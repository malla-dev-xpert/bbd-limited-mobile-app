import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/components/reusable_item_card.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/widgets/filters/filter_button.dart';
import 'package:bbd_limited/widgets/filters/filter_sheet.dart';

/// Full-page screen to select and embark items into a container.
/// Reuses the same UI design as the item selection step during container creation.
class EmbarkItemsPage extends StatefulWidget {
  final int containerId;

  const EmbarkItemsPage({
    super.key,
    required this.containerId,
  });

  @override
  State<EmbarkItemsPage> createState() => _EmbarkItemsPageState();
}

class _EmbarkItemsPageState extends State<EmbarkItemsPage> {
  final ContainerServices _containerServices = ContainerServices();
  final ItemServices _itemServices = ItemServices();
  final AuthService _authService = AuthService();

  List<Items> _availableItems = [];
  final Set<int> _selectedItemIds = {};
  bool _isLoadingItems = true;
  bool _isSubmitting = false;

  /// Filtres (même modèle que historique_achats_screen)
  String? _selectedClientName;
  String? _selectedSupplierName;
  String? _selectedInvoiceNumber;

  List<String> _getUniqueClientNames() {
    final set = <String>{};
    for (final item in _availableItems) {
      if (item.clientName != null && item.clientName!.isNotEmpty) {
        set.add(item.clientName!);
      }
    }
    return set.toList()..sort();
  }

  List<String> _getUniqueSupplierNames() {
    final set = <String>{};
    for (final item in _availableItems) {
      if (item.supplierName != null && item.supplierName!.isNotEmpty) {
        set.add(item.supplierName!);
      }
    }
    return set.toList()..sort();
  }

  List<String> _getUniqueInvoiceNumbers() {
    final set = <String>{};
    for (final item in _availableItems) {
      if (item.invoiceNumber != null && item.invoiceNumber!.isNotEmpty) {
        set.add(item.invoiceNumber!);
      }
    }
    return set.toList()..sort();
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
    });
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
    });
  }

  Future<void> _openInvoiceFilter() async {
    final numbers = _getUniqueInvoiceNumbers();
    final options =
        numbers.map((n) => FilterOption<String>(value: n, label: n)).toList();
    final loc = AppLocalizations.of(context);
    final selected = await FilterSheet.show<String>(
      context: context,
      title: loc.translate('invoice_number'),
      searchHint: loc.translate('search_supplier_placeholder'),
      options: options,
      initialValue: _selectedInvoiceNumber,
      showAllOption: true,
      allOptionLabel: loc.translate('container_all'),
      noResultsLabel: loc.translate('no_results'),
    );
    setState(() {
      _selectedInvoiceNumber = selected;
    });
  }

  List<Items> get _filteredItems {
    if (_selectedClientName == null &&
        _selectedSupplierName == null &&
        _selectedInvoiceNumber == null) {
      return _availableItems;
    }
    return _availableItems.where((item) {
      final clientMatch = _selectedClientName == null ||
          item.clientName == _selectedClientName;
      final supplierMatch = _selectedSupplierName == null ||
          item.supplierName == _selectedSupplierName;
      final invoiceMatch = _selectedInvoiceNumber == null ||
          item.invoiceNumber == _selectedInvoiceNumber;
      return clientMatch && supplierMatch && invoiceMatch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAvailableItems();
  }

  Future<void> _loadAvailableItems() async {
    setState(() => _isLoadingItems = true);
    try {
      final list = await _itemServices.findAllNotInContainer();
      setState(() {
        _availableItems = list;
        _isLoadingItems = false;
      });
    } catch (_) {
      setState(() => _isLoadingItems = false);
    }
  }

  Future<void> _embarkItems() async {
    if (_selectedItemIds.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final user = await _authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('user_not_connected'),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final itemIds = _selectedItemIds.toList();
      final result = await _containerServices.addItemsToContainer(
        widget.containerId,
        itemIds,
        userId: user.id.toInt(),
      );

      if (result.isSuccess) {
        showSuccessTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('container_items_embarked_success'),
        );
        if (mounted) Navigator.of(context).pop(true);
      } else {
        showErrorTopSnackBar(
          context,
          result.errorMessage ??
              AppLocalizations.of(context).translate('container_embark_error'),
        );
      }
    } catch (e) {
      showErrorTopSnackBar(
        context,
        '${AppLocalizations.of(context).translate('error')}: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStepCard({required Widget child}) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildItemSelectionCard({
    required Items item,
    required AppLocalizations loc,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ReusableItemCard(
      item: item,
      onTap: onTap,
      isSelected: isSelected,
      showPurchaseInfo: true,
      extraDetails: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          loc.translate('container_embark_items'),
          style: AppTextSize.headlineStyle(context, color: Colors.white, fontWeight: FontWeight.w600).copyWith(letterSpacing: 0.5),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterButton(
                    label:
                        '${loc.translate('filter_label_client')} · ${_selectedClientName ?? loc.translate('container_all')}',
                    isActive: _selectedClientName != null,
                    icon: Icons.person_outline,
                    onTap: _openClientFilter,
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
                        '${loc.translate('invoice_number')} · ${_selectedInvoiceNumber ?? loc.translate('container_all')}',
                    isActive: _selectedInvoiceNumber != null,
                    icon: Icons.receipt_long_outlined,
                    onTap: _openInvoiceFilter,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    loc.translate('container_items_step_title'),
                    style: AppTextSize.titleStyle(context, color: const Color(0xFF1A1E49)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.translate('container_items_step_subtitle'),
                    style: AppTextSize.bodyStyle(context, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingItems)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_filteredItems.isEmpty)
                    _buildStepCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _availableItems.isEmpty
                                    ? loc.translate('container_no_items_available')
                                    : loc.translate('sales_no_items_found'),
                                style: AppTextSize.bodyStyle(context, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._filteredItems.map(
                      (item) => _buildItemSelectionCard(
                        item: item,
                        loc: loc,
                        isSelected: item.id != null &&
                            _selectedItemIds.contains(item.id),
                        onTap: () {
                          setState(() {
                            if (item.id == null) return;
                            if (_selectedItemIds.contains(item.id)) {
                              _selectedItemIds.remove(item.id);
                            } else {
                              _selectedItemIds.add(item.id!);
                            }
                          });
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
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
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_selectedItemIds.isEmpty || _isSubmitting)
                      ? null
                      : _embarkItems,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF1A1E49),
                    disabledBackgroundColor: Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_circle_outline,
                          color: Colors.white),
                  label: Text(
                    _isSubmitting
                        ? loc.translate('container_form_saving')
                        : loc.translate('container_embark_items_button'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
