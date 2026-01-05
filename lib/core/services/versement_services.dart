import 'dart:async';
import 'dart:convert';
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
          "Impossible de supprimer : des opérations sont déjà associées à ce versement.") {
        return "IMPOSSIBLE";
      }
      return null;
    } catch (e) {
      throw Exception("Erreur lors de la suppression du colis : $e");
    }
  }

  Future<String?> createRetraitArgent({
    required int partnerId,
    required int versementId,
    required int deviseId,
    required double montant,
    required String note,
    required int userId,
  }) async {
    final url = Uri.parse('$baseUrl/versement/retrait');
    final Map<String, dynamic> body = {
      'partnerId': partnerId,
      'versementId': versementId,
      'deviseId': deviseId,
      'montant': montant,
      'note': note,
      'userId': userId,
    };
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "SUCCESS";
      } else if (response.statusCode == 404 &&
          response.body.contains("Montant supérieur au montant")) {
        return "INSUFFICIENT_FUNDS";
      } else {
        // On tente d'extraire le message d'erreur du backend
        String errorMsg;
        try {
          final decoded = jsonDecode(response.body);
          errorMsg = decoded['message'] ?? response.body;
        } catch (_) {
          errorMsg = response.body;
        }
        throw Exception(errorMsg);
      }
    } on SocketException {
      throw Exception("Pas de connexion internet");
    } on TimeoutException {
      throw Exception("Timeout - Serveur non disponible");
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> transferVersement({
    required int versementId,
    required int userId,
    required int oldPartnerId,
    required int newPartnerId,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/versements/transfert/$versementId?userId=$userId&oldPartnerId=$oldPartnerId&newPartnerId=$newPartnerId',
      );

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "SUCCESS";
      } else if (response.statusCode == 403) {
        // Forbidden - Le versement n'appartient pas à ce client
        return "WRONG_PARTNER";
      } else if (response.statusCode == 409) {
        // Conflit - analyser le message d'erreur pour être plus explicite
        final errorMessage = response.body;
        if (errorMessage.contains("SAME_PARTNER") ||
            errorMessage.contains("même client")) {
          return "SAME_PARTNER";
        } else if (errorMessage.contains("IMPOSSIBLE_TRANSFERT") ||
            errorMessage.contains("opérations ont déjà été effectuées")) {
          return "IMPOSSIBLE_TRANSFERT";
        } else {
          // Message d'erreur générique du backend
          return errorMessage;
        }
      } else if (response.statusCode == 400) {
        // Bad Request - Solde insuffisant
        return "BALANCE_INSUFFISANT";
      } else if (response.statusCode == 500) {
        // Internal Server Error - Erreur inconnue
        return "UNKNOWN_ERROR";
      } else {
        return "ERROR";
      }
    } on SocketException {
      throw Exception("Pas de connexion internet");
    } on TimeoutException {
      throw Exception("Timeout - Serveur non disponible");
    } catch (e) {
      throw Exception("Erreur lors du transfert: ${e.toString()}");
    }
  }
}
