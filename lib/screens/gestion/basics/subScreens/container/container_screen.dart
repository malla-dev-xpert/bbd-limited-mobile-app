import 'dart:async';

import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/core/services/access_control_service.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/container_detail_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/container_list_item.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/pages/create_container_page.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/pages/edit_container_page.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/widgets/filters/filter_button.dart';
import 'package:bbd_limited/widgets/filters/filter_sheet.dart';
import 'package:bbd_limited/widgets/filters/date_range_selector.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class ContainerScreen extends StatefulWidget {
  const ContainerScreen({super.key});

  @override
  State<ContainerScreen> createState() => _ContainerScreen();
}

class _ContainerScreen extends State<ContainerScreen> {
  final TextEditingController searchController = TextEditingController();
  final ContainerServices _containerServices = ContainerServices();
  final AuthService _authService = AuthService();
  final AccessControlService _accessControl = AccessControlService();

  List<Containers> _allContainers = [];
  List<Containers> _filteredContainers = [];
  Status? _selectedStatus;
  int? _selectedSupplierId;
  DateTime? _filterDateStart;
  DateTime? _filterDateEnd;

  bool _isLoading = false;
  bool _hasMoreData = true;
  int currentPage = 0;
  bool _containerReadOnly = false;

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
    _loadUserAndCheckRestriction();
    fetchContainers();
    searchController.addListener(_applyFilters);
    _refreshController.stream.listen((_) {
      fetchContainers(reset: true);
    });
  }

  Future<void> _loadUserAndCheckRestriction() async {
    final user = await _authService.getUserInfo();
    if (mounted) {
      setState(() {
        _containerReadOnly = user != null && _accessControl.isRestrictedBranch(user);
      });
    }
  }

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();
    setState(() {
      _filteredContainers = _allContainers.where((container) {
        final ref = (container.reference ?? '').toLowerCase();
        final num = (container.containerNumber ?? '').toLowerCase();
        final matchesSearch = ref.contains(query) || num.contains(query);
        final matchesStatus = _selectedStatus == null ||
            (container.status != null && container.status == _selectedStatus);
        final matchesSupplier = _selectedSupplierId == null ||
            container.supplier_id == _selectedSupplierId;
        final matchesDate = _matchesDateRange(container);
        return matchesSearch &&
            matchesStatus &&
            matchesSupplier &&
            matchesDate;
      }).toList();
    });
  }

  bool _matchesDateRange(Containers container) {
    if (_filterDateStart == null && _filterDateEnd == null) return true;
    final date = container.createdAt ?? container.departureDate;
    if (date == null) return false;
    if (_filterDateStart != null && date.isBefore(_filterDateStart!)) {
      return false;
    }
    if (_filterDateEnd != null) {
      final endOfDay = DateTime(
        _filterDateEnd!.year,
        _filterDateEnd!.month,
        _filterDateEnd!.day,
        23,
        59,
        59,
      );
      return !date.isAfter(endOfDay);
    }
    return true;
  }

  List<FilterOption<int>> _getSupplierOptions() {
    final seen = <int>{};
    final list = <FilterOption<int>>[];
    for (final c in _allContainers) {
      if (c.supplier_id != null &&
          c.supplier_id! > 0 &&
          seen.add(c.supplier_id!)) {
        list.add(FilterOption<int>(
          value: c.supplier_id,
          label: c.supplierName?.trim().isNotEmpty == true
              ? c.supplierName!
              : '${c.supplier_id}',
        ));
      }
    }
    list.sort((a, b) => (a.label).compareTo(b.label));
    return list;
  }

  Future<void> _openProviderFilter() async {
    final options = _getSupplierOptions();
    final loc = AppLocalizations.of(context)!;
    final selected = await FilterSheet.show<int>(
      context: context,
      title: loc.translate('filter_by_supplier'),
      searchHint: loc.translate('search_supplier_placeholder'),
      options: options,
      initialValue: _selectedSupplierId,
      showAllOption: true,
      allOptionLabel: loc.translate('container_all'),
      noResultsLabel: loc.translate('no_results'),
    );
    setState(() {
      _selectedSupplierId = selected;
      _applyFilters();
    });
  }

  void _openDateRangeFilter() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
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
              onChanged: (result) {
                setState(() {
                  _filterDateStart = result.start;
                  _filterDateEnd = result.end;
                });
                _applyFilters();
              },
              onApply: () => Navigator.of(ctx).pop(),
              onReset: () {
                setState(() {
                  _filterDateStart = null;
                  _filterDateEnd = null;
                  _applyFilters();
                });
                Navigator.of(ctx).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshController.close();
    searchController.removeListener(_applyFilters);
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchContainers({bool reset = false}) async {
    if (_isLoading || (!reset && !_hasMoreData)) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        currentPage = 0;
        _hasMoreData = true;
        _allContainers = [];
      }
    });
    try {
      final containers = await _containerServices.findAll(page: currentPage);

      setState(() {
        _allContainers.addAll(containers);
        _applyFilters();
        if (containers.isEmpty || containers.length < 30) {
          _hasMoreData = false;
        } else {
          currentPage++;
        }
      });
    } catch (e) {
      showErrorTopSnackBar(context,
          AppLocalizations.of(context)!.translate('error_loading_containers'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditContainerModal(
      BuildContext context, Containers container) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditContainerPage(
          container: container,
          onContainerUpdated: () => fetchContainers(reset: true),
        ),
      ),
    );

    if (result == true) {
      fetchContainers(reset: true);
    }
  }

  Future<void> _openCreateConatinerBottomSheet(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateContainerPage(),
      ),
    );

    if (result == true) {
      fetchContainers(reset: true);
    }
  }

  Future<void> _delete(Containers container) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!
            .translate('container_delete_confirm')),
        content: Text(
          AppLocalizations.of(context)!
              .translate('container_delete_message')
              .replaceAll(
                  '{reference}',
                  (container.containerNumber?.trim().isNotEmpty == true
                          ? '${container.containerNumber} · ${container.reference ?? ''}'
                          : container.reference) ??
                      ''),
        ),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete, color: Colors.red),
            label: Text(
              _isLoading
                  ? AppLocalizations.of(context)!
                      .translate('container_deleting')
                  : AppLocalizations.of(context)!.translate('delete'),
              style: TextStyle(
                  color: Colors.red, fontSize: AppTextSize.body(context)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = await _authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context, "Erreur: Utilisateur non connecté");
        return;
      }

      final result = await _containerServices.delete(
        container.id!,
        user.id.toInt(),
      );

      if (result == "DELETED") {
        setState(() {
          _allContainers.removeWhere((d) => d.id == container.id);
          _applyFilters();
        });

        showSuccessTopSnackBar(context,
            AppLocalizations.of(context)!.translate('container_deleted'));
      } else if (result == "CONTAINER_NOT_FOUND") {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context)!.translate('container_not_found'));
      } else if (result == "PACKAGE_EXIST") {
        showErrorTopSnackBar(
          context,
          "Impossible de supprimer : Des colis existent dans ce conteneur.",
        );
      }
    } catch (e) {
      showErrorTopSnackBar(context,
          AppLocalizations.of(context)!.translate('container_delete_error'));
    }
  }

  String _getSupplierFilterLabel() {
    if (_selectedSupplierId == null)
      return AppLocalizations.of(context)!.translate('container_all');
    try {
      final c = _allContainers.firstWhere(
        (x) => x.supplier_id == _selectedSupplierId,
      );
      return c.supplierName?.trim().isNotEmpty == true
          ? c.supplierName!
          : '${_selectedSupplierId}';
    } catch (_) {
      return '${_selectedSupplierId}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final primaryColor = const Color(0xFF1A1E49);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          loc.translate('container_management'),
          style: AppTextSize.titleStyle(context, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: _containerReadOnly
          ? null
          : FloatingActionButton(
              onPressed: () => _openCreateConatinerBottomSheet(context),
              backgroundColor: primaryColor,
              heroTag: 'container_fab',
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: Padding(
        padding: AppSpacing.screen(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = DeviceBreakpoints.isTablet(context);
                if (isTablet) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: buildTextField(
                          controller: searchController,
                          label: loc.translate('container_search'),
                          icon: Icons.search,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      FilterButton(
                        label: _getSupplierFilterLabel(),
                        isActive: _selectedSupplierId != null,
                        icon: Icons.person_3_outlined,
                        onTap: _openProviderFilter,
                      ),
                      FilterButton(
                        label: _filterDateStart != null || _filterDateEnd != null
                            ? '${_formatDate(_filterDateStart)} - ${_formatDate(_filterDateEnd)}'
                            : loc.translate('filter_by_date'),
                        isActive: _filterDateStart != null || _filterDateEnd != null,
                        icon: Icons.calendar_month,
                        onTap: _openDateRangeFilter,
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildTextField(
                      controller: searchController,
                      label: loc.translate('container_search'),
                      icon: Icons.search,
                    ),
                    SizedBox(height: AppSpacing.md),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterButton(
                            label: _getSupplierFilterLabel(),
                            isActive: _selectedSupplierId != null,
                            icon: Icons.person_3_outlined,
                            onTap: _openProviderFilter,
                          ),
                          FilterButton(
                            label: _filterDateStart != null || _filterDateEnd != null
                                ? '${_formatDate(_filterDateStart)} - ${_formatDate(_filterDateEnd)}'
                                : loc.translate('filter_by_date'),
                            isActive: _filterDateStart != null || _filterDateEnd != null,
                            icon: Icons.calendar_month,
                            onTap: _openDateRangeFilter,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              loc.translate('container_packages_list'),
              style: AppTextSize.titleStyle(context),
            ),
            SizedBox(height: AppSpacing.sm),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo.metrics.pixels ==
                                scrollInfo.metrics.maxScrollExtent &&
                            !_isLoading &&
                            _hasMoreData) {
                          fetchContainers();
                        }
                        return false;
                      },
                      child: _filteredContainers.isEmpty
                          ? Center(
                              child: Text(
                                loc.translate('no_container_found'),
                                style: AppTextSize.bodyStyle(context),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                await fetchContainers(reset: true);
                              },
                              displacement: AppSpacing.xxxl,
                              color: Theme.of(context).primaryColor,
                              backgroundColor: Colors.white,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _filteredContainers.length +
                                    (_hasMoreData && _isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _filteredContainers.length) {
                                    return Center(
                                      child: Padding(
                                        padding: AppSpacing.paddingSm,
                                        child: const CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final container =
                                      _filteredContainers[index];

                                  return ContainerListItem(
                                    container: container,
                                    readOnly: _containerReadOnly,
                                    onTap: () async {
                                      final updatedContainer =
                                          await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ContainerDetailPage(
                                            container: container,
                                            readOnly: _containerReadOnly,
                                            onContainerUpdated: (updated) {
                                              setState(() {
                                                final idx = _filteredContainers
                                                    .indexWhere((c) =>
                                                        c.id == updated.id);
                                                if (idx != -1) {
                                                  _filteredContainers[idx] =
                                                      updated;
                                                }
                                                final allIdx = _allContainers
                                                    .indexWhere((c) =>
                                                        c.id == updated.id);
                                                if (allIdx != -1) {
                                                  _allContainers[allIdx] =
                                                      updated;
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      );
                                      if (updatedContainer != null) {
                                        setState(() {
                                          final idx = _filteredContainers
                                              .indexWhere((c) =>
                                                  c.id == updatedContainer.id);
                                          if (idx != -1) {
                                            _filteredContainers[idx] =
                                                updatedContainer;
                                          }
                                          final allIdx = _allContainers
                                              .indexWhere((c) =>
                                                  c.id == updatedContainer.id);
                                          if (allIdx != -1) {
                                            _allContainers[allIdx] =
                                                updatedContainer;
                                          }
                                        });
                                      }
                                    },
                                    onEdit: () => _showEditContainerModal(
                                        context, container),
                                    onDelete: () => _delete(container),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
