import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/package.dart';

class CreateAchatDto {
  final int versementId;
  final Packages packageDto;
  final List<Achat> lignes;

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
