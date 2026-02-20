import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/core/services/access_control_service.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/components/item_detail_chip.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/screens/gestion/sales/edit_article_screen.dart';

/// Écran "Liste des articles" : récupère tous les achats, affiche tous les items
/// avec le même design que la section items des historiques d'achats.
class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({super.key});

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  final AchatServices _achatsService = AchatServices();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateFilterController = TextEditingController();
  List<Achat> _achats = [];
  List<Map<String, dynamic>> _allItems = [];
  bool _isLoading = true;
  bool _actionLoading = false;
  final Set<String> _confirmedArticles = {};
  DateTime? _selectedDate;

  List<Map<String, dynamic>> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return _allItems.where((entry) {
      final item = entry['item'] as Items;
      final achat = entry['achat'] as Achat;
      final matchesSearch = query.isEmpty ||
          (item.description?.toLowerCase().contains(query) ?? false) ||
          (item.invoiceNumber?.toLowerCase().contains(query) ?? false) ||
          (item.supplierName?.toLowerCase().contains(query) ?? false);
      if (!matchesSearch) return false;
      if (_selectedDate == null) return true;
      final achatDate = achat.createdAt ?? DateTime.now();
      return achatDate.year == _selectedDate!.year &&
          achatDate.month == _selectedDate!.month &&
          achatDate.day == _selectedDate!.day;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAchats();
    _searchController.addListener(() => setState(() {}));
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _dateFilterController.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadAchats() async {
    setState(() => _isLoading = true);
    try {
      final achats = await _achatsService.findAll();
      final allItems = <Map<String, dynamic>>[];
      for (var achat in achats) {
        if (achat.items != null) {
          for (var item in achat.items!) {
            allItems.add({'item': item, 'achat': achat});
          }
        }
      }
      setState(() {
        _achats = achats;
        _allItems = allItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context).translate('error_loading_purchases'));
      }
    }
  }

  String _formatAmount(double? amount) {
    if (amount == null) return '0,00';
    return NumberFormat.currency(locale: 'fr_FR', symbol: '')
        .format(amount)
        .trim();
  }

  Future<_ConfirmDeliveryData?> _showConfirmDeliveryDialog(Items item) async {
    final cartonController = TextEditingController(
        text: item.carton != null ? item.carton.toString() : '');
    final quantityPerCartonController = TextEditingController(
        text: item.quantityPerCarton != null
            ? item.quantityPerCarton.toString()
            : '');
    int? quantityTotal;
    void computeTotal() {
      final c = int.tryParse(cartonController.text);
      final qpc = int.tryParse(quantityPerCartonController.text);
      if (c != null && qpc != null && c > 0) quantityTotal = c * qpc;
    }

    return showDialog<_ConfirmDeliveryData?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            computeTotal();
            return Dialog(
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .translate('confirm_delivery_dialog_title'),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    buildTextField(
                      controller: cartonController,
                      label: AppLocalizations.of(context).translate('carton'),
                      icon: Icons.inventory_2,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    buildTextField(
                      controller: quantityPerCartonController,
                      label: AppLocalizations.of(context)
                          .translate('quantity_per_carton'),
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate('total_quantity'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          quantityTotal != null
                              ? quantityTotal.toString()
                              : '—',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(null),
                          child: Text(AppLocalizations.of(context)
                              .translate('cancel')),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1E49),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          onPressed: () {
                            final c = int.tryParse(cartonController.text);
                            final qpc =
                                int.tryParse(quantityPerCartonController.text);
                            final q = quantityTotal ??
                                (item.quantity != null ? item.quantity! : null);
                            Navigator.of(ctx).pop(_ConfirmDeliveryData(
                              carton: c,
                              quantityPerCarton: qpc,
                              quantity: q ??
                                  (c != null && qpc != null ? c * qpc : null),
                            ));
                          },
                          child: Text(AppLocalizations.of(context)
                              .translate('confirm_short')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmArticle(
    String itemId,
    Items item,
    Achat achat, {
    int? carton,
    int? quantityPerCarton,
    int? quantity,
  }) async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    try {
      final user = await AuthService().getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('user_not_connected'));
        return;
      }
      final id = int.parse(itemId);
      final quantitySent = quantity ?? item.quantity;
      final cartonSent = carton ?? item.carton;
      final qpcSent = quantityPerCarton ?? item.quantityPerCarton;
      final itemQuantities = [
        AchatServices.itemQuantityUpdate(id,
            quantity: quantitySent,
            carton: cartonSent,
            quantityPerCarton: qpcSent),
      ];
      final result = await _achatsService.confirmDelivery(
        itemIds: [id],
        userId: user.id,
        itemQuantities: itemQuantities,
      );

      if (result.isSuccess) {
        setState(() {
          _confirmedArticles.add(itemId);
          final updated = item.copyWith(
            carton: cartonSent,
            quantityPerCarton: qpcSent,
            quantity: quantitySent,
          );
          for (var a in _achats) {
            final idx =
                a.items?.indexWhere((i) => i.id?.toString() == itemId) ?? -1;
            if (idx != -1) {
              a.items![idx] = updated;
              a.items![idx].status = Status.RECEIVED;
            }
          }
          final idx = _allItems.indexWhere(
              (e) => (e['item'] as Items).id?.toString() == itemId);
          if (idx != -1) {
            _allItems[idx] = {
              'item': updated.copyWith(status: Status.RECEIVED),
              'achat': _allItems[idx]['achat'],
            };
          }
        });
        showSuccessTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_item_received_success'));
      } else {
        showErrorTopSnackBar(
            context,
            result.errorMessage ??
                AppLocalizations.of(context)
                    .translate('purchase_history_confirmation_error'));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showEditArticleDialog(Items item, Achat achat) async {
    final updated = await Navigator.push<Items>(
      context,
      MaterialPageRoute(
        builder: (context) => EditArticleScreen(item: item, achat: achat),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        for (var a in _achats) {
          final idx = a.items?.indexWhere((i) => i.id == updated.id) ?? -1;
          if (idx != -1) {
            a.items![idx] = updated;
            break;
          }
        }
        final idx = _allItems.indexWhere(
            (e) => (e['item'] as Items).id == updated.id);
        if (idx != -1) {
          _allItems[idx] = {'item': updated, 'achat': _allItems[idx]['achat']};
        }
      });
    }
  }

  void _confirmReverseArticle(Items item, Achat achat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)
                    .translate('purchase_history_reverse_confirm_title'),
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(AppLocalizations.of(context)
            .translate('purchase_history_reverse_confirm_message')
            .replaceAll('{description}', item.description ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)
                .translate('purchase_history_delete_confirm_cancel')),
          ),
          TextButton(
            onPressed: () {
              _reverseItem(item, achat);
              Navigator.pop(context);
            },
            child: Text(
              AppLocalizations.of(context)
                  .translate('purchase_history_reverse_confirm_reverse'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reverseItem(Items item, Achat achat) async {
    setState(() => _actionLoading = true);
    try {
      final user = await AuthService().getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('user_not_connected'));
        return;
      }
      final itemServices = ItemServices();
      final result = await itemServices.reverseItem(
        item.id!,
        user.id,
        achat.clientId ?? 0,
      );
      if (result == "DELETED_AND_REVERTED") {
        setState(() {
          for (var a in _achats) {
            final itemIndex =
                a.items?.indexWhere((i) => i.id == item.id) ?? -1;
            if (itemIndex != -1) {
              a.items![itemIndex].status = Status.PENDING;
            }
          }
          final idx = _allItems
              .indexWhere((e) => (e['item'] as Items).id == item.id);
          if (idx != -1) {
            _allItems[idx] = {
              'item': (_allItems[idx]['item'] as Items)
                  .copyWith(status: Status.PENDING),
              'achat': _allItems[idx]['achat'],
            };
          }
          _confirmedArticles.remove(item.id?.toString());
        });
        showSuccessTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_item_reversed_success'));
      } else {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_unknown_error'));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _handleDeleteItem(Items item, Achat achat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)
            .translate('delete_item_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).translate('delete'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _actionLoading = true);
    try {
      final user = await AuthService().getUserInfo();
      if (user == null) return;
      final itemServices = ItemServices();
      final result =
          await itemServices.deleteItem(itemId: item.id!, userId: user.id);
      if (result.isSuccess && mounted) {
        setState(() {
          achat.items?.removeWhere((i) => i.id == item.id);
          _allItems.removeWhere((e) => (e['item'] as Items).id == item.id);
        });
        showSuccessTopSnackBar(
            context,
            AppLocalizations.of(context).translate('delete_item_success'));
      } else if (mounted) {
        showErrorTopSnackBar(
            context,
            result.errorMessage ??
                AppLocalizations.of(context).translate('delete_item_error'));
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context).translate('delete_item_error'));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Widget _buildItemCard(
      Map<String, dynamic> itemData, int index) {
    final item = itemData['item'] as Items;
    final achat = itemData['achat'] as Achat;
    final isConfirmed = _confirmedArticles.contains(item.id?.toString());
    final user = AuthService.currentUser;
    final access = AccessControlService();
    final canEdit = access.canEditItem(user);
    final canDelete = access.canDeleteItem(user);

    final slidableActions = <Widget>[
      if (canEdit)
        SlidableAction(
          onPressed: (_) => _showEditArticleDialog(item, achat),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          icon: Icons.edit,
          label: AppLocalizations.of(context).translate('edit'),
        ),
      if (canEdit)
        SlidableAction(
          onPressed: (item.status == Status.RECEIVED)
              ? (_) => _confirmReverseArticle(item, achat)
              : null,
          backgroundColor: (item.status == Status.RECEIVED)
              ? Colors.orange
              : Colors.grey[300]!,
          foregroundColor: Colors.white,
          icon: Icons.undo_outlined,
          label: AppLocalizations.of(context).translate('reverse'),
        ),
      if (canDelete)
        SlidableAction(
          onPressed: (item.status != Status.RECEIVED)
              ? (_) => _handleDeleteItem(item, achat)
              : null,
          backgroundColor: (item.status != Status.RECEIVED)
              ? Colors.red
              : Colors.grey[300]!,
          foregroundColor: Colors.white,
          icon: Icons.delete,
          label: AppLocalizations.of(context).translate('delete'),
        ),
    ];

    return Slidable(
      key: ValueKey('item_${item.id ?? index}'),
      endActionPane: slidableActions.isEmpty
          ? null
          : ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.35,
              children: slidableActions,
            ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1E49).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Color(0xFF1A1E49),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description ?? 'N/A',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                            children: [
                              TextSpan(
                                text:
                                    '${AppLocalizations.of(context).translate('invoice_number')}: ',
                              ),
                              TextSpan(
                                text: item.invoiceNumber ?? 'N/A',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Image.asset(
                    item.status == Status.RECEIVED
                        ? 'assets/images/delivery.png'
                        : 'assets/images/no-delivery.png',
                    width: 44,
                    height: 44,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey[200], height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ItemDetailChip(
                    text:
                        '${AppLocalizations.of(context).translate('carton')}: ${item.carton ?? 0}',
                    icon: Icons.inventory,
                  ),
                  const SizedBox(width: 16),
                  ItemDetailChip(
                    text:
                        '${AppLocalizations.of(context).translate('quantity_per_carton_2')}: ${item.quantityPerCarton ?? 0}',
                    icon: Icons.format_list_numbered,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ItemDetailChip(
                    text:
                        '${AppLocalizations.of(context).translate('total_quantity')}: ${item.quantity ?? 0}',
                    icon: Icons.numbers,
                  ),
                  ItemDetailChip(
                    text: '${_formatAmount(item.unitPrice)} ¥',
                    icon: Icons.attach_money,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ItemDetailChip(
                    text:
                        '${AppLocalizations.of(context).translate('weight')}: ${item.totalWeight ?? 0}',
                    icon: Icons.scale,
                  ),
                  const SizedBox(width: 16),
                  ItemDetailChip(
                    text:
                        '${AppLocalizations.of(context).translate('cbn')}: ${item.cbnTotal ?? 0}',
                    icon: Icons.straighten,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  ItemDetailChip(
                    text:
                        '${AppLocalizations.of(context).translate('sales_rate')}: ${item.salesRate ?? 0}',
                    icon: Icons.trending_up,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 8),
                  ItemDetailChip(
                    text:
                        '${AppLocalizations.of(context).translate('total')}: ${_formatAmount((item.quantity ?? 0) * (item.unitPrice ?? 0))} ¥',
                    icon: Icons.calculate,
                    fullWidth: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.business,
                        size: 16, color: Colors.purple[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${AppLocalizations.of(context).translate('supplier')}: ${item.supplierName ?? AppLocalizations.of(context).translate('not_available')}',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.purple[900],
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.of(context).translate('client')}: ${achat.client ?? 'N/A'}',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue[900],
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${AppLocalizations.of(context).translate('purchase_history_date')}: ${DateFormat('dd/MM/yyyy').format(achat.createdAt ?? DateTime.now())}',
                            style: TextStyle(
                                fontSize: 16, color: Colors.blue[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isConfirmed && item.status != Status.RECEIVED) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pending_actions,
                          size: 20, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('purchase_history_item_pending'),
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange[900],
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final data =
                              await _showConfirmDeliveryDialog(item);
                          if (data != null && mounted) {
                            await _confirmArticle(
                                item.id!.toString(),
                                item,
                                achat,
                                carton: data.carton,
                                quantityPerCarton: data.quantityPerCarton,
                                quantity: data.quantity);
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(
                          _actionLoading
                              ? AppLocalizations.of(context)
                                  .translate('loading_short')
                              : AppLocalizations.of(context)
                                  .translate('confirm_short'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1E49),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (item.status == Status.RECEIVED) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 20, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)
                            .translate('purchase_history_item_received'),
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.green[900],
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _dateFilterController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('home_items_list'),
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Recherche et filtre par date — style moderne
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A1E49).withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildTextField(
                        controller: _searchController,
                        label: AppLocalizations.of(context)
                            .translate('items_list_search_hint'),
                        icon: Icons.search_rounded,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      buildTextField(
                        controller: _dateFilterController,
                        label: AppLocalizations.of(context)
                            .translate('filter_by_date'),
                        icon: Icons.calendar_month_rounded,
                        readOnly: true,
                        onTap: _pickDate,
                        suffixIcon: _selectedDate != null
                            ? IconButton(
                                onPressed: _clearDateFilter,
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                                tooltip: AppLocalizations.of(context)
                                    .translate('clear_filter'),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
                // Liste
                Expanded(
                  child: _filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                _allItems.isEmpty
                                    ? AppLocalizations.of(context)
                                        .translate('purchase_history_no_items')
                                    : AppLocalizations.of(context).translate(
                                        'items_list_no_results'),
                                style: TextStyle(
                                    fontSize: 20, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAchats,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) =>
                                _buildItemCard(_filteredItems[index], index),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _ConfirmDeliveryData {
  final int? carton;
  final int? quantityPerCarton;
  final int? quantity;
  _ConfirmDeliveryData(
      {this.carton, this.quantityPerCarton, this.quantity});
}
