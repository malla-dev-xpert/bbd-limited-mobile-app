class Achat {
  final int? id;
  final String? descriptionItem;
  final double? quantityItem;
  final double? prixUnitaire;

  Achat copyWith({
    int? id,
    String? descriptionItem,
    double? quantityItem,
    double? prixUnitaire,
  }) {
    return Achat(
      id: id ?? this.id,
      descriptionItem: descriptionItem ?? this.descriptionItem,
      quantityItem: quantityItem ?? this.quantityItem,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
    );
  }

  Achat({this.id, this.descriptionItem, this.quantityItem, this.prixUnitaire});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descriptionItem': descriptionItem,
      'quantityItem': quantityItem,
      'prixUnitaire': prixUnitaire,
    };
  }
}
