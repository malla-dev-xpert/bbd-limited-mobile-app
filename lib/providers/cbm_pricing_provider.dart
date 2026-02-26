import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbd_limited/core/services/cbm_pricing_services.dart';
import 'package:bbd_limited/models/cbm_pricing.dart';

final cbmPricingServiceProvider = Provider<CbmPricingServices>((ref) {
  return CbmPricingServices();
});

final cbmPricingListProvider =
    StateNotifierProvider<CbmPricingListNotifier, AsyncValue<List<CbmPricing>>>(
        (ref) {
  return CbmPricingListNotifier(ref.watch(cbmPricingServiceProvider));
});

class CbmPricingListNotifier
    extends StateNotifier<AsyncValue<List<CbmPricing>>> {
  final CbmPricingServices _service;
  List<CbmPricing> _allPricing = [];
  String _currentFilter = '';

  CbmPricingListNotifier(this._service) : super(const AsyncValue.loading()) {
    loadPricing();
  }

  Future<void> loadPricing({bool reset = false}) async {
    if (reset) {
      state = const AsyncValue.loading();
    }

    try {
      final result = await _service.findAll(page: 0, size: 100);
      _allPricing = result;
      _applyFilter();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void filterPricing(String query) {
    _currentFilter = query.toLowerCase();
    _applyFilter();
  }

  void _applyFilter() {
    if (_currentFilter.isEmpty) {
      state = AsyncValue.data(_allPricing);
    } else {
      final filtered = _allPricing.where((item) {
        final cbmVal = item.cbmValue.toString().toLowerCase();
        final priceVal = item.price.toString().toLowerCase();
        return cbmVal.contains(_currentFilter) ||
            priceVal.contains(_currentFilter);
      }).toList();
      state = AsyncValue.data(filtered);
    }
  }

  Future<String?> createPricing(CbmPricing pricing) async {
    try {
      await _service.create(pricing);
      await loadPricing();
      return "SUCCESS";
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> updatePricing(int id, CbmPricing pricing) async {
    try {
      await _service.update(id, pricing);
      await loadPricing();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePricing(int id) async {
    try {
      await _service.delete(id);
      await loadPricing();
      return true;
    } catch (e) {
      return false;
    }
  }
}
