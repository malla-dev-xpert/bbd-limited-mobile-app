import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/widgets/filters/filter_button.dart';
import 'package:bbd_limited/widgets/filters/filter_sheet.dart';
import 'package:bbd_limited/widgets/filters/date_range_selector.dart';
import 'package:bbd_limited/components/reusable_item_card.dart';
import 'package:intl/intl.dart';
import 'achat_detail_screen.dart';

/// Entrée liste : un item + son achat parent (pour filtre date et navigation).
class _ItemWithAchat {
  final Items item;
  final Achat achat;

  _ItemWithAchat({required this.item, required this.achat});
}

/// Page des achats d'un client : liste d'items avec filtres (recherche, date, fournisseur).
/// Design = liste d'items (comme items_list_screen). Filtres sur une ligne sur tablette.
class CustomerPurchasesPage extends StatefulWidget {
  final Partner customer;

  const CustomerPurchasesPage({super.key, required this.customer});

  @override
  State<CustomerPurchasesPage> createState() => _CustomerPurchasesPageState();
}

class _CustomerPurchasesPageState extends State<CustomerPurchasesPage> {
  final TextEditingController _searchController = TextEditingController();

  List<_ItemWithAchat> _allItems = [];
  List<_ItemWithAchat> _filteredItems = [];
  DateTime? _filterDateStart;
  DateTime? _filterDateEnd;
  String? _selectedSupplierName;

  static const Color _primary = Color(0xFF1A1E49);

  @override
  void initState() {
    super.initState();
    _collectItems();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  void _collectItems() {
    final list = <_ItemWithAchat>[];
    for (var v in widget.customer.versements ?? []) {
      for (var a in v.achats ?? []) {
        for (var item in a.items ?? []) {
          list.add(_ItemWithAchat(item: item, achat: a));
        }
      }
    }
    list.sort((a, b) {
      final da = a.achat.createdAt ?? DateTime(0);
      final db = b.achat.createdAt ?? DateTime(0);
      return db.compareTo(da);
    });
    setState(() {
      _allItems = list;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredItems = _allItems.where((e) {
        final matchSearch = query.isEmpty ||
            (e.item.description?.toLowerCase().contains(query) ?? false) ||
            (e.item.invoiceNumber?.toLowerCase().contains(query) ?? false);
        final matchDate = _filterDateStart == null && _filterDateEnd == null ||
            _matchDate(e.achat.createdAt);
        final matchSupplier = _selectedSupplierName == null ||
            (e.item.supplierName == _selectedSupplierName);
        return matchSearch && matchDate && matchSupplier;
      }).toList();
    });
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
    for (var e in _allItems) {
      if (e.item.supplierName != null && e.item.supplierName!.isNotEmpty) {
        set.add(e.item.supplierName!);
      }
    }
    final list = set.toList()..sort();
    return list;
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
                  _applyFilters();
                });
              },
              onApply: () => Navigator.pop(ctx),
              onReset: () {
                setState(() {
                  _filterDateStart = null;
                  _filterDateEnd = null;
                  _applyFilters();
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
    setState(() {
      _selectedSupplierName = selected;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isTablet = DeviceBreakpoints.isTablet(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '${widget.customer.firstName} ${widget.customer.lastName}',
          style: AppTextSize.titleStyle(context, color: Colors.white),
        ),
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: isTablet
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => _applyFilters(),
                          decoration: InputDecoration(
                            hintText:
                                loc.translate('purchase_history_search_hint'),
                            prefixIcon:
                                Icon(Icons.search, color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.md),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                          ),
                          style: AppTextSize.bodyStyle(context),
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      FilterButton(
                        label: _filterDateStart != null ||
                                _filterDateEnd != null
                            ? '${_formatDate(_filterDateStart)} - ${_formatDate(_filterDateEnd)}'
                            : loc.translate('filter_by_date'),
                        isActive:
                            _filterDateStart != null || _filterDateEnd != null,
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
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => _applyFilters(),
                        decoration: InputDecoration(
                          hintText:
                              loc.translate('purchase_history_search_hint'),
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        style: AppTextSize.bodyStyle(context),
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
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: AppSpacing.xxl * 2,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: AppSpacing.lg),
                          Text(
                            _allItems.isEmpty
                                ? 'Aucun article'
                                : 'Aucun article ne correspond aux filtres',
                            style: AppTextSize.titleStyle(context,
                                color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? AppSpacing.xl : AppSpacing.lg,
                    ),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final e = _filteredItems[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md),
                        child: ReusableItemCard(
                          item: e.item,
                          achat: e.achat,
                          showSupplierInfo: true,
                          showPurchaseInfo: true,
                          showReceptionInfo: true,
                          onTap: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AchatDetailScreen(
                                  achat: e.achat,
                                ),
                              ),
                            ).then((_) => setState(() {}));
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return AppLocalizations.of(context).translate('not_available');
    return DateFormat('dd/MM/yyyy').format(d);
  }
}
