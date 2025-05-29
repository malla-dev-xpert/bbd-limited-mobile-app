import 'dart:developer';

import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/achats/create_achat_dto.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/package_items_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/package_items_list.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PurchaseDialog extends StatefulWidget {
  final Function(Achat) onPurchaseComplete;
  final int clientId;
  final int versementId;

  const PurchaseDialog({
    Key? key,
    required this.onPurchaseComplete,
    required this.clientId,
    required this.versementId,
  }) : super(key: key);

  static void show(
    BuildContext context,
    Function(Achat) onPurchaseComplete,
    int clientId,
    int versementId,
  ) {
    showDialog(
      context: context,
      builder: (context) => PurchaseDialog(
        onPurchaseComplete: onPurchaseComplete,
        clientId: clientId,
        versementId: versementId,
      ),
    );
  }

  @override
  State<PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<PurchaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');
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
  ) {
    setState(() {
      localItems.add({
        'description': description,
        'quantity': quantity.toInt(),
        'unitPrice': unitPrice,
        'supplierId': supplierId,
        'supplier': supplierName,
      });
    });
  }

  void _removeItem(int index) {
    setState(() => localItems.removeAt(index));
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
        lignes: localItems
            .map(
              (item) => CreateLigneDto(
                descriptionItem: item['description']?.toString() ?? '',
                quantityItem: (item['quantity'] as num?)?.toInt() ?? 0,
                prixUnitaire: (item['unitPrice'] as num?)?.toDouble() ?? 0.0,
                supplierId: item['supplierId'],
              ),
            )
            .toList(),
      );

      final result = await achatServices.createAchatForClient(
        clientId: widget.clientId,
        supplierId: localItems.first['supplierId'],
        userId: user!.id,
        dto: createAchatDto,
      );

      if (!mounted) return;

      switch (result) {
        case "ACHAT_CREATED":
          // Récupérer l'achat créé
          Navigator.pop(context, true);
          showSuccessTopSnackBar(context, "Achat créé avec succès !");
          break;
        case "INVALID_VERSEMENT":
          showErrorTopSnackBar(
            context,
            "Le versement ne correspond pas au client",
          );
          break;
        case "INACTIVE_VERSEMENT":
          showErrorTopSnackBar(context, "Le versement n'est pas actif");
          break;
        default:
          showErrorTopSnackBar(context, "Erreur: $result");
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(context, "Erreur: ${e.toString()}");
      }
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
                      fontSize: 24,
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
                            ) {
                              _addItem(
                                description,
                                quantity,
                                unitPrice,
                                supplierId,
                                supplierName,
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          PackageItemsList(
                            items: localItems,
                            onRemoveItem: _removeItem,
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
