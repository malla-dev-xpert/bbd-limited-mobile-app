import 'dart:convert';
import 'package:bbd_limited/models/harbor.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HarborServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<List<Harbor>> findAll({int page = 0, String? query}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/harbors?page=$page&query=${query ?? ''}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
      return jsonBody.map((e) => Harbor.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des ports");
    }
  }

  Future<String?> create(String name, String location, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/harbors/create?userId=$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "location": location}),
      );

      if (response.statusCode == 201) {
        return "CREATED";
      } else if (response.statusCode == 409 &&
          response.body == 'Nom de port déjà utilisé !') {
        return "NAME_EXIST";
      } else {
        throw Exception("Erreur (${response.statusCode}) : ${response.body}");
      }
    } catch (e) {
      throw Exception("Erreur de connexion: $e");
    }
  }

  Future<void> retrieveContainerToHarbor(
    int id,
    int? userId,
    int harborId,
  ) async {
    final url = Uri.parse(
      "$baseUrl/harbors/retrieve/$id/harbor/$harborId?userId=$userId",
    );

    try {
      final response = await http.delete(url);

      if (response.statusCode == 201) {
        return;
      }
    } catch (e) {
      throw Exception("Erreur lors de la suppression du colis : $e");
    }
  }
}
