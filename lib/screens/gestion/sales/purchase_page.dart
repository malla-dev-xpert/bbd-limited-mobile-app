import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/achats/create_achat_dto.dart';
import 'package:bbd_limited/models/devises.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/create_partner_bottom_sheet.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/create_supplier_bottom_sheet.dart';

class PurchasePage extends StatefulWidget {
  // Paramètres optionnels pour les achats avec versement existant
  final int? clientId;
  final int? versementId;
  final String? invoiceNumber;
  final Devise? devise;
  final double? tauxChange;
  final Function(Achat)? onPurchaseComplete;

  const PurchasePage({
    Key? key,
    this.clientId,
    this.versementId,
    this.invoiceNumber,
    this.devise,
    this.tauxChange,
    this.onPurchaseComplete,
  }) : super(key: key);

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final _formKey = GlobalKey<FormState>();
  late NumberFormat currencyFormat;
  final List<Map<String, dynamic>> localItems = [];
  bool isLoading = false;
  bool isSuppliersLoading = true;

  // Services
  final AuthService authService = AuthService();
  final AchatServices achatServices = AchatServices();
  final PartnerServices partnerServices = PartnerServices();
  final VersementServices versementServices = VersementServices();

  // Données
  List<Partner> suppliers = [];
  List<Partner> customers = [];
  List<Versement> versements = [];
  Partner? selectedSupplier;
  Partner? selectedCustomer;
  Versement? selectedVersement;
  bool isDebtPurchase = false;
  bool isCustomersLoading = true;
  bool isVersementsLoading = false;

  // Clé pour forcer la reconstruction du dropdown fournisseur
  Key _supplierDropdownKey = UniqueKey();

  // Contrôleurs
  final TextEditingController _searchCustomerController =
      TextEditingController();
  final TextEditingController _searchSupplierController =
      TextEditingController();

  // Contrôleurs pour les articles
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _cartonController = TextEditingController();
  final TextEditingController _quantityPerCartonController =
      TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(); // Calculé automatiquement
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _salesRateController = TextEditingController();

  // Mode de calcul du prix (par défaut: par carton)
  bool _isPricePerCarton = true;

  @override
  void initState() {
    super.initState();

    // Debug: Afficher les paramètres reçus
    log("PurchasePage initState - clientId: ${widget.clientId}, versementId: ${widget.versementId}");

    // Initialiser le format de devise
    final deviseCode = widget.devise?.code ?? 'CNY';
    currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: deviseCode);

    // Initialiser le sales rate avec la valeur par défaut 1
    _salesRateController.text = '1';

    // Si on a déjà un client (cas d'achat depuis les détails d'un client ou versement)
    if (widget.clientId != null) {
      _loadExistingPurchaseData();
    } else {
      // Cas d'achat normal - charger les données
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _searchCustomerController.dispose();
    _searchSupplierController.dispose();
    _descriptionController.dispose();
    _cartonController.dispose();
    _quantityPerCartonController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _invoiceNumberController.dispose();
    _salesRateController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingPurchaseData() async {
    try {
      // Charger le client et le versement existants
      final customersData = await partnerServices.findCustomers(page: 0);

      setState(() {
        customers = customersData;
        isCustomersLoading = false;

        // Trouver le client correspondant
        log("Recherche du client avec ID: ${widget.clientId}");
        log("Clients disponibles: ${customers.map((c) => '${c.id}: ${c.firstName} ${c.lastName}').join(', ')}");

        try {
          selectedCustomer = customers.firstWhere(
            (c) => c.id == widget.clientId,
          );
        } catch (e) {
          log("Client non trouvé, utilisation du premier client");
          selectedCustomer = customers.isNotEmpty ? customers.first : null;
        }

        log("Client sélectionné: ${selectedCustomer?.id} - ${selectedCustomer?.firstName} ${selectedCustomer?.lastName}");
      });

      // Si on a un versement ID, charger les versements et le sélectionner
      if (widget.versementId != null) {
        final versementsData = await versementServices.getAll(page: 0);
        setState(() {
          versements = versementsData;
          selectedVersement = versements.firstWhere(
            (v) => v.id == widget.versementId,
            orElse: () => versements.first,
          );
          isDebtPurchase = false; // Achat avec versement existant
        });
      } else {
        // Si pas de versement ID, charger les versements du client et déterminer le mode
        await _loadVersementsForCustomer(widget.clientId!);
      }

      await _loadSuppliers();
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('error_loading_data'),
        );
      }
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCustomers(),
      _loadSuppliers(),
    ]);
  }

  Future<void> _loadCustomers() async {
    try {
      final customersData = await partnerServices.findCustomers(page: 0);
      setState(() {
        customers = customersData;
        isCustomersLoading = false;
      });
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('error_loading_customers'),
        );
      }
    }
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliersData = await partnerServices.findSuppliers(page: 0);
      setState(() {
        suppliers = suppliersData;
        isSuppliersLoading = false;
      });
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('error_loading_suppliers'),
        );
      }
    }
  }

  Future<void> _loadVersementsForCustomer(int customerId) async {
    if (customerId <= 0) return;

    setState(() {
      isVersementsLoading = true;
      selectedVersement = null;
    });

    try {
      final versementsData = await versementServices.getByClient(customerId);
      setState(() {
        versements = versementsData;
        isVersementsLoading = false;
        // Si aucun versement n'est trouvé, définir automatiquement comme dette
        if (versementsData.isEmpty) {
          isDebtPurchase = true;
        } else {
          isDebtPurchase = false;
        }
      });
    } catch (e) {
      setState(() {
        isVersementsLoading = false;
        // En cas d'erreur, considérer comme dette
        isDebtPurchase = true;
      });
      if (mounted) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('error_loading_versements'),
        );
      }
    }
  }

  void _onCustomerSelected(Partner? customer) {
    setState(() {
      selectedCustomer = customer;
      selectedVersement = null;
      versements = [];
    });

    if (customer != null) {
      _loadVersementsForCustomer(customer.id);
    }
  }

  void _onVersementSelected(Versement? versement) {
    setState(() {
      selectedVersement = versement;
      // Si un versement est sélectionné, désactiver l'achat en dette
      if (versement != null) {
        isDebtPurchase = false;
      }
    });
  }

  // Méthode pour créer un nouveau client
  void _showCreateClientBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePartnerBottomSheet(),
    ).then((_) {
      _loadCustomers(); // Recharger la liste des clients après la création
    });
  }

  // Méthode pour créer un nouveau fournisseur
  void _showCreateSupplierBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateSupplierBottomSheet(
        onSupplierCreated: () {
          _loadSuppliers(); // Recharger la liste des fournisseurs après la création
        },
      ),
    );
  }

  // Méthode pour calculer la quantité totale automatiquement
  void _calculateTotalQuantity() {
    final carton = int.tryParse(_cartonController.text) ?? 0;
    final quantityPerCarton =
        int.tryParse(_quantityPerCartonController.text) ?? 0;
    final totalQuantity = carton * quantityPerCarton;

    setState(() {
      _quantityController.text = totalQuantity.toString();
    });
  }

  // Méthode pour calculer le prix total automatiquement
  double _calculateItemTotalPrice() {
    final carton = int.tryParse(_cartonController.text) ?? 0;
    final quantityPerCarton =
        int.tryParse(_quantityPerCartonController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;

    if (_isPricePerCarton) {
      // Prix par carton
      return carton * unitPrice;
    } else {
      // Prix par quantité totale
      final totalQuantity = carton * quantityPerCarton;
      return totalQuantity * unitPrice;
    }
  }

  void _addItem() {
    if (_descriptionController.text.trim().isEmpty ||
        _cartonController.text.trim().isEmpty ||
        _quantityPerCartonController.text.trim().isEmpty ||
        _unitPriceController.text.trim().isEmpty ||
        selectedSupplier == null) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('fill_all_fields'),
      );
      return;
    }

    // Calculer la quantité totale
    _calculateTotalQuantity();
    final totalQuantity = int.tryParse(_quantityController.text) ?? 0;

    if (totalQuantity <= 0) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('invalid_quantity_calculation'),
      );
      return;
    }

    setState(() {
      localItems.add({
        'description': _descriptionController.text.trim(),
        'carton': int.tryParse(_cartonController.text) ?? 0,
        'quantityPerCarton':
            int.tryParse(_quantityPerCartonController.text) ?? 0,
        'quantity': totalQuantity,
        'unitPrice': double.tryParse(_unitPriceController.text) ?? 0.0,
        'isPricePerCarton': _isPricePerCarton, // Ajouter le mode de calcul
        'supplierId': selectedSupplier!.id,
        'supplierName':
            '${selectedSupplier!.firstName} ${selectedSupplier!.lastName}',
        'invoiceNumber': _invoiceNumberController.text.trim(),
        'salesRate': double.tryParse(_salesRateController.text) ?? 0.0,
      });

      // Réinitialiser les champs dans le setState pour garantir la mise à jour de l'UI
      _descriptionController.clear();
      _cartonController.clear();
      _quantityPerCartonController.clear();
      _quantityController.clear();
      _unitPriceController.clear();
      _invoiceNumberController.clear();
      _salesRateController.text = '1'; // Réinitialiser à la valeur par défaut
      selectedSupplier = null;

      // Forcer la reconstruction du dropdown fournisseur
      _supplierDropdownKey = UniqueKey();
    });
  }

  void _removeItem(int index) {
    setState(() {
      localItems.removeAt(index);
    });
  }

  void _duplicateItem(int index) {
    final item = localItems[index];
    setState(() {
      localItems.add(Map<String, dynamic>.from(item));
    });
  }

  void _editItem(int index) {
    final item = localItems[index];

    setState(() {
      // Remplir les champs avec les données de l'article
      _descriptionController.text = item['description']?.toString() ?? '';
      _cartonController.text = item['carton']?.toString() ?? '';
      _quantityPerCartonController.text =
          item['quantityPerCarton']?.toString() ?? '';
      _quantityController.text = item['quantity']?.toString() ?? '';
      _unitPriceController.text = item['unitPrice']?.toString() ?? '';
      _invoiceNumberController.text = item['invoiceNumber']?.toString() ?? '';
      _salesRateController.text = item['salesRate']?.toString() ?? '1';
      _isPricePerCarton =
          item['isPricePerCarton'] ?? true; // Par défaut par carton

      // Trouver et sélectionner le fournisseur
      final supplierId = item['supplierId'];
      selectedSupplier = suppliers.firstWhere(
        (s) => s.id == supplierId,
        orElse: () => suppliers.first,
      );

      // Forcer la reconstruction du dropdown avec le nouveau fournisseur
      _supplierDropdownKey = UniqueKey();
    });

    // Supprimer l'article de la liste
    _removeItem(index);

    // Faire défiler vers le formulaire d'ajout
    Future.delayed(const Duration(milliseconds: 100), () {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  // Méthode unifiée pour calculer le total d'un article
  double _calculateItemTotal(Map<String, dynamic> item) {
    final isPricePerCarton = item['isPricePerCarton'] ?? true;
    final carton = (item['carton'] as num?)?.toInt() ?? 0;
    final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
    final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;

    if (isPricePerCarton) {
      // Prix par carton
      return carton * unitPrice;
    } else {
      // Prix par quantité totale
      return quantity * unitPrice;
    }
  }

  double _calculateTotal() {
    return localItems.fold(0.0, (sum, item) {
      return sum + _calculateItemTotal(item);
    });
  }

  Widget _buildDetailItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPurchase() async {
    if (selectedCustomer == null) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('customer_required'),
      );
      return;
    }

    if (localItems.isEmpty) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('items_required'),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = await authService.getUserInfo();
      if (user?.id == null) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('user_not_connected'));
        return;
      }

      // Log des données avant création
      log("Création achat - Client ID: ${selectedCustomer!.id}");
      log("Création achat - User ID: ${user!.id}");
      log("Création achat - Versement ID: ${selectedVersement?.id}");
      log("Création achat - Devise: ${widget.devise?.code}");
      log("Création achat - Taux de change: ${widget.tauxChange}");
      log("Création achat - Nombre d'articles: ${localItems.length}");

      final createAchatDto = CreateAchatDto(
        versementId: selectedVersement?.id,
        items: localItems.map((item) {
          // Pour les achats avec versement dans une devise étrangère,
          // convertissez le prix unitaire si nécessaire
          double unitPrice = item['unitPrice'];
          if (selectedVersement != null &&
              widget.devise != null &&
              widget.devise!.code != 'CNY' &&
              widget.tauxChange != null) {
            unitPrice = item['unitPrice'] * widget.tauxChange!;
          }

          final createItemDto = CreateItemDto(
            description: item['description']?.toString() ?? '',
            quantity: (item['quantity'] as num?)?.toInt() ?? 0,
            carton: (item['carton'] as num?)?.toInt() ?? 0,
            quantityPerCarton:
                (item['quantityPerCarton'] as num?)?.toInt() ?? 0,
            unitPrice: unitPrice,
            invoiceNumber:
                item['invoiceNumber']?.toString() ?? widget.invoiceNumber ?? '',
            supplierId: item['supplierId']?.toInt() ?? 0,
            salesRate: (item['salesRate'] as num?)?.toDouble() ?? 0.0,
          );

          return createItemDto;
        }).toList(),
      );

      final result = await achatServices.createAchatForClient(
        clientId: selectedCustomer!.id,
        userId: user.id,
        dto: createAchatDto,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        // Appeler le callback si fourni
        if (widget.onPurchaseComplete != null) {
          widget.onPurchaseComplete!(Achat());
        }

        final message = isDebtPurchase
            ? AppLocalizations.of(context).translate('debt_created_success')
            : AppLocalizations.of(context)
                .translate('purchase_created_success');
        showSuccessTopSnackBar(context, message);

        // Retourner à l'écran précédent
        Navigator.pop(context, true);
      } else {
        String message = result.errorMessage ??
            AppLocalizations.of(context).translate('unknown_error');
        if (result.errors != null && result.errors!.isNotEmpty) {
          message = result.errors!.join('\n');
        }
        showErrorTopSnackBar(context, message);
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          "${AppLocalizations.of(context).translate('error_creating_purchase')}: ${e.toString()}",
        );
      }
      log(e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('new_purchase'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Section sélection client/versement (seulement si pas déjà défini)
              if (widget.clientId == null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate('customer_selection'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sélection du client avec bouton d'ajout
                      Row(
                        children: [
                          Expanded(
                            child: DropDownCustom<Partner>(
                              items: customers,
                              selectedItem: selectedCustomer,
                              onChanged: _onCustomerSelected,
                              itemToString: (customer) =>
                                  '${customer.firstName} ${customer.lastName} - ${customer.phoneNumber}',
                              hintText: AppLocalizations.of(context)
                                  .translate('select_customer'),
                              prefixIcon: Icons.person,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add, color: Colors.blue[700]),
                              onPressed: _showCreateClientBottomSheet,
                              tooltip: AppLocalizations.of(context)
                                  .translate('add_new_partner'),
                            ),
                          ),
                        ],
                      ),

                      if (selectedCustomer != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)
                              .translate('versement_selection'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Sélection du versement (seulement si des versements existent)
                        if (versements.isNotEmpty) ...[
                          IgnorePointer(
                            ignoring: isDebtPurchase,
                            child: Opacity(
                              opacity: isDebtPurchase ? 0.5 : 1.0,
                              child: DropDownCustom<Versement>(
                                items: versements,
                                selectedItem: selectedVersement,
                                onChanged: _onVersementSelected,
                                itemToString: (versement) =>
                                    '${versement.reference} - ${currencyFormat.format(versement.montantRestant)}',
                                hintText: AppLocalizations.of(context)
                                    .translate('select_versement_or_debt'),
                                prefixIcon: Icons.payment,
                              ),
                            ),
                          ),
                        ] else ...[
                          // Message quand aucun versement n'est disponible
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.payment,
                                    color: Colors.grey[600], size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .translate('no_versements_available'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Option dette (seulement si des versements existent)
                        if (versements.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Checkbox(
                                value: isDebtPurchase,
                                onChanged: selectedVersement != null
                                    ? null // Désactiver si un versement est sélectionné
                                    : (value) {
                                        setState(() {
                                          isDebtPurchase = value ?? false;
                                          if (isDebtPurchase) {
                                            selectedVersement = null;
                                          }
                                        });
                                      },
                              ),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate('debt_purchase'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedVersement != null
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Message informatif quand aucun versement n'est disponible
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.orange[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context).translate(
                                        'no_versements_available_debt_mode'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ] else ...[
                // Affichage des informations du client/versement quand déjà défini
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('purchase_info'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Informations du client
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person,
                                color: Colors.blue[600], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate('client'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    selectedCustomer != null
                                        ? '${selectedCustomer!.firstName} ${selectedCustomer!.lastName}'
                                        : AppLocalizations.of(context)
                                            .translate('loading'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Informations du versement (si applicable)
                      if (widget.versementId != null &&
                          selectedVersement != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.payment,
                                  color: Colors.green[600], size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)
                                          .translate('versement'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${selectedVersement!.reference} - ${currencyFormat.format(selectedVersement!.montantRestant)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (isDebtPurchase) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_wallet,
                                  color: Colors.orange[600], size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)
                                          .translate('purchase_type'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      AppLocalizations.of(context)
                                          .translate('debt_purchase'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Section ajout d'article
              if (selectedCustomer != null || widget.clientId != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('add_item'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Formulaire d'ajout d'article
                      // Numéro de facture en première position
                      buildTextField(
                        controller: _invoiceNumberController,
                        label: AppLocalizations.of(context)
                            .translate('invoice_number'),
                        icon: Icons.receipt,
                      ),
                      const SizedBox(height: 12),

                      buildTextField(
                        controller: _descriptionController,
                        label: AppLocalizations.of(context)
                            .translate('description'),
                        icon: Icons.description,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: buildTextField(
                              controller: _cartonController,
                              label: AppLocalizations.of(context)
                                  .translate('carton'),
                              icon: Icons.inventory_2,
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _calculateTotalQuantity(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: buildTextField(
                              controller: _quantityPerCartonController,
                              label: AppLocalizations.of(context)
                                  .translate('quantity_per_carton'),
                              icon: Icons.format_list_numbered,
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _calculateTotalQuantity(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Champ quantité totale (lecture seule)
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        enabled: false, // Lecture seule
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)
                              .translate('total_quantity'),
                          prefixIcon:
                              Icon(Icons.calculate, color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[100],
                          hintText: AppLocalizations.of(context)
                              .translate('calculated_automatically'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Mode de calcul du prix
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)
                                  .translate('price_calculation_mode'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<bool>(
                                    title: Text(
                                      AppLocalizations.of(context)
                                          .translate('price_per_carton'),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    value: true,
                                    groupValue: _isPricePerCarton,
                                    onChanged: (value) {
                                      setState(() {
                                        _isPricePerCarton = value ?? true;
                                      });
                                    },
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<bool>(
                                    title: Text(
                                      AppLocalizations.of(context).translate(
                                          'price_per_total_quantity'),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    value: false,
                                    groupValue: _isPricePerCarton,
                                    onChanged: (value) {
                                      setState(() {
                                        _isPricePerCarton = value ?? false;
                                      });
                                    },
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      buildTextField(
                        controller: _unitPriceController,
                        label: _isPricePerCarton
                            ? AppLocalizations.of(context)
                                .translate('price_per_carton')
                            : AppLocalizations.of(context)
                                .translate('unit_price'),
                        icon: Icons.currency_yen,
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            setState(() {}), // Pour recalculer l'affichage
                      ),
                      const SizedBox(height: 12),

                      // Prix total sur une ligne entière
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)
                                  .translate('total_price'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                            Text(
                              currencyFormat.format(_calculateItemTotalPrice()),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sélection du fournisseur avec bouton d'ajout
                      Row(
                        children: [
                          Expanded(
                            child: DropDownCustom<Partner>(
                              key:
                                  _supplierDropdownKey, // Clé pour forcer la reconstruction
                              items: suppliers,
                              selectedItem: selectedSupplier,
                              onChanged: (value) {
                                setState(() {
                                  selectedSupplier = value;
                                });
                              },
                              itemToString: (supplier) =>
                                  '${supplier.firstName} ${supplier.lastName}',
                              hintText: AppLocalizations.of(context)
                                  .translate('supplier'),
                              prefixIcon: Icons.business,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add, color: Colors.green[700]),
                              onPressed: _showCreateSupplierBottomSheet,
                              tooltip: AppLocalizations.of(context)
                                  .translate('add_new_supplier'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      buildTextField(
                        controller: _salesRateController,
                        label: AppLocalizations.of(context)
                            .translate('sales_rate'),
                        icon: Icons.trending_up,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      confirmationButton(
                        isLoading: false,
                        onPressed: _addItem,
                        label:
                            AppLocalizations.of(context).translate('add_item'),
                        icon: Icons.add,
                        subLabel:
                            AppLocalizations.of(context).translate('adding'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Liste des articles
                if (localItems.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context).translate('items'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${AppLocalizations.of(context).translate('total')}: ${currencyFormat.format(_calculateTotal())}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: localItems.length,
                          itemBuilder: (context, index) {
                            final item = localItems[index];
                            // Calculer le total en utilisant la méthode unifiée
                            final total = _calculateItemTotal(item);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // En-tête avec description et actions
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['description']
                                                        ?.toString() ??
                                                    '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${AppLocalizations.of(context).translate('supplier')}: ${item['supplierName']?.toString() ?? ''}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Boutons d'action
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Bouton dupliquer
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: IconButton(
                                                icon: Icon(Icons.copy,
                                                    color: Colors.blue[600],
                                                    size: 20),
                                                onPressed: () =>
                                                    _duplicateItem(index),
                                                tooltip:
                                                    AppLocalizations.of(context)
                                                        .translate('duplicate'),
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 36,
                                                        minHeight: 36),
                                                padding:
                                                    const EdgeInsets.all(8),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            // Bouton modifier
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.orange[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: IconButton(
                                                icon: Icon(Icons.edit,
                                                    color: Colors.orange[600],
                                                    size: 20),
                                                onPressed: () =>
                                                    _editItem(index),
                                                tooltip:
                                                    AppLocalizations.of(context)
                                                        .translate('edit'),
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 36,
                                                        minHeight: 36),
                                                padding:
                                                    const EdgeInsets.all(8),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            // Bouton supprimer
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: IconButton(
                                                icon: Icon(Icons.delete_outline,
                                                    color: Colors.red[600],
                                                    size: 20),
                                                onPressed: () =>
                                                    _removeItem(index),
                                                tooltip:
                                                    AppLocalizations.of(context)
                                                        .translate('delete'),
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 36,
                                                        minHeight: 36),
                                                padding:
                                                    const EdgeInsets.all(8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Détails de l'article
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          // Ligne carton et quantité par carton
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildDetailItem(
                                                  AppLocalizations.of(context)
                                                      .translate('carton'),
                                                  '${item['carton']}'),
                                              _buildDetailItem(
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'quantity_per_carton'),
                                                  '${item['quantityPerCarton']}'),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Ligne quantité totale et prix unitaire
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildDetailItem(
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'total_quantity'),
                                                  '${item['quantity']}'),
                                              _buildDetailItem(
                                                  (item['isPricePerCarton'] ??
                                                          true)
                                                      ? AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'price_per_carton')
                                                      : AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'unit_price'),
                                                  currencyFormat.format(
                                                      item['unitPrice'])),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Ligne numéro de facture et sales rate
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildDetailItem(
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'invoice_number'),
                                                  item['invoiceNumber']
                                                          ?.toString() ??
                                                      'N/A'),
                                              _buildDetailItem(
                                                  AppLocalizations.of(context)
                                                      .translate('sales_rate'),
                                                  '${item['salesRate']}'),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Ligne total
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '${AppLocalizations.of(context).translate('total')}:',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                Text(
                                                  currencyFormat.format(total),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.blue[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bouton de validation
                  confirmationButton(
                    isLoading: isLoading,
                    onPressed: _submitPurchase,
                    label: isDebtPurchase
                        ? AppLocalizations.of(context).translate('create_debt')
                        : AppLocalizations.of(context)
                            .translate('create_purchase'),
                    icon: isDebtPurchase
                        ? Icons.account_balance_wallet
                        : Icons.shopping_cart,
                    subLabel: isDebtPurchase
                        ? AppLocalizations.of(context)
                            .translate('creating_debt')
                        : AppLocalizations.of(context)
                            .translate('creating_purchase'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
