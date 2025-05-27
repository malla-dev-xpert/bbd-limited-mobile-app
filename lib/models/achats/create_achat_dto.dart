class CreateAchatDto {
  final int versementId;
  final List<CreateLigneDto> lignes;

  CreateAchatDto({required this.versementId, required this.lignes});

  Map<String, dynamic> toJson() {
    return {
      'versementId': versementId,
      'lignes':
          lignes
              .map(
                (ligne) => {
                  'descriptionItem': ligne.descriptionItem,
                  'quantityItem': ligne.quantityItem.toInt(),
                  'prixUnitaire': ligne.prixUnitaire,
                  'supplierId': ligne.supplierId,
                },
              )
              .toList(),
    };
  }
}

class CreateLigneDto {
  final String descriptionItem;
  final int quantityItem;
  final double prixUnitaire;
  final int supplierId;

  CreateLigneDto({
    required this.descriptionItem,
    required this.quantityItem,
    required this.prixUnitaire,
    required this.supplierId,
  });

  Map<String, dynamic> toJson() {
    return {
      'descriptionItem': descriptionItem,
      'quantityItem': quantityItem,
      'prixUnitaire': prixUnitaire,
      'supplierId': supplierId,
    };
  }
}
