/// Modèle représentant le résumé agrégé par client des items dans un conteneur.
///
/// Ce modèle est utilisé pour afficher le tableau de facture récapitulatif
/// qui regroupe les items par client avec leurs totaux respectifs.
class ContainerClientSummary {
  /// Nom du client (MARK dans le tableau)
  final String clientName;

  /// Somme totale des cartons pour ce client (CTNS dans le tableau)
  final int totalCartons;

  /// Somme totale du CBM pour ce client (T.CBM dans le tableau)
  final double totalCbm;

  /// Somme totale du poids pour ce client (KGS dans le tableau)
  final double totalWeight;

  const ContainerClientSummary({
    required this.clientName,
    required this.totalCartons,
    required this.totalCbm,
    required this.totalWeight,
  });

  @override
  String toString() {
    return 'ContainerClientSummary(clientName: $clientName, totalCartons: $totalCartons, totalCbm: $totalCbm, totalWeight: $totalWeight)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ContainerClientSummary &&
        other.clientName == clientName &&
        other.totalCartons == totalCartons &&
        other.totalCbm == totalCbm &&
        other.totalWeight == totalWeight;
  }

  @override
  int get hashCode {
    return clientName.hashCode ^
        totalCartons.hashCode ^
        totalCbm.hashCode ^
        totalWeight.hashCode;
  }
}
