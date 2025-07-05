import 'dart:developer';

import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/achats/create_achat_dto.dart';
import 'package:bbd_limited/models/devises.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/package_items_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/package_items_list.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // Added for jsonEncode

class PurchaseDialog extends StatefulWidget {
  final Function(Achat) onPurchaseComplete;
  final int clientId;
  final int versementId;
  final String invoiceNumber;
  final Devise? devise;
  final double? tauxChange;

  const PurchaseDialog(
      {Key? key,
      required this.onPurchaseComplete,
      required this.clientId,
      required this.versementId,
      required this.invoiceNumber,
      this.devise,
      this.tauxChange})
      : super(key: key);

  static void show(
    BuildContext context,
    Function(Achat) onPurchaseComplete,
    int clientId,
    int versementId,
    String invoiceNumber, {
    Devise? devise,
    double? tauxChange,
  }) {
    showDialog(
      context: context,
      builder: (context) => PurchaseDialog(
        onPurchaseComplete: onPurchaseComplete,
        clientId: clientId,
        versementId: versementId,
        invoiceNumber: invoiceNumber,
        devise: devise,
        tauxChange: tauxChange,
      ),
    );
  }

  @override
  State<PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<PurchaseDialog> {
  final _formKey = GlobalKey<FormState>();
  late NumberFormat currencyFormat;
  final List<Map<String, dynamic>> localItems = [];
  bool isLoading = false;
  final AuthService authService = AuthService();
  final AchatServices achatServices = AchatServices();
  final PartnerServices partnerServices = PartnerServices();

  List<Partner> suppliers = [];
  Partner? selectedSupplier;

  @override
  void initState() {
    super.initState();
    // Utiliser la devise du versement si disponible, sinon CNY par défaut
    final deviseCode = widget.devise?.code ?? 'CNY';
    currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: deviseCode);
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliersData = await partnerServices.findSuppliers(page: 0);
      setState(() {
        suppliers = suppliersData;
        // selectedSupplier = null;
      });
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          "Erreur lors du chargement des fournisseurs",
        );
      }
    }
  }

  void _addItem(
    String description,
    double quantity,
    double unitPrice,
    int supplierId,
    String supplierName,
    String invoiceNumber,
    double salesRate,
  ) {
    setState(() {
      localItems.add({
        'description': description,
        'quantity': quantity.toInt(),
        'unitPrice': unitPrice,
        'supplierId': supplierId,
        'supplier': supplierName,
        'invoiceNumber': invoiceNumber,
        'salesRate': salesRate,
      });
    });
  }

  void _removeItem(int index) {
    setState(() => localItems.removeAt(index));
  }

  void _duplicateItem(int index) {
    setState(() {
      final item = localItems[index];
      localItems.add(Map<String, dynamic>.from(item));
    });
  }

  void _editItem(int index, Map<String, dynamic> updatedItem) {
    setState(() {
      localItems[index] = updatedItem;
    });
  }

  Future<void> _submitForm() async {
    if (localItems.isEmpty) {
      showErrorTopSnackBar(context, "Ajoutez au moins un article.");
      return;
    }

    // Validation supplémentaire pour les achats avec versement
    if (widget.versementId != null && widget.devise == null) {
      showErrorTopSnackBar(
          context, "La devise du versement doit être spécifiée");
      return;
    }

    // Validation des données des articles
    for (int i = 0; i < localItems.length; i++) {
      final item = localItems[i];
      if (item['description']?.toString().isEmpty ?? true) {
        showErrorTopSnackBar(
            context, "La description de l'article ${i + 1} est requise.");
        return;
      }
      final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
      if (quantity <= 0) {
        showErrorTopSnackBar(context,
            "La quantité de l'article ${i + 1} doit être supérieure à 0.");
        return;
      }
      final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
      if (unitPrice <= 0) {
        showErrorTopSnackBar(context,
            "Le prix unitaire de l'article ${i + 1} doit être supérieur à 0.");
        return;
      }
      final supplierId = (item['supplierId'] as num?)?.toInt() ?? 0;
      if (supplierId <= 0) {
        showErrorTopSnackBar(
            context, "Le fournisseur de l'article ${i + 1} est requis.");
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      final user = await authService.getUserInfo();
      if (user?.id == null) {
        showErrorTopSnackBar(context, "Utilisateur non connecté");
        return;
      }

      // Log des données avant création
      log("Création achat - Client ID: ${widget.clientId}");
      log("Création achat - User ID: ${user!.id}");
      log("Création achat - Versement ID: ${widget.versementId}");
      log("Création achat - Devise: ${widget.devise?.code}");
      log("Création achat - Taux de change: ${widget.tauxChange}");
      log("Création achat - Nombre d'articles: ${localItems.length}");

      final createAchatDto = CreateAchatDto(
        versementId: widget.versementId,
        items: localItems.map((item) {
          // Pour les achats avec versement dans une devise étrangère,
          // convertissez le prix unitaire si nécessaire
          double unitPrice = item['unitPrice'];
          if (widget.versementId != null &&
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
                item['invoiceNumber']?.toString() ?? widget.invoiceNumber,
            supplierId: item['supplierId']?.toInt() ?? 0,
            salesRate: (item['salesRate'] as num?)?.toDouble() ?? 0.0,
          );

          // Log de chaque article
          log("Article - Description: ${createItemDto.description}");
          log("Article - Quantité: ${createItemDto.quantity}");
          log("Article - Prix unitaire: ${createItemDto.unitPrice}");
          log("Article - Numéro facture: ${createItemDto.invoiceNumber}");
          log("Article - ID fournisseur: ${createItemDto.supplierId}");
          log("Article - Taux de vente: ${createItemDto.salesRate}");

          return createItemDto;
        }).toList(),
      );

      // Log du DTO complet
      log("DTO JSON: ${jsonEncode(createAchatDto.toJson())}");

      final result = await achatServices.createAchatForClient(
        clientId: widget.clientId,
        userId: user.id,
        dto: createAchatDto,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        Navigator.pop(context, true);
        showSuccessTopSnackBar(context, "Achat créé avec succès !");
      } else {
        String message = result.errorMessage ?? "Erreur inconnue";
        if (result.errors != null && result.errors!.isNotEmpty) {
          message = result.errors!.join('\n');
        }
        showErrorTopSnackBar(context, message);
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
            context, "Erreur lors de la création de l'achat: ${e.toString()}");
      }
      log("Erreur création achat: ${e.toString()}");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nouvel Achat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          PackageItemForm(
                            onAddItem: (
                              description,
                              quantity,
                              unitPrice,
                              supplierId,
                              supplierName,
                              invoiceNumber,
                              salesRate,
                            ) {
                              _addItem(
                                description,
                                quantity,
                                unitPrice,
                                supplierId,
                                supplierName,
                                invoiceNumber,
                                salesRate,
                              );
                            },
                            suppliers: suppliers,
                          ),
                          const SizedBox(height: 10),
                          PackageItemsList(
                            items: localItems,
                            suppliers: suppliers,
                            onRemoveItem: _removeItem,
                            onDuplicateItem: _duplicateItem,
                            onEditItem: _editItem,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currencyFormat.format(
                              localItems.fold<double>(
                                0,
                                (sum, item) =>
                                    sum +
                                    (item['quantity'] * item['unitPrice']),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1E49),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    confirmationButton(
                      isLoading: isLoading,
                      onPressed: _submitForm,
                      label: 'Valider',
                      icon: Icons.verified_outlined,
                      subLabel: 'Enregistrement...',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DebtPurchaseDialog extends StatefulWidget {
  final int clientId;
  final int? versementId;
  final Function()? onDebtCreated;

  const DebtPurchaseDialog({
    Key? key,
    required this.clientId,
    this.versementId,
    this.onDebtCreated,
  }) : super(key: key);

  static void show(BuildContext context, int clientId,
      {int? versementId, Function()? onDebtCreated}) {
    showDialog(
      context: context,
      builder: (context) => DebtPurchaseDialog(
        clientId: clientId,
        versementId: versementId,
        onDebtCreated: onDebtCreated,
      ),
    );
  }

  @override
  State<DebtPurchaseDialog> createState() => _DebtPurchaseDialogState();
}

class _DebtPurchaseDialogState extends State<DebtPurchaseDialog> {
  final _formKey = GlobalKey<FormState>();
  late NumberFormat currencyFormat;
  final List<Map<String, dynamic>> localItems = [];
  bool isLoading = false;
  final AuthService authService = AuthService();
  final AchatServices achatServices = AchatServices();
  final PartnerServices partnerServices = PartnerServices();

  List<Partner> suppliers = [];
  Partner? selectedSupplier;

  @override
  void initState() {
    super.initState();
    // Pour les dettes, utiliser CNY par défaut car il n'y a pas de devise spécifique
    currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'CNY');
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliersData = await partnerServices.findSuppliers(page: 0);
      setState(() {
        suppliers = suppliersData;
      });
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          "Erreur lors du chargement des fournisseurs",
        );
      }
    }
  }

  void _addItem(
    String description,
    double quantity,
    double unitPrice,
    int supplierId,
    String supplierName,
    String invoiceNumber,
    double salesRate,
  ) {
    setState(() {
      localItems.add({
        'description': description,
        'quantity': quantity.toInt(),
        'unitPrice': unitPrice,
        'supplierId': supplierId,
        'supplier': supplierName,
        'invoiceNumber': invoiceNumber,
        'salesRate': salesRate,
      });
    });
  }

  void _removeItem(int index) {
    setState(() => localItems.removeAt(index));
  }

  void _duplicateItem(int index) {
    setState(() {
      final item = localItems[index];
      localItems.add(Map<String, dynamic>.from(item));
    });
  }

  void _editItem(int index, Map<String, dynamic> updatedItem) {
    setState(() {
      localItems[index] = updatedItem;
    });
  }

  Future<void> _submitForm() async {
    if (localItems.isEmpty) {
      showErrorTopSnackBar(context, "Ajoutez au moins un article.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = await authService.getUserInfo();
      if (user?.id == null) {
        showErrorTopSnackBar(context, "Utilisateur non connecté");
        return;
      }

      final createAchatDto = CreateAchatDto(
        versementId: widget.versementId,
        items: localItems
            .map(
              (item) => CreateItemDto(
                description: item['description']?.toString() ?? '',
                quantity: (item['quantity'] as num?)?.toInt() ?? 0,
                unitPrice: (item['unitPrice'] as num?)?.toDouble() ?? 0.0,
                invoiceNumber: item['invoiceNumber']?.toString() ?? '',
                supplierId: item['supplierId']?.toInt() ?? 0,
                salesRate: (item['salesRate'] as num?)?.toDouble() ?? 0.0,
              ),
            )
            .toList(),
      );

      final result = await achatServices.createAchatForClient(
        clientId: widget.clientId,
        userId: user!.id,
        dto: createAchatDto,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        Navigator.pop(context, true);
        if (widget.onDebtCreated != null) widget.onDebtCreated!();
        showSuccessTopSnackBar(context, "Dette créée avec succès !");
      } else {
        String message = result.errorMessage ?? "Erreur inconnue";
        if (result.errors != null && result.errors!.isNotEmpty) {
          message = result.errors!.join('\n');
        }
        showErrorTopSnackBar(context, message);
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(context, "Erreur: \\${e.toString()}");
      }
      log(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nouvelle Dette',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          PackageItemForm(
                            onAddItem: (
                              description,
                              quantity,
                              unitPrice,
                              supplierId,
                              supplierName,
                              invoiceNumber,
                              salesRate,
                            ) {
                              _addItem(
                                description,
                                quantity,
                                unitPrice,
                                supplierId,
                                supplierName,
                                invoiceNumber,
                                salesRate,
                              );
                            },
                            suppliers: suppliers,
                          ),
                          const SizedBox(height: 10),
                          PackageItemsList(
                            items: localItems,
                            suppliers: suppliers,
                            onRemoveItem: _removeItem,
                            onDuplicateItem: _duplicateItem,
                            onEditItem: _editItem,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currencyFormat.format(
                              localItems.fold<double>(
                                0,
                                (sum, item) =>
                                    sum +
                                    (item['quantity'] * item['unitPrice']),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1E49),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    confirmationButton(
                      isLoading: isLoading,
                      onPressed: _submitForm,
                      label: 'Valider',
                      icon: Icons.verified_outlined,
                      subLabel: 'Enregistrement...',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
