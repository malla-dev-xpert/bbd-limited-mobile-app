import 'package:flutter/material.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/package_items_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/package_items_list.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/models/achats/create_achat_dto.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/services/partner_services.dart';

class PurchaseItemsStep extends StatefulWidget {
  final Partner customer;
  final Versement? versement;
  final bool isDebtPurchase;
  final List<Map<String, dynamic>> initialItems;
  final void Function(List<Map<String, dynamic>>) onItemsChanged;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  const PurchaseItemsStep({
    Key? key,
    required this.customer,
    required this.versement,
    required this.isDebtPurchase,
    required this.initialItems,
    required this.onItemsChanged,
    required this.onBack,
    required this.onFinish,
  }) : super(key: key);

  @override
  State<PurchaseItemsStep> createState() => _PurchaseItemsStepState();
}

class _PurchaseItemsStepState extends State<PurchaseItemsStep> {
  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'CNY');
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  List<Partner> _suppliers = [];
  bool _isSuppliersLoading = true;
  final AchatServices achatServices = AchatServices();
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    _items = List<Map<String, dynamic>>.from(widget.initialItems);
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await PartnerServices().findSuppliers();
      setState(() {
        _suppliers = suppliers;
        _isSuppliersLoading = false;
      });
    } catch (e) {
      setState(() {
        _isSuppliersLoading = false;
      });
      showErrorTopSnackBar(
          context, "Erreur lors du chargement des fournisseurs");
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
      _items.add({
        'description': description,
        'quantity': quantity.toInt(),
        'unitPrice': unitPrice,
        'supplierId': supplierId,
        'supplier': supplierName,
        'invoiceNumber': invoiceNumber,
        'salesRate': salesRate,
      });
      widget.onItemsChanged(_items);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      widget.onItemsChanged(_items);
    });
  }

  void _duplicateItem(int index) {
    setState(() {
      final item = _items[index];
      _items.add(Map<String, dynamic>.from(item));
      widget.onItemsChanged(_items);
    });
  }

  void _editItem(int index, Map<String, dynamic> updatedItem) {
    setState(() {
      _items[index] = updatedItem;
      widget.onItemsChanged(_items);
    });
  }

  void _submit() async {
    if (_items.isEmpty) {
      showErrorTopSnackBar(context, "Ajoutez au moins un article.");
      return;
    }

    // Validation supplémentaire pour les achats en dette
    if (widget.isDebtPurchase) {
      // Vérifier que le client a des informations valides
      if (widget.customer.id <= 0) {
        showErrorTopSnackBar(context, "Informations du client invalides.");
        return;
      }

      // Vérifier que les articles ont des prix valides
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
        if (unitPrice <= 0) {
          showErrorTopSnackBar(context,
              "Le prix unitaire de l'article ${i + 1} doit être supérieur à 0.");
          return;
        }
      }
    }

    setState(() => _isLoading = true);
    try {
      final user = await authService.getUserInfo();
      if (user?.id == null) {
        showErrorTopSnackBar(context, "Utilisateur non connecté");
        setState(() => _isLoading = false);
        return;
      }

      // Log des informations pour debug
      print('=== CRÉATION ACHAT ===');
      print('Client ID: ${widget.customer.id}');
      print(
          'Client nom: ${widget.customer.firstName} ${widget.customer.lastName}');
      print('Client téléphone: ${widget.customer.phoneNumber}');
      print('Versement ID: ${widget.versement?.id}');
      print('Is Debt Purchase: ${widget.isDebtPurchase}');
      print('Nombre d\'articles: ${_items.length}');

      final createAchatDto = CreateAchatDto(
        versementId: widget.versement?.id,
        items: _items
            .map((item) => CreateItemDto(
                  description: item['description']?.toString() ?? '',
                  quantity: (item['quantity'] as num?)?.toInt() ?? 0,
                  unitPrice: (item['unitPrice'] as num?)?.toDouble() ?? 0.0,
                  invoiceNumber: item['invoiceNumber']?.toString() ?? '',
                  supplierId: item['supplierId']?.toInt() ?? 0,
                  salesRate: (item['salesRate'] as num?)?.toDouble() ?? 0.0,
                ))
            .toList(),
      );

      // Utiliser la méthode appropriée selon le type d'achat
      final result = await achatServices.createAchatForClient(
        clientId: widget.customer.id,
        userId: user!.id,
        dto: createAchatDto,
      );
      if (!mounted) return;
      if (result.isSuccess) {
        widget.onFinish();
        final message = widget.isDebtPurchase
            ? "Dette créée avec succès !"
            : "Achat créé avec succès !";
        showSuccessTopSnackBar(context, message);
      } else {
        String message = result.errorMessage ?? "Erreur inconnue";
        if (result.errors != null && result.errors!.isNotEmpty) {
          message = result.errors!.join('\n');
        }

        // Message spécial pour les erreurs de dette
        if (widget.isDebtPurchase && message.contains('getTotalDebt()')) {
          message =
              "Erreur lors de la création de la dette. Le client pourrait avoir des informations manquantes. Veuillez vérifier les données du client et réessayer.";
        }

        showErrorTopSnackBar(context, message);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = "Erreur: ${e.toString()}";
        if (widget.isDebtPurchase) {
          errorMessage =
              "Erreur lors de la création de la dette. Veuillez réessayer.";
        }
        showErrorTopSnackBar(context, errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding:
              const EdgeInsets.only(top: 18, left: 0, right: 0, bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Articles',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (widget.isDebtPurchase) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF7F78AF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFF7F78AF)),
                                ),
                                child: const Text(
                                  'Dette',
                                  style: TextStyle(
                                    color: Color(0xFF7F78AF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.customer.firstName} ${widget.customer.lastName}',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.versement != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Versement: ${widget.versement!.reference ?? ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Formulaire d'ajout d'article
                PackageItemForm(
                  suppliers: _suppliers,
                  onAddItem: _addItem,
                ),
                const SizedBox(height: 20),
                // Liste des articles
                Expanded(
                  child: PackageItemsList(
                    items: _items,
                    onRemoveItem: _removeItem,
                    onDuplicateItem: _duplicateItem,
                    onEditItem: _editItem,
                    suppliers: _suppliers,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Footer avec bouton de validation
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              if (_items.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
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
                          _items.fold<double>(
                            0,
                            (sum, item) =>
                                sum + (item['quantity'] * item['unitPrice']),
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
              ],
              confirmationButton(
                isLoading: _isLoading,
                onPressed: _submit,
                label: widget.isDebtPurchase ? 'Créer la dette' : 'Valider',
                icon: widget.isDebtPurchase
                    ? Icons.credit_card
                    : Icons.verified_outlined,
                subLabel: 'Enregistrement...',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
