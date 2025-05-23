import 'package:bbd_limited/models/package.dart';

class CreateAchatDto {
  final int versementId;
  final Packages packageDto;
  final List<CreateLigneDto> lignes;

  CreateAchatDto({
    required this.versementId,
    required this.packageDto,
    required this.lignes,
  });

  Map<String, dynamic> toJson() {
    return {
      'versementId': versementId,
      'packageDto': packageDto.toJson(),
      'lignes': lignes.map((ligne) => ligne.toJson()).toList(),
    };
  }
}

class CreateLigneDto {
  final String? descriptionItem;
  final double? quantityItem;
  final double? prixUnitaire; // Nom aligné avec le backend

  CreateLigneDto({this.descriptionItem, this.quantityItem, this.prixUnitaire});

  Map<String, dynamic> toJson() {
    return {
      'descriptionItem': descriptionItem,
      'quantityItem': quantityItem,
      'prixUnitaire': prixUnitaire, // Clé correspondant au backend
    };
  }
}
