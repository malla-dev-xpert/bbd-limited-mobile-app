import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/core/services/access_control_service.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/components/reusable_item_card.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/widgets/filters/filter_button.dart';
import 'package:bbd_limited/widgets/filters/filter_sheet.dart';
import 'package:bbd_limited/widgets/filters/date_range_selector.dart';
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
  List<Achat> _achats = [];
  List<Map<String, dynamic>> _allItems = [];
  bool _isLoading = true;
  bool _actionLoading = false;
  final Set<String> _confirmedArticles = {};
  DateTime? _filterDateStart;
  DateTime? _filterDateEnd;
  String? _selectedSupplierName;
  String? _selectedClientName;

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
      final matchesDate = _filterDateStart == null && _filterDateEnd == null ||
          _matchDate(achat.createdAt);
      if (!matchesDate) return false;
      final matchesSupplier = _selectedSupplierName == null ||
          (item.supplierName == _selectedSupplierName);
      if (!matchesSupplier) return false;
      final matchesClient =
          _selectedClientName == null || (achat.client == _selectedClientName);
      return matchesClient;
    }).toList();
  }

  bool _matchDate(DateTime? d) {
    if (d == null) return false;
    if (_filterDateStart != null && d.isBefore(_filterDateStart!)) return false;
    if (_filterDateEnd != null) {
      final endOfDay = DateTime(
        _filterDateEnd!.year,
        _filterDateEnd!.month,
        _filterDateEnd!.day,
        23,
        59,
        59,
      );
      if (d.isAfter(endOfDay)) return false;
    }
    return true;
  }

  List<String> _getUniqueSupplierNames() {
    final set = <String>{};
    for (var entry in _allItems) {
      final item = entry['item'] as Items;
      if (item.supplierName != null && item.supplierName!.isNotEmpty) {
        set.add(item.supplierName!);
      }
    }
    return set.toList()..sort();
  }

  List<String> _getUniqueClientNames() {
    final set = <String>{};
    for (var entry in _allItems) {
      final achat = entry['achat'] as Achat;
      if (achat.client != null && achat.client!.isNotEmpty) {
        set.add(achat.client!);
      }
    }
    return set.toList()..sort();
  }

  Future<void> _openDateFilter() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: DateRangeSelector(
              initialValue: _filterDateStart != null || _filterDateEnd != null
                  ? DateRangeResult(
                      start: _filterDateStart,
                      end: _filterDateEnd,
                      preset: DateRangePreset.custom,
                    )
                  : null,
              onChanged: (r) {
                setState(() {
                  _filterDateStart = r.start;
                  _filterDateEnd = r.end;
                });
              },
              onApply: () => Navigator.pop(ctx),
              onReset: () {
                setState(() {
                  _filterDateStart = null;
                  _filterDateEnd = null;
                });
                Navigator.pop(ctx);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSupplierFilter() async {
    final names = _getUniqueSupplierNames();
    final options =
        names.map((n) => FilterOption<String>(value: n, label: n)).toList();
    final loc = AppLocalizations.of(context);
    final selected = await FilterSheet.show<String>(
      context: context,
      title: loc.translate('filter_by_supplier'),
      searchHint: loc.translate('search_supplier_placeholder'),
      options: options,
      initialValue: _selectedSupplierName,
      showAllOption: true,
      allOptionLabel: loc.translate('container_all'),
      noResultsLabel: loc.translate('no_results'),
    );
    setState(() => _selectedSupplierName = selected);
  }

  Future<void> _openClientFilter() async {
    final names = _getUniqueClientNames();
    final options =
        names.map((n) => FilterOption<String>(value: n, label: n)).toList();
    final loc = AppLocalizations.of(context);
    final selected = await FilterSheet.show<String>(
      context: context,
      title: loc.translate('filter_by_client'),
      searchHint: loc.translate('search_client_placeholder'),
      options: options,
      initialValue: _selectedClientName,
      showAllOption: true,
      allOptionLabel: loc.translate('container_all'),
      noResultsLabel: loc.translate('no_results'),
    );
    setState(() => _selectedClientName = selected);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('dd/MM/yyyy').format(d);
  }

  @override
  void initState() {
    super.initState();
    _loadAchats();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('error_loading_purchases'));
      }
    }
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
                          child: Text(
                              AppLocalizations.of(context).translate('cancel')),
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
          final idx = _allItems
              .indexWhere((e) => (e['item'] as Items).id?.toString() == itemId);
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
        final idx =
            _allItems.indexWhere((e) => (e['item'] as Items).id == updated.id);
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
              child:
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)
                    .translate('purchase_history_reverse_confirm_title'),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
            final itemIndex = a.items?.indexWhere((i) => i.id == item.id) ?? -1;
            if (itemIndex != -1) {
              a.items![itemIndex].status = Status.PENDING;
            }
          }
          final idx =
              _allItems.indexWhere((e) => (e['item'] as Items).id == item.id);
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
        title: Text(
            AppLocalizations.of(context).translate('delete_item_confirmation')),
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
        showSuccessTopSnackBar(context,
            AppLocalizations.of(context).translate('delete_item_success'));
      } else if (mounted) {
        showErrorTopSnackBar(
            context,
            result.errorMessage ??
                AppLocalizations.of(context).translate('delete_item_error'));
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('delete_item_error'));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Widget _buildItemCard(Map<String, dynamic> itemData, int index) {
    final item = itemData['item'] as Items;
    final achat = itemData['achat'] as Achat;
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
          backgroundColor:
              (item.status != Status.RECEIVED) ? Colors.red : Colors.grey[300]!,
          foregroundColor: Colors.white,
          icon: Icons.delete,
          label: AppLocalizations.of(context).translate('delete'),
        ),
    ];

    return ReusableItemCard(
      item: item,
      achat: achat,
      actions: slidableActions,
      showSupplierInfo: true,
      showPurchaseInfo: true,
      isLoading: _actionLoading,
      onConfirm: (item, achat) async {
        final data = await _showConfirmDeliveryDialog(item);
        if (data != null && mounted) {
          await _confirmArticle(item.id!.toString(), item, achat!,
              carton: data.carton,
              quantityPerCarton: data.quantityPerCarton,
              quantity: data.quantity);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      appBar: AppBar(
        title: Text(
          loc.translate('items_list_title'),
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
                // Recherche + filtres date / fournisseur (même ligne sur tablette)
                Container(
                  margin: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    0,
                  ),
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.lg),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A1E49).withOpacity(0.06),
                        blurRadius: AppSpacing.lg,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isTablet
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: buildTextField(
                                controller: _searchController,
                                label: loc.translate('items_list_search_hint'),
                                icon: Icons.search_rounded,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            SizedBox(width: AppSpacing.md),
                            FilterButton(
                              label: _filterDateStart != null ||
                                      _filterDateEnd != null
                                  ? '${_formatDate(_filterDateStart)} - ${_formatDate(_filterDateEnd)}'
                                  : loc.translate('filter_by_date'),
                              isActive: _filterDateStart != null ||
                                  _filterDateEnd != null,
                              icon: Icons.calendar_month,
                              onTap: _openDateFilter,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            FilterButton(
                              label:
                                  '${loc.translate('filter_label_supplier')} · ${_selectedSupplierName ?? loc.translate('container_all')}',
                              isActive: _selectedSupplierName != null,
                              icon: Icons.business,
                              onTap: _openSupplierFilter,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            FilterButton(
                              label:
                                  '${loc.translate('filter_label_client')} · ${_selectedClientName ?? loc.translate('container_all')}',
                              isActive: _selectedClientName != null,
                              icon: Icons.person_outline,
                              onTap: _openClientFilter,
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            buildTextField(
                              controller: _searchController,
                              label: loc.translate('items_list_search_hint'),
                              icon: Icons.search_rounded,
                              onChanged: (_) => setState(() {}),
                            ),
                            SizedBox(height: AppSpacing.md),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  FilterButton(
                                    label: _filterDateStart != null ||
                                            _filterDateEnd != null
                                        ? '${_formatDate(_filterDateStart)} - ${_formatDate(_filterDateEnd)}'
                                        : loc.translate('filter_by_date'),
                                    isActive: _filterDateStart != null ||
                                        _filterDateEnd != null,
                                    icon: Icons.calendar_month,
                                    onTap: _openDateFilter,
                                  ),
                                  FilterButton(
                                    label:
                                        '${loc.translate('filter_label_supplier')} · ${_selectedSupplierName ?? loc.translate('container_all')}',
                                    isActive: _selectedSupplierName != null,
                                    icon: Icons.business,
                                    onTap: _openSupplierFilter,
                                  ),
                                  FilterButton(
                                    label:
                                        '${loc.translate('filter_label_client')} · ${_selectedClientName ?? loc.translate('container_all')}',
                                    isActive: _selectedClientName != null,
                                    icon: Icons.person_outline,
                                    onTap: _openClientFilter,
                                  ),
                                ],
                              ),
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
                                    : AppLocalizations.of(context)
                                        .translate('items_list_no_results'),
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
  _ConfirmDeliveryData({this.carton, this.quantityPerCarton, this.quantity});
}
