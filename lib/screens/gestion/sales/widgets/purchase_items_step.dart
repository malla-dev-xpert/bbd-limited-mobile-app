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
  final Versement versement;
  final List<Map<String, dynamic>> initialItems;
  final void Function(List<Map<String, dynamic>>) onItemsChanged;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  const PurchaseItemsStep({
    Key? key,
    required this.customer,
    required this.versement,
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
  ) {
    setState(() {
      _items.add({
        'description': description,
        'quantity': quantity.toInt(),
        'unitPrice': unitPrice,
        'supplierId': supplierId,
        'supplier': supplierName,
        'invoiceNumber': invoiceNumber,
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
    setState(() => _isLoading = true);
    try {
      final user = await authService.getUserInfo();
      if (user?.id == null) {
        showErrorTopSnackBar(context, "Utilisateur non connecté");
        setState(() => _isLoading = false);
        return;
      }
      final createAchatDto = CreateAchatDto(
        versementId: widget.versement.id!,
        items: _items
            .map((item) => CreateItemDto(
                  description: item['description']?.toString() ?? '',
                  quantity: (item['quantity'] as num?)?.toInt() ?? 0,
                  unitPrice: (item['unitPrice'] as num?)?.toDouble() ?? 0.0,
                  invoiceNumber: item['invoiceNumber']?.toString() ?? '',
                  supplierId: item['supplierId']?.toInt() ?? 0,
                ))
            .toList(),
      );
      final result = await achatServices.createAchatForClient(
        clientId: widget.customer.id,
        userId: user!.id,
        dto: createAchatDto,
      );
      if (!mounted) return;
      if (result.isSuccess) {
        widget.onFinish();
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
        showErrorTopSnackBar(context, "Erreur: \\${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuppliersLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Ajouter les articles',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Column(
              children: [
                PackageItemForm(
                  onAddItem: _addItem,
                  suppliers: _suppliers,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: PackageItemsList(
                    items: _items,
                    suppliers: _suppliers,
                    onRemoveItem: _removeItem,
                    onDuplicateItem: _duplicateItem,
                    onEditItem: _editItem,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
                "Total: ${currencyFormat.format(_items.fold<double>(0, (sum, item) => sum + (item['quantity'] * item['unitPrice'])))}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.grey),
                  label: const Text('Retour',
                      style: TextStyle(color: Colors.grey)),
                ),
                Expanded(
                  child: confirmationButton(
                      isLoading: _isLoading,
                      onPressed: _submit,
                      label: 'Valider',
                      icon: Icons.verified_outlined,
                      subLabel: 'Enregistrement...'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
