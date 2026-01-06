import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbd_limited/core/services/statistics_service.dart';

enum ReportPeriod {
  currentWeek,
  currentMonth,
  currentYear,
}

extension ReportPeriodExtension on ReportPeriod {
  String getDisplayName() {
    switch (this) {
      case ReportPeriod.currentWeek:
        return 'Semaine courante';
      case ReportPeriod.currentMonth:
        return 'Mois en cours';
      case ReportPeriod.currentYear:
        return 'Année en cours';
    }
  }

  /// Retourne la plage de dates correspondante
  DateRange getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case ReportPeriod.currentWeek:
        // Semaine du lundi au dimanche
        final weekday = now.weekday;
        final monday = today.subtract(Duration(days: weekday - 1));
        final nextMonday = monday.add(const Duration(days: 7));
        return DateRange(startDate: monday, endDate: nextMonday);
      case ReportPeriod.currentMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateRange(startDate: startOfMonth, endDate: endOfMonth);
      case ReportPeriod.currentYear:
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
        return DateRange(startDate: startOfYear, endDate: endOfYear);
    }
  }
}

class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange({required this.startDate, required this.endDate});
}

class ReportStatistics {
  final List<ProductStat> topProducts;
  final List<CustomerStat> topCustomers;
  final List<SupplierStat> topSuppliers;
  final List<ShippingHarborStat> shippingHarbors;
  final List<ReceivingHarborStat> receivingHarbors;
  final bool isLoading;
  final String? error;

  ReportStatistics({
    required this.topProducts,
    required this.topCustomers,
    required this.topSuppliers,
    required this.shippingHarbors,
    required this.receivingHarbors,
    this.isLoading = false,
    this.error,
  });

  ReportStatistics copyWith({
    List<ProductStat>? topProducts,
    List<CustomerStat>? topCustomers,
    List<SupplierStat>? topSuppliers,
    List<ShippingHarborStat>? shippingHarbors,
    List<ReceivingHarborStat>? receivingHarbors,
    bool? isLoading,
    String? error,
  }) {
    return ReportStatistics(
      topProducts: topProducts ?? this.topProducts,
      topCustomers: topCustomers ?? this.topCustomers,
      topSuppliers: topSuppliers ?? this.topSuppliers,
      shippingHarbors: shippingHarbors ?? this.shippingHarbors,
      receivingHarbors: receivingHarbors ?? this.receivingHarbors,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ProductStat {
  final String description;
  final int frequency;
  final double totalQuantity;
  final double totalValue;

  ProductStat({
    required this.description,
    required this.frequency,
    required this.totalQuantity,
    required this.totalValue,
  });
}

class CustomerStat {
  final String customerName;
  final int purchaseCount;
  final double totalSpent;

  CustomerStat({
    required this.customerName,
    required this.purchaseCount,
    required this.totalSpent,
  });
}

class SupplierStat {
  final String supplierName;
  final int itemCount;
  final int containerCount;
  final double totalValue;

  SupplierStat({
    required this.supplierName,
    required this.itemCount,
    required this.containerCount,
    required this.totalValue,
  });
}

class HarborStat {
  final String harborName;
  final int packageCount;
  final int containerCount;

  HarborStat({
    required this.harborName,
    required this.packageCount,
    required this.containerCount,
  });
}

/// Statistiques des ports d'envoi
class ShippingHarborStat {
  final String harborName;
  final int packageCount;

  ShippingHarborStat({
    required this.harborName,
    required this.packageCount,
  });
}

/// Statistiques des ports de réception
class ReceivingHarborStat {
  final String harborName;
  final int packageCount;

  ReceivingHarborStat({
    required this.harborName,
    required this.packageCount,
  });
}

class ReportsNotifier extends StateNotifier<ReportStatistics> {
  ReportsNotifier()
      : super(ReportStatistics(
          topProducts: [],
          topCustomers: [],
          topSuppliers: [],
          shippingHarbors: [],
          receivingHarbors: [],
        ));

  final StatisticsService _statisticsService = StatisticsService();

  Future<void> loadReports(ReportPeriod period) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Charger toutes les statistiques depuis les APIs backend
      final mostActiveClients =
          await _statisticsService.getMostActiveClients(limit: 10);
      final mostSolicitedSuppliers =
          await _statisticsService.getMostSolicitedSuppliers(limit: 10);
      final mostPurchasedItems =
          await _statisticsService.getMostPurchasedItems(limit: 10);
      final shippingHarbors =
          await _statisticsService.getMostUsedHarborsForShipping(limit: 10);
      final receivingHarbors =
          await _statisticsService.getMostUsedHarborsForReceiving(limit: 10);

      // Mapper les données des APIs vers les modèles internes
      final topProducts = mostPurchasedItems
          .map((item) => ProductStat(
                description: item.itemDescription,
                frequency: item.totalPurchases,
                totalQuantity: item.totalQuantity.toDouble(),
                totalValue: item.totalAmount,
              ))
          .toList();

      final topCustomers = mostActiveClients
          .map((client) => CustomerStat(
                customerName: client.clientName,
                purchaseCount: client.totalOperations,
                totalSpent: 0.0, // Non disponible depuis l'API
              ))
          .toList();

      final topSuppliers = mostSolicitedSuppliers
          .map((supplier) => SupplierStat(
                supplierName: supplier.supplierName,
                itemCount: supplier.itemsCount,
                containerCount: supplier.containersCount,
                totalValue: 0.0, // Non disponible depuis l'API
              ))
          .toList();

      final shippingHarborsList = shippingHarbors
          .map((harbor) => ShippingHarborStat(
                harborName: harbor.harborName,
                packageCount: harbor.totalPackages,
              ))
          .toList();

      final receivingHarborsList = receivingHarbors
          .map((harbor) => ReceivingHarborStat(
                harborName: harbor.harborName,
                packageCount: harbor.totalPackages,
              ))
          .toList();

      state = state.copyWith(
        topProducts: topProducts,
        topCustomers: topCustomers,
        topSuppliers: topSuppliers,
        shippingHarbors: shippingHarborsList,
        receivingHarbors: receivingHarborsList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final reportsProvider =
    StateNotifierProvider<ReportsNotifier, ReportStatistics>((ref) {
  return ReportsNotifier();
});

final selectedPeriodProvider = StateProvider<ReportPeriod>((ref) {
  return ReportPeriod.currentWeek;
});
