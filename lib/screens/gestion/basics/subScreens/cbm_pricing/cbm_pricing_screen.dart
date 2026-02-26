import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbd_limited/models/cbm_pricing.dart';
import 'package:bbd_limited/providers/cbm_pricing_provider.dart';
import 'package:bbd_limited/widgets/cbm_pricing/cbm_pricing_form.dart';
import 'package:bbd_limited/widgets/cbm_pricing/cbm_pricing_list_item.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';

class CbmPricingScreen extends ConsumerStatefulWidget {
  const CbmPricingScreen({super.key});

  @override
  ConsumerState<CbmPricingScreen> createState() => _CbmPricingScreenState();
}

class _CbmPricingScreenState extends ConsumerState<CbmPricingScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref
        .read(cbmPricingListProvider.notifier)
        .filterPricing(_searchController.text);
  }

  Future<void> _showAddModal() async {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('add_cbm_pricing'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1E49),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CbmPricingForm(
                isLoading: _isLoading,
                isEditing: false,
                onSubmit: (cbmValue, price, currency) async {
                  setState(() => _isLoading = true);
                  final pricing = CbmPricing(
                    cbmValue: cbmValue,
                    price: price,
                    currency: currency,
                  );
                  final result = await ref
                      .read(cbmPricingListProvider.notifier)
                      .createPricing(pricing);

                  if (result == "SUCCESS") {
                    Navigator.pop(context);
                    showSuccessTopSnackBar(
                        context,
                        AppLocalizations.of(context)
                            .translate('cbm_pricing_created_success'));
                  } else {
                    showErrorTopSnackBar(context, result ?? 'Error');
                  }
                  setState(() => _isLoading = false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditModal(CbmPricing pricing) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context).translate('edit_cbm_pricing')),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ],
          ),
          content: CbmPricingForm(
            cbmPricing: pricing,
            isLoading: _isLoading,
            isEditing: true,
            onSubmit: (cbmValue, price, currency) async {
              setState(() => _isLoading = true);
              final updated = pricing.copyWith(
                cbmValue: cbmValue,
                price: price,
                currency: currency,
              );
              final success = await ref
                  .read(cbmPricingListProvider.notifier)
                  .updatePricing(pricing.id!, updated);

              if (success) {
                Navigator.pop(context);
                showSuccessTopSnackBar(
                    context,
                    AppLocalizations.of(context)
                        .translate('cbm_pricing_updated_success'));
              } else {
                showErrorTopSnackBar(context, 'Update error');
              }
              setState(() => _isLoading = false);
            },
          ),
        );
      },
    );
  }

  Future<void> _deletePricing(CbmPricing pricing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context).translate('confirm_delete')),
        content:
            Text(AppLocalizations.of(context).translate('confirm_delete_cbm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).translate('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).translate('delete'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(cbmPricingListProvider.notifier)
          .deletePricing(pricing.id!);
      if (success) {
        showSuccessTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('cbm_pricing_deleted_success'));
      } else {
        showErrorTopSnackBar(context, 'Delete error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cbmPricingListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('cbm_pricing_management'),
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1E49),
        onPressed: _showAddModal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            buildTextField(
              controller: _searchController,
              label: AppLocalizations.of(context).translate('search_cbm'),
              icon: Icons.search,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: state.when(
                data: (pricings) {
                  if (pricings.isEmpty) {
                    return Center(
                        child: Text(AppLocalizations.of(context)
                            .translate('no_cbm_pricing_found')));
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(cbmPricingListProvider.notifier)
                        .loadPricing(reset: true),
                    child: ListView.builder(
                      itemCount: pricings.length,
                      itemBuilder: (context, index) {
                        final pricing = pricings[index];
                        return CbmPricingListItem(
                          cbmPricing: pricing,
                          onEdit: () => _showEditModal(pricing),
                          onDelete: () => _deletePricing(pricing),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text(error.toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
