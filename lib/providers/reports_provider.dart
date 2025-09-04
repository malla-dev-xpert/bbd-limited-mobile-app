import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/harbor_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/harbor.dart';
import 'package:bbd_limited/core/enums/status.dart';

enum ReportPeriod {
  currentMonth,
  lastThreeMonths,
  currentYear,
  customRange,
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
  final List<HarborStat> topHarbors;
  final bool isLoading;
  final String? error;

  ReportStatistics({
    required this.topProducts,
    required this.topCustomers,
    required this.topSuppliers,
    required this.topHarbors,
    this.isLoading = false,
    this.error,
  });

  ReportStatistics copyWith({
    List<ProductStat>? topProducts,
    List<CustomerStat>? topCustomers,
    List<SupplierStat>? topSuppliers,
    List<HarborStat>? topHarbors,
    bool? isLoading,
    String? error,
  }) {
    return ReportStatistics(
      topProducts: topProducts ?? this.topProducts,
      topCustomers: topCustomers ?? this.topCustomers,
      topSuppliers: topSuppliers ?? this.topSuppliers,
      topHarbors: topHarbors ?? this.topHarbors,
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

class ReportsNotifier extends StateNotifier<ReportStatistics> {
  ReportsNotifier()
      : super(ReportStatistics(
          topProducts: [],
          topCustomers: [],
          topSuppliers: [],
          topHarbors: [],
        ));

  final AchatServices _achatServices = AchatServices();
  final PartnerServices _partnerServices = PartnerServices();
  final PackageServices _packageServices = PackageServices();
  final ContainerServices _containerServices = ContainerServices();
  final HarborServices _harborServices = HarborServices();

  Future<void> loadReports(ReportPeriod period,
      {DateRange? customRange}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Charger toutes les données
      final achats = await _achatServices.findAll();
      final customers = await _partnerServices.findCustomers();
      final suppliers = await _partnerServices.findSuppliers();
      final packages = await _packageServices.findAll();
      final containers = await _containerServices.findAll();
      final harbors = await _harborServices.findAll();

      // Filtrer par période
      final filteredAchats =
          _filterByPeriod(achats, period, customRange: customRange);
      final filteredPackages =
          _filterByPeriod(packages, period, customRange: customRange);
      final filteredContainers =
          _filterByPeriod(containers, period, customRange: customRange);

      // Calculer les statistiques
      final topProducts = _calculateTopProducts(filteredAchats);
      final topCustomers = _calculateTopCustomers(filteredAchats, customers);
      final topSuppliers =
          _calculateTopSuppliers(filteredAchats, filteredContainers, suppliers);
      final topHarbors = _calculateTopHarbors(filteredPackages, harbors);

      state = state.copyWith(
        topProducts: topProducts,
        topCustomers: topCustomers,
        topSuppliers: topSuppliers,
        topHarbors: topHarbors,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  List<T> _filterByPeriod<T>(List<T> items, ReportPeriod period,
      {DateRange? customRange}) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (period) {
      case ReportPeriod.currentMonth:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case ReportPeriod.lastThreeMonths:
        startDate = DateTime(now.year, now.month - 3, 1);
        break;
      case ReportPeriod.currentYear:
        startDate = DateTime(now.year, 1, 1);
        break;
      case ReportPeriod.customRange:
        if (customRange != null) {
          startDate = customRange.startDate;
          endDate = customRange.endDate;
        } else {
          startDate = DateTime(now.year, now.month, 1);
        }
        break;
    }

    return items.where((item) {
      DateTime? itemDate;

      if (item is Achat) {
        itemDate = item.createdAt;
      } else if (item is Packages) {
        itemDate = item.startDate;
      } else if (item is Containers) {
        itemDate = item.createdAt;
      }

      return itemDate != null &&
          itemDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          itemDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  List<ProductStat> _calculateTopProducts(List<Achat> achats) {
    final Map<String, ProductStat> productStats = {};

    for (final achat in achats) {
      // Filtrer uniquement les achats avec le statut RECEIVED
      if (achat.status != Status.RECEIVED) {
        continue;
      }

      if (achat.items != null) {
        for (final item in achat.items!) {
          // Normaliser la description (ignorer la casse et les espaces)
          final rawDescription = item.description ?? 'Produit inconnu';
          final normalizedDescription = rawDescription.trim().toLowerCase();
          final quantity = item.quantity ?? 0;
          final totalPrice = item.totalPrice ?? 0.0;

          if (productStats.containsKey(normalizedDescription)) {
            final existing = productStats[normalizedDescription]!;
            productStats[normalizedDescription] = ProductStat(
              description: existing
                  .description, // Garder la première description rencontrée
              frequency: existing.frequency + 1,
              totalQuantity: existing.totalQuantity + quantity,
              totalValue: existing.totalValue + totalPrice,
            );
          } else {
            productStats[normalizedDescription] = ProductStat(
              description: rawDescription, // Utiliser la description originale
              frequency: 1,
              totalQuantity: quantity.toDouble(),
              totalValue: totalPrice,
            );
          }
        }
      }
    }

    // Calculer un score pondéré qui combine fréquence et quantité
    final productsWithScore = productStats.values.map((product) {
      // Score = (fréquence * 0.3) + (quantité * 0.7) - Priorité à la quantité
      // Pas de normalisation pour éviter les problèmes d'échelle
      final score = (product.frequency * 0.3) + (product.totalQuantity * 0.7);

      return {
        'product': product,
        'score': score,
      };
    }).toList();

    // Trier par score décroissant, puis par quantité décroissante en cas d'égalité
    productsWithScore.sort((a, b) {
      final scoreA = a['score'] as double;
      final scoreB = b['score'] as double;

      if ((scoreA - scoreB).abs() < 0.01) {
        // En cas d'égalité de score, trier par quantité décroissante
        final productA = a['product'] as ProductStat;
        final productB = b['product'] as ProductStat;
        return productB.totalQuantity.compareTo(productA.totalQuantity);
      }

      return scoreB.compareTo(scoreA);
    });

    return productsWithScore
        .take(5)
        .map((item) => item['product'] as ProductStat)
        .toList();
  }

  List<CustomerStat> _calculateTopCustomers(
      List<Achat> achats, List<Partner> customers) {
    final Map<int, CustomerStat> customerStats = {};

    for (final achat in achats) {
      final clientId = achat.clientId;
      final clientName = achat.client ?? 'Client inconnu';
      final montantTotal = achat.montantTotal ?? 0.0;

      if (clientId != null) {
        if (customerStats.containsKey(clientId)) {
          final existing = customerStats[clientId]!;
          customerStats[clientId] = CustomerStat(
            customerName: existing.customerName,
            purchaseCount: existing.purchaseCount + 1,
            totalSpent: existing.totalSpent + montantTotal,
          );
        } else {
          customerStats[clientId] = CustomerStat(
            customerName: clientName,
            purchaseCount: 1,
            totalSpent: montantTotal,
          );
        }
      }
    }

    // Calculer un score pondéré qui combine nombre d'achats et montant total
    final customersWithScore = customerStats.values.map((customer) {
      // Score = (nombre d'achats * 0.4) + (montant normalisé * 0.6)
      // Normaliser le montant par rapport au maximum pour équilibrer les échelles
      final maxAmount = customerStats.values
          .map((c) => c.totalSpent)
          .reduce((a, b) => a > b ? a : b);
      final normalizedAmount =
          maxAmount > 0 ? customer.totalSpent / maxAmount : 0;
      final score = (customer.purchaseCount * 0.4) + (normalizedAmount * 0.6);

      return {
        'customer': customer,
        'score': score,
      };
    }).toList();

    // Trier par score décroissant, puis par montant décroissant en cas d'égalité
    customersWithScore.sort((a, b) {
      final scoreA = a['score'] as double;
      final scoreB = b['score'] as double;

      if ((scoreA - scoreB).abs() < 0.01) {
        // En cas d'égalité de score, trier par montant décroissant
        final customerA = a['customer'] as CustomerStat;
        final customerB = b['customer'] as CustomerStat;
        return customerB.totalSpent.compareTo(customerA.totalSpent);
      }

      return scoreB.compareTo(scoreA);
    });

    return customersWithScore
        .take(5)
        .map((item) => item['customer'] as CustomerStat)
        .toList();
  }

  List<SupplierStat> _calculateTopSuppliers(
    List<Achat> achats,
    List<Containers> containers,
    List<Partner> suppliers,
  ) {
    final Map<int, SupplierStat> supplierStats = {};

    // Compter les items des achats
    for (final achat in achats) {
      if (achat.items != null) {
        for (final item in achat.items!) {
          final supplierId = item.supplierId;
          final supplierName = item.supplierName ?? 'Fournisseur inconnu';
          final totalPrice = item.totalPrice ?? 0.0;

          if (supplierId != null) {
            if (supplierStats.containsKey(supplierId)) {
              final existing = supplierStats[supplierId]!;
              supplierStats[supplierId] = SupplierStat(
                supplierName: existing.supplierName,
                itemCount: existing.itemCount + 1,
                containerCount: existing.containerCount,
                totalValue: existing.totalValue + totalPrice,
              );
            } else {
              supplierStats[supplierId] = SupplierStat(
                supplierName: supplierName,
                itemCount: 1,
                containerCount: 0,
                totalValue: totalPrice,
              );
            }
          }
        }
      }
    }

    // Compter les conteneurs
    for (final container in containers) {
      final supplierId = container.supplier_id;
      if (supplierId != null) {
        if (supplierStats.containsKey(supplierId)) {
          final existing = supplierStats[supplierId]!;
          supplierStats[supplierId] = SupplierStat(
            supplierName: existing.supplierName,
            itemCount: existing.itemCount,
            containerCount: existing.containerCount + 1,
            totalValue: existing.totalValue,
          );
        } else {
          final supplier = suppliers.firstWhere(
            (s) => s.id == supplierId,
            orElse: () => Partner(
              id: supplierId,
              firstName: 'Fournisseur',
              lastName: 'inconnu',
              phoneNumber: '',
              email: '',
              country: '',
              adresse: '',
              accountType: 'FOURNISSEUR',
            ),
          );
          supplierStats[supplierId] = SupplierStat(
            supplierName: '${supplier.firstName} ${supplier.lastName}',
            itemCount: 0,
            containerCount: 1,
            totalValue: 0.0,
          );
        }
      }
    }

    final sortedSuppliers = supplierStats.values.toList()
      ..sort((a, b) => (b.itemCount + b.containerCount)
          .compareTo(a.itemCount + a.containerCount));

    return sortedSuppliers.take(5).toList();
  }

  List<HarborStat> _calculateTopHarbors(
      List<Packages> packages, List<Harbor> harbors) {
    final Map<int, HarborStat> harborStats = {};

    // Compter les packages par port de départ et d'arrivée
    for (final package in packages) {
      final startHarborId = package.startHarborId;
      final destinationHarborId = package.destinationHarborId;

      if (startHarborId != null) {
        final harbor = harbors.firstWhere(
          (h) => h.id == startHarborId,
          orElse: () => Harbor(id: startHarborId, name: 'Port inconnu'),
        );

        if (harborStats.containsKey(startHarborId)) {
          final existing = harborStats[startHarborId]!;
          harborStats[startHarborId] = HarborStat(
            harborName: existing.harborName,
            packageCount: existing.packageCount + 1,
            containerCount: existing.containerCount,
          );
        } else {
          harborStats[startHarborId] = HarborStat(
            harborName: harbor.name ?? 'Port inconnu',
            packageCount: 1,
            containerCount: 0,
          );
        }
      }

      if (destinationHarborId != null && destinationHarborId != startHarborId) {
        final harbor = harbors.firstWhere(
          (h) => h.id == destinationHarborId,
          orElse: () => Harbor(id: destinationHarborId, name: 'Port inconnu'),
        );

        if (harborStats.containsKey(destinationHarborId)) {
          final existing = harborStats[destinationHarborId]!;
          harborStats[destinationHarborId] = HarborStat(
            harborName: existing.harborName,
            packageCount: existing.packageCount + 1,
            containerCount: existing.containerCount,
          );
        } else {
          harborStats[destinationHarborId] = HarborStat(
            harborName: harbor.name ?? 'Port inconnu',
            packageCount: 1,
            containerCount: 0,
          );
        }
      }
    }

    // Compter les conteneurs par port
    for (final harbor in harbors) {
      if (harbor.containers != null) {
        if (harborStats.containsKey(harbor.id)) {
          final existing = harborStats[harbor.id]!;
          harborStats[harbor.id] = HarborStat(
            harborName: existing.harborName,
            packageCount: existing.packageCount,
            containerCount: existing.containerCount + harbor.containers!.length,
          );
        } else {
          harborStats[harbor.id] = HarborStat(
            harborName: harbor.name ?? 'Port inconnu',
            packageCount: 0,
            containerCount: harbor.containers!.length,
          );
        }
      }
    }

    final sortedHarbors = harborStats.values.toList()
      ..sort((a, b) => (b.packageCount + b.containerCount)
          .compareTo(a.packageCount + a.containerCount));

    return sortedHarbors.take(5).toList();
  }
}

final reportsProvider =
    StateNotifierProvider<ReportsNotifier, ReportStatistics>((ref) {
  return ReportsNotifier();
});

final selectedPeriodProvider = StateProvider<ReportPeriod>((ref) {
  return ReportPeriod.currentMonth;
});

final customDateRangeProvider = StateProvider<DateRange?>((ref) {
  return null;
});
