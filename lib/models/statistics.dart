/// Modèles DTO pour les statistiques provenant du backend
/// Ces modèles correspondent exactement aux DTOs Spring Boot

/// Statistique d'un client actif
/// Correspond à MostActiveClientDto
class MostActiveClient {
  final int? clientId;
  final String clientName;
  final String? clientPhone;
  final int totalOperations;
  final int achatsCount;
  final int versementsCount;
  final int packagesCount;

  MostActiveClient({
    this.clientId,
    required this.clientName,
    this.clientPhone,
    required this.totalOperations,
    required this.achatsCount,
    required this.versementsCount,
    required this.packagesCount,
  });

  factory MostActiveClient.fromJson(Map<String, dynamic> json) {
    return MostActiveClient(
      clientId: json['clientId'] as int?,
      clientName: json['clientName'] as String? ?? 'Client inconnu',
      clientPhone: json['clientPhone'] as String?,
      totalOperations: json['totalOperations'] as int? ?? 0,
      achatsCount: json['achatsCount'] as int? ?? 0,
      versementsCount: json['versementsCount'] as int? ?? 0,
      packagesCount: json['packagesCount'] as int? ?? 0,
    );
  }
}

/// Statistique d'un fournisseur sollicité
/// Correspond à MostSolicitedSupplierDto
class MostSolicitedSupplier {
  final int? supplierId;
  final String supplierName;
  final String? supplierPhone;
  final int totalOperations;
  final int itemsCount;
  final int containersCount;

  MostSolicitedSupplier({
    this.supplierId,
    required this.supplierName,
    this.supplierPhone,
    required this.totalOperations,
    required this.itemsCount,
    required this.containersCount,
  });

  factory MostSolicitedSupplier.fromJson(Map<String, dynamic> json) {
    return MostSolicitedSupplier(
      supplierId: json['supplierId'] as int?,
      supplierName: json['supplierName'] as String? ?? 'Fournisseur inconnu',
      supplierPhone: json['supplierPhone'] as String?,
      totalOperations: json['totalOperations'] as int? ?? 0,
      itemsCount: json['itemsCount'] as int? ?? 0,
      containersCount: json['containersCount'] as int? ?? 0,
    );
  }
}

/// Statistique d'un port utilisé
/// Correspond à MostUsedHarborDto
class MostUsedHarbor {
  final int? harborId;
  final String harborName;
  final String? harborLocation;
  final int totalPackages;

  MostUsedHarbor({
    this.harborId,
    required this.harborName,
    this.harborLocation,
    required this.totalPackages,
  });

  factory MostUsedHarbor.fromJson(Map<String, dynamic> json) {
    return MostUsedHarbor(
      harborId: json['harborId'] as int?,
      harborName: json['harborName'] as String? ?? 'Port inconnu',
      harborLocation: json['harborLocation'] as String?,
      totalPackages: json['totalPackages'] as int? ?? 0,
    );
  }
}

/// Statistique d'un produit acheté
/// Correspond à MostPurchasedItemDto
class MostPurchasedItem {
  final int? itemId;
  final String itemDescription;
  final int totalPurchases;
  final int totalQuantity;
  final double totalAmount;

  MostPurchasedItem({
    this.itemId,
    required this.itemDescription,
    required this.totalPurchases,
    required this.totalQuantity,
    required this.totalAmount,
  });

  factory MostPurchasedItem.fromJson(Map<String, dynamic> json) {
    return MostPurchasedItem(
      itemId: json['itemId'] as int?,
      itemDescription: json['itemDescription'] as String? ?? 'Produit inconnu',
      totalPurchases: json['totalPurchases'] as int? ?? 0,
      totalQuantity: json['totalQuantity'] as int? ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
