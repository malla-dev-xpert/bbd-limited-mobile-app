import 'dart:async';
import 'dart:convert';
import 'package:bbd_limited/models/achats/create_achat_dto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AchatServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  // Future<List<Packages>> findAll({int page = 0}) async {
  //   final response = await http.get(Uri.parse('$baseUrl/achats?page=$page'));

  //   if (response.statusCode == 200) {
  //     final List<dynamic> jsonBody = json.decode(response.body);
  //     return jsonBody.map((e) => Packages.fromJson(e)).toList();
  //   } else {
  //     throw Exception("Erreur lors du chargement des colis");
  //   }
  // }

  Future<String?> createAchatForClient({
    required int clientId,
    required int supplierId,
    required int userId,
    required CreateAchatDto dto,
  }) async {
    final url = Uri.parse(
      '$baseUrl/achats/create?clientId=$clientId&supplierId=$supplierId&userId=$userId',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "SUCCESS";
      } else if (response.statusCode == 409 &&
          response.body == 'Invalid versement.') {
        return "INVALID_ACHAT";
      } else if (response.statusCode == 409 &&
          response.body == "Inactif versement.") {
        return "INACTIVE_ACHAT";
      }
    } on http.ClientException catch (e) {
      return 'NETWORK_ERROR';
    } catch (e) {
      throw Exception('Erreur inattendue: ${e.toString()}');
    }
  }
}
