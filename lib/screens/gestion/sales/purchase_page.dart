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

  // Contrôleurs
  final TextEditingController _searchCustomerController =
      TextEditingController();
  final TextEditingController _searchSupplierController =
      TextEditingController();

  // Contrôleurs pour les articles
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _salesRateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialiser le format de devise
    final deviseCode = widget.devise?.code ?? 'CNY';
    currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: deviseCode);

    // Initialiser le sales rate avec la valeur par défaut 1
    _salesRateController.text = '1';

    // Si on a déjà un client et versement (cas d'achat avec versement existant)
    if (widget.clientId != null && widget.versementId != null) {
      _loadExistingPurchaseData();
    } else {
      // Cas d'achat normal ou dette - charger les données
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _searchCustomerController.dispose();
    _searchSupplierController.dispose();
    _descriptionController.dispose();
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
      final versementsData = await versementServices.getAll(page: 0);

      setState(() {
        customers = customersData;
        versements = versementsData;

        // Trouver le client et versement correspondants
        selectedCustomer = customers.firstWhere(
          (c) => c.id == widget.clientId,
          orElse: () => customers.first,
        );
        selectedVersement = versements.firstWhere(
          (v) => v.id == widget.versementId,
          orElse: () => versements.first,
        );

        isDebtPurchase = false; // Achat avec versement existant
        isCustomersLoading = false;
      });

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
      });
    } catch (e) {
      setState(() {
        isVersementsLoading = false;
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
      isDebtPurchase = versement == null;
    });
  }

  void _addItem() {
    if (_descriptionController.text.trim().isEmpty ||
        _quantityController.text.trim().isEmpty ||
        _unitPriceController.text.trim().isEmpty ||
        selectedSupplier == null) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('fill_all_fields'),
      );
      return;
    }

    setState(() {
      localItems.add({
        'description': _descriptionController.text.trim(),
        'quantity': double.tryParse(_quantityController.text) ?? 0.0,
        'unitPrice': double.tryParse(_unitPriceController.text) ?? 0.0,
        'supplierId': selectedSupplier!.id,
        'supplierName':
            '${selectedSupplier!.firstName} ${selectedSupplier!.lastName}',
        'invoiceNumber': _invoiceNumberController.text.trim(),
        'salesRate': double.tryParse(_salesRateController.text) ?? 0.0,
      });
    });

    // Réinitialiser les champs
    _descriptionController.clear();
    _quantityController.clear();
    _unitPriceController.clear();
    _invoiceNumberController.clear();
    _salesRateController.text = '1'; // Réinitialiser à la valeur par défaut
    selectedSupplier = null;
  }

  void _removeItem(int index) {
    setState(() {
      localItems.removeAt(index);
    });
  }

  double _calculateTotal() {
    return localItems.fold(0.0, (sum, item) {
      final quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
      return sum + (quantity * unitPrice);
    });
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
        showErrorTopSnackBar(context, "Utilisateur non connecté");
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
              // Section sélection client/versement
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

                    // Sélection du client
                    DropDownCustom<Partner>(
                      items: customers,
                      selectedItem: selectedCustomer,
                      onChanged: _onCustomerSelected,
                      itemToString: (customer) =>
                          '${customer.firstName} ${customer.lastName} - ${customer.phoneNumber}',
                      hintText: AppLocalizations.of(context)
                          .translate('select_customer'),
                      prefixIcon: Icons.person,
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

                      // Sélection du versement
                      DropDownCustom<Versement>(
                        items: versements,
                        selectedItem: selectedVersement,
                        onChanged: _onVersementSelected,
                        itemToString: (versement) =>
                            '${versement.reference} - ${currencyFormat.format(versement.montantRestant)}',
                        hintText: AppLocalizations.of(context)
                            .translate('select_versement_or_debt'),
                        prefixIcon: Icons.payment,
                      ),

                      // Option dette
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: isDebtPurchase,
                            onChanged: (value) {
                              setState(() {
                                isDebtPurchase = value ?? false;
                                if (isDebtPurchase) {
                                  selectedVersement = null;
                                }
                              });
                            },
                          ),
                          Text(
                            AppLocalizations.of(context)
                                .translate('debt_purchase'),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Section ajout d'article
              if (selectedCustomer != null) ...[
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
                              controller: _quantityController,
                              label: AppLocalizations.of(context)
                                  .translate('quantity'),
                              icon: Icons.numbers,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: buildTextField(
                              controller: _unitPriceController,
                              label: AppLocalizations.of(context)
                                  .translate('unit_price'),
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      DropDownCustom<Partner>(
                        items: suppliers,
                        selectedItem: selectedSupplier,
                        onChanged: (value) {
                          setState(() {
                            selectedSupplier = value;
                          });
                        },
                        itemToString: (supplier) =>
                            '${supplier.firstName} ${supplier.lastName}',
                        hintText:
                            AppLocalizations.of(context).translate('supplier'),
                        prefixIcon: Icons.business,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: buildTextField(
                              controller: _invoiceNumberController,
                              label: AppLocalizations.of(context)
                                  .translate('invoice_number'),
                              icon: Icons.receipt,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: buildTextField(
                              controller: _salesRateController,
                              label: AppLocalizations.of(context)
                                  .translate('sales_rate'),
                              icon: Icons.trending_up,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
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
                              'Total: ${currencyFormat.format(_calculateTotal())}',
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
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(item['description']),
                                subtitle: Text(
                                  'Qty: ${item['quantity']} × ${currencyFormat.format(item['unitPrice'])} = ${currencyFormat.format((item['quantity'] as double) * (item['unitPrice'] as double))}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _removeItem(index),
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
