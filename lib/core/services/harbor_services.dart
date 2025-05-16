import 'dart:convert';
import 'dart:io';
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

  Future<Harbor> getHarborDetails(int harborId) async {
    final response = await http.get(Uri.parse('$baseUrl/harbors/$harborId'));

    if (response.statusCode == 200) {
      return Harbor.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Erreur lors du chargement du port');
    }
  }

  Future<String?> retrieveContainerToHarbor(
    int containerId,
    int? userId,
    int harborId,
  ) async {
    final url = Uri.parse(
      "$baseUrl/containers/retrieve/harbor?containerId=$containerId&userId=$userId&harborId=$harborId",
    );

    try {
      final response = await http.delete(url);

      if (response.statusCode == HttpStatus.created) {
        return "SUCCESS";
      } else if (response.statusCode == HttpStatus.conflict) {
        final errorMessage = response.body;

        if (errorMessage.contains("Impossible de retirer le conteneur")) {
          return "IMPOSSIBLE";
        } else if (errorMessage.contains("Le conteneur a déjà été retiré")) {
          return "CONTAINER_ALREADY_RETREIVED";
        }
      }
    } catch (e) {
      throw Exception("Erreur lors du retrait : $e");
    }
  }
}
