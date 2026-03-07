import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/achats/update_achat_dto.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/widgets/filters/filter_button.dart';
import 'package:bbd_limited/widgets/filters/filter_sheet.dart';
import 'package:bbd_limited/widgets/filters/date_range_selector.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'achat_detail_screen.dart';
import 'package:bbd_limited/screens/gestion/sales/edit_article_screen.dart';
import 'package:bbd_limited/core/services/access_control_service.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/reusable_item_card.dart';

class HistoriqueAchatsScreen extends StatefulWidget {
  const HistoriqueAchatsScreen({super.key});

  @override
  State<HistoriqueAchatsScreen> createState() => _HistoriqueAchatsScreenState();
}

class _HistoriqueAchatsScreenState extends State<HistoriqueAchatsScreen> {
  final AchatServices _achatsService = AchatServices();
  List<Achat> _achats = [];
  List<Achat> _filteredAchats = [];
  bool _isLoading = true;
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  Status? _selectedStatus;
  DateTime? _filterDateStart;
  DateTime? _filterDateEnd;
  String? _selectedSupplierName;
  String? _selectedClientName;
  bool _showItemsDirectly =
      false; // Mode d'affichage: false = achats, true = items
  final Set<String> confirmedArticles = {};

  @override
  void initState() {
    super.initState();
    _chargerAchats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chargerAchats() async {
    final achats = await _achatsService.findAll();
    setState(() {
      _achats = achats;
      _filteredAchats = achats;
      _isLoading = false;
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
    for (var a in _achats) {
      for (var item in a.items ?? []) {
        if (item.supplierName != null && item.supplierName!.isNotEmpty) {
          set.add(item.supplierName!);
        }
      }
    }
    return set.toList()..sort();
  }

  List<String> _getUniqueClientNames() {
    final set = <String>{};
    for (var a in _achats) {
      if (a.client != null && a.client!.isNotEmpty) {
        set.add(a.client!);
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
                  _filterAchats();
                });
              },
              onApply: () => Navigator.pop(ctx),
              onReset: () {
                setState(() {
                  _filterDateStart = null;
                  _filterDateEnd = null;
                  _filterAchats();
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
      _filterAchats();
    });
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
    setState(() {
      _selectedClientName = selected;
      _filterAchats();
    });
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('dd/MM/yyyy').format(d);
  }

  void _filterAchats() {
    final searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _filteredAchats = _achats.where((achat) {
        bool matchesSearch;
        if (searchQuery.isEmpty) {
          matchesSearch = true;
        } else {
          final refMatch =
              (achat.referenceVersement?.toLowerCase().contains(searchQuery) ??
                  false);
          final clientMatch =
              (achat.client?.toLowerCase().contains(searchQuery) ?? false);
          final clientIdMatch = (achat.isDebt == true && achat.clientId != null)
              ? achat.clientId.toString().contains(searchQuery)
              : false;
          matchesSearch = refMatch || clientMatch || clientIdMatch;
        }

        final matchesStatus =
            _selectedStatus == null || achat.status == _selectedStatus;
        final matchesDate =
            _filterDateStart == null && _filterDateEnd == null ||
                _matchDate(achat.createdAt);
        final matchesSupplier = _selectedSupplierName == null ||
            (achat.items?.any(
                    (item) => item.supplierName == _selectedSupplierName) ??
                false);
        final matchesClient = _selectedClientName == null ||
            (achat.client == _selectedClientName);
        return matchesSearch &&
            matchesStatus &&
            matchesDate &&
            matchesSupplier &&
            matchesClient;
      }).toList();
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
          loc.translate('purchase_history_title'),
          style: AppTextSize.headlineStyle(
            context,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ).copyWith(letterSpacing: 0.5),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header fixe : recherche + filtres date/fournisseur (même ligne sur tablette)
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isTablet
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: buildTextField(
                              controller: _searchController,
                              label:
                                  loc.translate('purchase_history_search_hint'),
                              icon: Icons.search,
                              onChanged: (_) => _filterAchats(),
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
                            label:
                                loc.translate('purchase_history_search_hint'),
                            icon: Icons.search,
                            onChanged: (_) => _filterAchats(),
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
                SizedBox(height: AppSpacing.lg),
                Container(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          loc.translate('purchase_history_filter_status'),
                          style: AppTextSize.subtitleStyle(
                            context,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusFilterChip(context, null,
                                loc.translate('purchase_history_filter_all')),
                            _buildStatusFilterChip(
                                context,
                                Status.COMPLETED,
                                loc.translate(
                                    'purchase_history_filter_completed')),
                            _buildStatusFilterChip(
                                context,
                                Status.PENDING,
                                loc.translate(
                                    'purchase_history_filter_pending')),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      // Toggle pour afficher les achats ou les items
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildViewModeButton(
                                context: context,
                                label: loc.translate(
                                    'purchase_history_view_purchases'),
                                icon: Icons.receipt_long,
                                isSelected: !_showItemsDirectly,
                                onTap: () {
                                  setState(() {
                                    _showItemsDirectly = false;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildViewModeButton(
                                context: context,
                                label: loc
                                    .translate('purchase_history_view_items'),
                                icon: Icons.inventory_2,
                                isSelected: _showItemsDirectly,
                                onTap: () {
                                  setState(() {
                                    _showItemsDirectly = true;
                                  });
                                },
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
          // Contenu scrollable
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAchats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('purchase_history_no_purchases'),
                              style: AppTextSize.headlineStyle(
                                context,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _showItemsDirectly
                        ? _buildItemsListView()
                        : RefreshIndicator(
                            onRefresh: _chargerAchats,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredAchats.length,
                              itemBuilder: (context, index) {
                                final achat = _filteredAchats[index];
                                final user = AuthService.currentUser;
                                final canEditAchat = user != null &&
                                    !AccessControlService().isEmployeD(user);
                                return Slidable(
                                  key: ValueKey('achat_${achat.id ?? index}'),
                                  endActionPane: canEditAchat
                                      ? ActionPane(
                                          motion: const DrawerMotion(),
                                          extentRatio: 0.25,
                                          children: [
                                            SlidableAction(
                                              onPressed: (_) =>
                                                  _showEditDateDialog(achat),
                                              backgroundColor:
                                                  const Color(0xFF1976D2),
                                              foregroundColor: Colors.white,
                                              icon: Icons.edit_calendar,
                                              label:
                                                  AppLocalizations.of(context)
                                                      .translate('edit_date'),
                                            ),
                                          ],
                                        )
                                      : null,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
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
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () =>
                                            _showAchatDetails(context, achat),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '${AppLocalizations.of(context).translate('purchase_number')} : ${achat.id ?? 'N/A'}',
                                                          style: AppTextSize
                                                              .titleStyle(
                                                                  context,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .calendar_today,
                                                              size: 16,
                                                              color: Colors
                                                                  .grey[700]!,
                                                            ),
                                                            const SizedBox(
                                                                width: 6),
                                                            Text(
                                                              DateFormat(
                                                                      'dd/MM/yyyy')
                                                                  .format(achat
                                                                          .createdAt ??
                                                                      DateTime
                                                                          .now()),
                                                              style: AppTextSize.bodyStyle(
                                                                  context,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Colors
                                                                          .grey[
                                                                      700]!),
                                                            ),
                                                          ],
                                                        ),
                                                        if (achat.isDebt ==
                                                            true)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 8),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          16,
                                                                      vertical:
                                                                          2),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                        0xFF7F78AF)
                                                                    .withOpacity(
                                                                        0.1),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                                border: Border.all(
                                                                    color: const Color(
                                                                        0xFF7F78AF)),
                                                              ),
                                                              child: Text(
                                                                AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'purchase_history_debt'),
                                                                style:
                                                                    const TextStyle(
                                                                  color: Color(
                                                                      0xFF7F78AF),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 20),
                                                  Image.asset(
                                                    achat.status ==
                                                            Status.COMPLETED
                                                        ? 'assets/images/delivery.png'
                                                        : 'assets/images/no-delivery.png',
                                                    width: 44,
                                                    height: 44,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.person_outline,
                                                    size: 16,
                                                    color: Colors.grey[700]!,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      (achat.client != null &&
                                                              achat.client!
                                                                  .isNotEmpty)
                                                          ? achat.client!
                                                          : (achat.isDebt ==
                                                                      true &&
                                                                  achat.clientId !=
                                                                      null)
                                                              ? '${AppLocalizations.of(context).translate('client')} #${achat.clientId}'
                                                              : AppLocalizations
                                                                      .of(
                                                                          context)
                                                                  .translate(
                                                                      'not_available'),
                                                      style: TextStyle(
                                                        color:
                                                            Colors.grey[700]!,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (achat.clientPhone !=
                                                  null) ...[
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.phone_outlined,
                                                      size: 16,
                                                      color: Colors.grey[700]!,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      achat.clientPhone!,
                                                      style: TextStyle(
                                                        color:
                                                            Colors.grey[700]!,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              const SizedBox(height: 12),
                                              // Informations sur les articles
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[50],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: Colors.blue[200]!),
                                                ),
                                                child: Column(
                                                  children: [
                                                    _buildArticleInfoRow(
                                                      context,
                                                      Icons.inventory_2,
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'total_items'),
                                                      '${achat.items?.length ?? 0}',
                                                      Colors.blue[700]!,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    _buildArticleInfoRow(
                                                      context,
                                                      Icons.check_circle,
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'delivered_items'),
                                                      '${_getDeliveredItemsCount(achat)}/${_getTotalInvoicesCount(achat)}',
                                                      Colors.green[700]!,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    _buildArticleInfoRow(
                                                      context,
                                                      Icons.business,
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'suppliers'),
                                                      _getSuppliersInfo(achat),
                                                      Colors.orange[700]!,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              // Montant total
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF1A1E49)
                                                      .withOpacity(0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: const Color(
                                                              0xFF1A1E49)
                                                          .withOpacity(0.2)),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'purchase_history_total_amount'),
                                                      style: AppTextSize
                                                          .subtitleStyle(
                                                              context,
                                                              color: Colors
                                                                  .grey[600],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500),
                                                    ),
                                                    Text(
                                                      '${_formatAmount(achat.montantTotal)} ¥',
                                                      style: AppTextSize
                                                          .headlineStyle(
                                                              context,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: const Color(
                                                                  0xFF1A1E49)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double? amount) {
    if (amount == null) return "0,00";
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]} ',
        )
        .replaceAll('.', ',');
  }

  // Méthode pour compter les articles livrés (par numéro de facture)
  int _getDeliveredItemsCount(Achat achat) {
    if (achat.items == null) return 0;

    final deliveredInvoices = <String>{};
    for (var item in achat.items!) {
      if (item.status == Status.RECEIVED &&
          item.invoiceNumber != null &&
          item.invoiceNumber!.isNotEmpty) {
        deliveredInvoices.add(item.invoiceNumber!);
      }
    }
    return deliveredInvoices.length;
  }

  // Méthode pour compter le total des factures
  int _getTotalInvoicesCount(Achat achat) {
    if (achat.items == null) return 0;

    final allInvoices = <String>{};
    for (var item in achat.items!) {
      if (item.invoiceNumber != null && item.invoiceNumber!.isNotEmpty) {
        allInvoices.add(item.invoiceNumber!);
      }
    }
    return allInvoices.length;
  }

  // Méthode pour obtenir les informations sur les fournisseurs
  String _getSuppliersInfo(Achat achat) {
    if (achat.items == null || achat.items!.isEmpty) {
      return AppLocalizations.of(context).translate('none');
    }

    final suppliers = <String>{};
    for (var item in achat.items!) {
      if (item.supplierName != null && item.supplierName!.isNotEmpty) {
        suppliers.add(item.supplierName!);
      }
    }

    if (suppliers.isEmpty) {
      return AppLocalizations.of(context).translate('none');
    }

    if (suppliers.length == 1) {
      return AppLocalizations.of(context).translate('same_supplier');
    } else {
      return '${suppliers.length}';
    }
  }

  // Méthode pour construire une ligne d'information sur les articles
  Widget _buildArticleInfoRow(BuildContext context, IconData icon, String label,
      String value, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTextSize.subtitleStyle(
              context,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextSize.subtitleStyle(
            context,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showAchatDetails(BuildContext context, Achat achat) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => AchatDetailScreen(achat: achat),
      ),
    ).then((_) => setState(() {}));
  }

  void _showEditDateDialog(Achat achat) {
    DateTime selectedDate = achat.createdAt ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context).translate('edit_date')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppLocalizations.of(context).translate('purchase_number')} : ${achat.id ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  selectedDate = picked;
                  (context as Element).markNeedsBuild();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                      style: AppTextSize.subtitleStyle(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          confirmationButton(
            isLoading: isLoading,
            onPressed: () => _updateAchatDate(achat, selectedDate),
            label: AppLocalizations.of(context).translate('save'),
            icon: Icons.save,
            subLabel: AppLocalizations.of(context).translate('saving'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAchatDate(Achat achat, DateTime newDate) async {
    if (achat.id == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final user = await AuthService().getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('user_not_connected'));
        return;
      }

      final dto = UpdateAchatDto(createdAt: newDate);
      final result = await _achatsService.updateAchat(
        achatId: achat.id!,
        userId: user.id,
        dto: dto,
      );

      if (result.isSuccess) {
        setState(() {
          // Mettre à jour la date dans la liste locale
          for (int i = 0; i < _achats.length; i++) {
            if (_achats[i].id == achat.id) {
              _achats[i] = _achats[i].copyWith(createdAt: newDate);
            }
          }
          for (int i = 0; i < _filteredAchats.length; i++) {
            if (_filteredAchats[i].id == achat.id) {
              _filteredAchats[i] =
                  _filteredAchats[i].copyWith(createdAt: newDate);
            }
          }
        });
        showSuccessTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('date_updated_successfully'));
        Navigator.pop(context);
      } else {
        showErrorTopSnackBar(
            context,
            result.errorMessage ??
                AppLocalizations.of(context).translate('error_updating_date'));
      }
    } catch (e) {
      showErrorTopSnackBar(context,
          AppLocalizations.of(context).translate('error_updating_date'));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildStatusFilterChip(
      BuildContext context, Status? status, String label) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedStatus = isSelected ? null : status;
                _filterAchats();
              });
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1A1E49) : Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFF1A1E49) : Colors.grey[300]!,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1A1E49).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: AppTextSize.subtitleStyle(
                      context,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1E49) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTextSize.subtitleStyle(
                  context,
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
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
                      style: AppTextSize.headlineStyle(
                        context,
                        fontWeight: FontWeight.bold,
                      ),
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
                          style: AppTextSize.subtitleStyle(
                            context,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          quantityTotal != null
                              ? quantityTotal.toString()
                              : '—',
                          style: AppTextSize.subtitleStyle(
                            context,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
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

  Future<void> confirmArticle(
    String itemId,
    Items item,
    Achat achat, {
    int? carton,
    int? quantityPerCarton,
    int? quantity,
  }) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

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
        AchatServices.itemQuantityUpdate(
          id,
          quantity: quantitySent,
          carton: cartonSent,
          quantityPerCarton: qpcSent,
        ),
      ];
      final result = await _achatsService.confirmDelivery(
        itemIds: [id],
        userId: user.id,
        itemQuantities: itemQuantities,
      );

      if (result.isSuccess) {
        setState(() {
          confirmedArticles.add(itemId);
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
              _updateAchatStatusFromItems(a);
            }
          }
          for (var a in _filteredAchats) {
            final idx =
                a.items?.indexWhere((i) => i.id?.toString() == itemId) ?? -1;
            if (idx != -1) {
              a.items![idx] = updated;
              a.items![idx].status = Status.RECEIVED;
              _updateAchatStatusFromItems(a);
            }
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
    } catch (e) {
      showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('purchase_history_error_during_confirmation'));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _updateAchatStatusFromItems(Achat achat) {
    final total = _getTotalInvoicesCount(achat);
    final delivered = _getDeliveredItemsCount(achat);
    if (total > 0 && delivered >= total) {
      achat.status = Status.COMPLETED;
    } else {
      // S'il reste des factures non livrées, on considère l'achat comme en attente
      if (achat.status == Status.COMPLETED) {
        achat.status = Status.PENDING;
      }
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
        for (var a in _filteredAchats) {
          final idx = a.items?.indexWhere((i) => i.id == updated.id) ?? -1;
          if (idx != -1) {
            a.items![idx] = updated;
            break;
          }
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
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  AppLocalizations.of(context)
                      .translate('purchase_history_reverse_confirm_title'),
                  style: AppTextSize.headlineStyle(context,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(AppLocalizations.of(context)
            .translate('purchase_history_reverse_confirm_message')
            .replaceAll('{description}', item.description ?? '')),
        backgroundColor: Colors.white,
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
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _reverseItem(Items item, Achat achat) async {
    setState(() {
      isLoading = true;
    });
    try {
      final user = await AuthService().getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('user_not_connected'));
        setState(() {
          isLoading = false;
        });
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
          // Mettre à jour le statut de l'item reversé et recalculer le statut de l'achat
          for (var a in _achats) {
            final itemIndex = a.items?.indexWhere((i) => i.id == item.id) ?? -1;
            if (itemIndex != -1) {
              a.items![itemIndex].status = Status.PENDING;
              _updateAchatStatusFromItems(a);
            }
          }
          for (var a in _filteredAchats) {
            final itemIndex = a.items?.indexWhere((i) => i.id == item.id) ?? -1;
            if (itemIndex != -1) {
              a.items![itemIndex].status = Status.PENDING;
              _updateAchatStatusFromItems(a);
            }
          }
        });
        showSuccessTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_item_reversed_success'));
      } else if (result == "ITEM_NOT_FOUND") {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_item_not_found'));
      } else if (result == "CLIENT_NOT_FOUND_OR_MISMATCH") {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_client_mismatch'));
      } else if (result == "USER_NOT_FOUND") {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_user_not_found'));
      } else {
        showErrorTopSnackBar(
            context,
            result?.toString() ??
                AppLocalizations.of(context)
                    .translate('purchase_history_unknown_error'));
      }
    } catch (e) {
      showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('purchase_history_error_during_reverse')
              .replaceAll('{error}', e.toString()));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleDeleteItem(Items item, Achat achat) async {
    // 1. Demander confirmation à l'utilisateur
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title:
            Text(AppLocalizations.of(context).translate('delete_item_title')),
        content: Text(
            AppLocalizations.of(context).translate('delete_item_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).translate('delete')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 2. Appel au service (Assurez-vous d'avoir accès au currentUserId)
      final itemServices = ItemServices();
      final authService = AuthService();
      final user = await authService.getUserInfo();
      // Note : Remplacez 'currentUserId' par votre variable réelle (ex: authProvider.user.id)
      final result = await itemServices.deleteItem(
        itemId: item.id!,
        userId: user!.id,
      );

      if (result.isSuccess) {
        Navigator.of(context).pop(true);
        // 3. Mise à jour de l'UI
        setState(() {
          achat.items?.removeWhere((i) => i.id == item.id);
        });

        showSuccessTopSnackBar(
          context,
          AppLocalizations.of(context).translate('delete_item_success'),
        );
      } else {
        showErrorTopSnackBar(
          context,
          result.errorMessage ??
              AppLocalizations.of(context).translate('delete_item_error'),
        );
      }
    } catch (e) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('delete_item_error'),
      );
    }
  }

  Widget _buildItemsListView() {
    // Extraire tous les items de tous les achats filtrés
    final allItems = <Map<String, dynamic>>[];

    for (var achat in _filteredAchats) {
      if (achat.items != null) {
        for (var item in achat.items!) {
          allItems.add({
            'item': item,
            'achat': achat,
          });
        }
      }
    }

    if (allItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)
                  .translate('purchase_history_no_items'),
              style: AppTextSize.headlineStyle(
                context,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _chargerAchats,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: allItems.length,
        itemBuilder: (context, index) {
          final itemData = allItems[index];
          final item = itemData['item'];
          final achat = itemData['achat'] as Achat;

          final user = AuthService.currentUser;
          final access = AccessControlService();
          final canEdit = access.canEditItem(user);
          final canDelete = access.canDeleteItem(user);
          final itemSlidableActions = <Widget>[
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
          return ReusableItemCard(
            item: item,
            achat: achat,
            actions: itemSlidableActions,
            showSupplierInfo: true,
            showPurchaseInfo: true,
            showReceptionInfo: true,
            isLoading: isLoading,
            onConfirm: (item, achat) async {
              final data = await _showConfirmDeliveryDialog(item);
              if (data != null && mounted) {
                await confirmArticle(item.id!.toString(), item, achat!,
                    carton: data.carton,
                    quantityPerCarton: data.quantityPerCarton,
                    quantity: data.quantity);
              }
            },
          );
        },
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
