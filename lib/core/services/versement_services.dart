import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:bbd_limited/models/versement.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VersementServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<List<Versement>> getByClient(int clientId, {int page = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/versements?page=$page'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
      return jsonBody
          .map((e) => Versement.fromJson(e))
          .where((v) => v.partnerId == clientId)
          .toList();
    } else {
      throw Exception("Erreur lors du chargement des versements");
    }
  }

  Future<List<Versement>> getAll({int page = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/versements?page=$page'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
      return jsonBody.map((e) => Versement.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des colis");
    }
  }

  Future<String?> create(
      int userId, int partnerId, int deviseId, Versement versement) async {
    try {
      final url = Uri.parse(
        '$baseUrl/versements/new?userId=$userId&partnerId=$partnerId&deviseId=$deviseId',
      );

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(versement.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return "CREATED";
      } else {
        final errorMsg = jsonDecode(response.body)['message'] ?? response.body;
        throw Exception("Erreur (${response.statusCode}): $errorMsg");
      }
    } on SocketException {
      throw Exception("Pas de connexion internet");
    } on TimeoutException {
      throw Exception("Timeout - Serveur non disponible");
    } catch (e) {
      throw Exception("Erreur: ${e.toString()}");
    }
  }

  Future<bool> updatePaiement(
    int id,
    int? userId,
    int clientId,
    Versement dto,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/versements/update/$id?userId=$userId&clientId=$clientId',
      );
      final headers = {'Content-Type': 'application/json'};

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Échec de la mise à jour');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> delete(int id, int userId) async {
    final url = Uri.parse("$baseUrl/versements/delete/$id?userId=$userId");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "DELETED";
      } else if (response.body ==
          "Impossible de supprimer: des achats sont déjà associés à ce versement") {
        return "ACHATS_NOT_DELETED";
      }
    } catch (e) {
      throw Exception("Erreur lors de la suppression du colis : $e");
    }
  }
}
