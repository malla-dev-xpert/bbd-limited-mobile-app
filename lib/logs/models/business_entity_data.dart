/// Modèle représentant les données métier extraites d'une entité
/// Ne contient jamais d'IDs techniques, uniquement des valeurs métier
class BusinessEntityData {
  final Map<String, dynamic> data;
  final Map<String, dynamic>? beforeData;
  final Map<String, dynamic>? afterData;

  BusinessEntityData({
    required this.data,
    this.beforeData,
    this.afterData,
  });

  /// Retourne true si des données before/after sont disponibles
  bool get hasBeforeAfter => beforeData != null || afterData != null;

  /// Retourne true si les données before et after sont disponibles
  bool get hasBothBeforeAfter => beforeData != null && afterData != null;

  /// Retourne true si seulement before est disponible (DELETE)
  bool get hasOnlyBefore => beforeData != null && afterData == null;

  /// Retourne true si seulement after est disponible (CREATE)
  bool get hasOnlyAfter => beforeData == null && afterData != null;

  /// Retourne les données principales (pour CREATE ou actions simples)
  Map<String, dynamic> get mainData => data;

  /// Retourne true si les données sont vides
  bool get isEmpty => data.isEmpty && beforeData == null && afterData == null;
}

