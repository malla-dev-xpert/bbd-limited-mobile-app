import 'dart:convert';
import 'package:bbd_limited/models/expedition.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ExpeditionServices {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  Future<List<Expedition>> findAll({int page = 0, String? query}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/expeditions?page=$page&query=${query ?? ''}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
      return jsonBody.map((e) => Expedition.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des expeditions");
    }
  }

  Future<String?> create({
    required Expedition dto,
    required int clientId,
    required int userId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/expeditions/create?clientId=$clientId&userId=$userId',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "SUCCESS";
      }
    } on http.ClientException catch (e) {
      return 'NETWORK_ERROR';
    } catch (e) {
      throw Exception('Erreur inattendue: ${e.toString()}');
    }
  }

  Future<String?> startExpedition(int id) async {
    final url = Uri.parse(
      "$baseUrl/expeditions/start-expedition?expeditionId=$id",
    );

    try {
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "SUCCESS";
      } else {
        return "Erreur : ${response.body}";
      }
    } catch (e) {
      return "Erreur lors du démarrage de l'expédition : $e";
    }
  }

  Future<String?> deliverExpedition(int id) async {
    final url = Uri.parse(
      "$baseUrl/expeditions/deliver-expedition?expeditionId=$id",
    );

    try {
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "SUCCESS";
      } else {
        return "Erreur : ${response.body}";
      }
    } catch (e) {
      return "Erreur lors de la livraison de l'expédition : $e";
    }
  }

  Future<String?> updateExpedition(Expedition expedition) async {
    final url = Uri.parse('$baseUrl/expeditions/update/${expedition.id}');
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(expedition.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "SUCCESS";
      } else {
        return "Erreur : ${response.body}";
      }
    } catch (e) {
      return "Erreur lors de la mise à jour de l'expédition : $e";
    }
  }
}
