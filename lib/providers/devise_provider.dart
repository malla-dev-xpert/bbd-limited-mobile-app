import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbd_limited/core/services/devises_service.dart';
import 'package:bbd_limited/models/devises.dart';

final deviseServiceProvider = Provider<DeviseServices>((ref) {
  return DeviseServices();
});

final deviseListProvider =
    StateNotifierProvider<DeviseListNotifier, AsyncValue<List<Devise>>>((ref) {
  return DeviseListNotifier();
});

class DeviseListNotifier extends StateNotifier<AsyncValue<List<Devise>>> {
  DeviseListNotifier() : super(const AsyncValue.loading()) {
    loadDevises();
  }

  final DeviseServices _deviseServices = DeviseServices();
  List<Devise> _allDevises = [];
  String _currentFilter = '';

  Future<void> loadDevises({bool reset = false}) async {
    if (reset) {
      _allDevises = [];
    }

    try {
      state = const AsyncValue.loading();
      final result = await _deviseServices.findAllDevises(page: 0);
      _allDevises = result;
      _applyFilter();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void filterDevises(String query) {
    _currentFilter = query.toLowerCase();
    _applyFilter();
  }

  void _applyFilter() {
    if (_currentFilter.isEmpty) {
      state = AsyncValue.data(_allDevises);
    } else {
      final filtered = _allDevises.where((devise) {
        final code = devise.code.toLowerCase();
        final name = devise.name.toLowerCase();
        return code.contains(_currentFilter) || name.contains(_currentFilter);
      }).toList();
      state = AsyncValue.data(filtered);
    }
  }

  Future<String> createDevise({
    required String name,
    required String code,
    double? rate,
    required int userId,
  }) async {
    try {
      final result = await _deviseServices.create(
        name: name,
        code: code,
        rate: rate,
        userId: userId,
      );
      if (result == "SUCCESS") {
        await loadDevises(reset: true);
      }
      return result;
    } catch (e) {
      return 'ERROR';
    }
  }

  Future<bool> updateDevise(int id, Devise devise) async {
    try {
      final result = await _deviseServices.updateDevise(id, devise);
      if (result) {
        await loadDevises(reset: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDevise(int id) async {
    try {
      await _deviseServices.deleteDevise(id);
      await loadDevises(reset: true);
      return true;
    } catch (e) {
      return false;
    }
  }
}
