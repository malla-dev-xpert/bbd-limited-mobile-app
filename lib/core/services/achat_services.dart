import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:bbd_limited/models/achats/create_achat_dto.dart';
import 'package:bbd_limited/models/achats/achat.dart';
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

      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return "ACHAT_CREATED";
      } else if (response.statusCode == 400) {
        return response.body;
      } else {
        return 'SERVER_ERROR';
      }
    } on http.ClientException catch (e) {
      log('Network error: $e');
      return 'NETWORK_ERROR';
    } catch (e) {
      log('Unexpected error: $e');
      return 'UNEXPECTED_ERROR';
    }
  }

  Future<Achat?> getLastAchatForClient(int clientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/achats/client/$clientId/last'),
      );

      if (response.statusCode == 200) {
        final jsonBody = json.decode(utf8.decode(response.bodyBytes));
        return Achat.fromJson(jsonBody);
      }
      return null;
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération du dernier achat: ${e.toString()}',
      );
    }
  }
}
