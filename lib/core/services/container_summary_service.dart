import 'package:bbd_limited/core/services/cbm_pricing_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/container_client_summary.dart';

/// Service pour générer des résumés agrégés des conteneurs.
class ContainerSummaryService {
  /// [container] Le conteneur dont on veut générer le résumé
  static List<ContainerClientSummary> generateSummary(Containers container) {
    final items = container.items;
    if (items == null || items.isEmpty) {
      return [];
    }

    // Grouper les items par client
    // Clé: nom du client, Valeur: liste des items de ce client
    final Map<String, List<dynamic>> groupedByClient = {};

    for (final item in items) {
      // Déterminer la clé du client
      String clientKey;
      if (item.clientName != null && item.clientName!.trim().isNotEmpty) {
        clientKey = item.clientName!.trim();
      } else if (item.clientId != null) {
        clientKey = 'Client #${item.clientId}';
      } else {
        clientKey = 'Client Inconnu';
      }

      // Ajouter l'item au groupe correspondant
      groupedByClient.putIfAbsent(clientKey, () => []);
      groupedByClient[clientKey]!.add(item);
    }

    // Calculer les totaux pour chaque client
    final summaries = groupedByClient.entries.map((entry) {
      final clientName = entry.key;
      final clientItems = entry.value;

      // Somme des cartons
      final totalCartons = clientItems.fold<int>(
        0,
        (sum, item) => sum + ((item.carton as int?) ?? 0),
      );

      // Somme des CBM
      final totalCbm = clientItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.cbnTotal ?? 0.0),
      );

      // Somme des poids
      final totalWeight = clientItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.totalWeight ?? 0.0),
      );

      // Somme des shipping price (CFA) des items du client
      final totalShippingPrice = clientItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.shippingPrice ?? 0.0),
      );

      return ContainerClientSummary(
        clientName: clientName,
        totalCartons: totalCartons,
        totalCbm: totalCbm,
        totalShippingPrice: totalShippingPrice,
        totalWeight: totalWeight,
      );
    }).toList();

    // Trier alphabétiquement par nom de client
    summaries.sort((a, b) => a.clientName.compareTo(b.clientName));

    return summaries;
  }

  /// Génère le résumé par client en calculant le shipping price (CFA) à partir de la grille CBM
  /// pour les items qui n'ont pas de shippingPrice renseigné. À utiliser pour le PDF.
  static Future<List<ContainerClientSummary>> generateSummaryWithShipping(
    Containers container,
    CbmPricingServices cbmService,
  ) async {
    final items = container.items;
    if (items == null || items.isEmpty) {
      return [];
    }

    final Map<String, List<Items>> groupedByClient = {};

    for (final item in items) {
      String clientKey;
      if (item.clientName != null && item.clientName!.trim().isNotEmpty) {
        clientKey = item.clientName!.trim();
      } else if (item.clientId != null) {
        clientKey = 'Client #${item.clientId}';
      } else {
        clientKey = 'Client Inconnu';
      }
      groupedByClient.putIfAbsent(clientKey, () => []);
      groupedByClient[clientKey]!.add(item);
    }

    final summaries = groupedByClient.entries.map((entry) {
      final clientName = entry.key;
      final clientItems = entry.value;

      final totalCartons = clientItems.fold<int>(
        0,
        (sum, item) => sum + (item.carton ?? 0),
      );

      final totalCbm = clientItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.cbnTotal ?? 0.0),
      );

      final totalWeight = clientItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.totalWeight ?? 0.0),
      );

      final totalShippingPrice = clientItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.shippingPrice ?? 0.0),
      );

      return ContainerClientSummary(
        clientName: clientName,
        totalCartons: totalCartons,
        totalCbm: totalCbm,
        totalShippingPrice: totalShippingPrice,
        totalWeight: totalWeight,
      );
    }).toList();

    summaries.sort((a, b) => a.clientName.compareTo(b.clientName));
    return summaries;
  }
}
