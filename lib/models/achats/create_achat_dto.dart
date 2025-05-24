class CreateAchatDto {
  final int versementId;
  // final Packages packageDto;
  final List<CreateLigneDto> lignes;

  CreateAchatDto({
    required this.versementId,
    // required this.packageDto,
    required this.lignes,
  });

  Map<String, dynamic> toJson() {
    return {
      'versementId': versementId,
      // 'packageDto': packageDto.toJson(),
      'lignes': lignes.map((ligne) => ligne.toJson()).toList(),
    };
  }
}

class CreateLigneDto {
  final String? descriptionItem;
  final double? quantityItem;
  final double? prixUnitaire; // Nom aligné avec le backend
  final int supplierId;

  CreateLigneDto({
    this.descriptionItem,
    this.quantityItem,
    this.prixUnitaire,
    required this.supplierId,
  });

  Map<String, dynamic> toJson() {
    return {
      'descriptionItem': descriptionItem,
      'quantityItem': quantityItem,
      'prixUnitaire': prixUnitaire, // Clé correspondant au backend
      'supplierId': supplierId,
    };
  }
}
