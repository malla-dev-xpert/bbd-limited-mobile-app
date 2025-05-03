import 'dart:convert';
import 'package:bbd_limited/models/container.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ContainerServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<List<Containers>> findAll({int page = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/containers?page=$page'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(response.body);
      return jsonBody.map((e) => Containers.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des conteneurs");
    }
  }

  Future<String?> create(
    String reference,
    bool isAvailable,
    int? userId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/containers/create?userId=$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"reference": reference, "isAvailable": isAvailable}),
      );

      if (response.statusCode == 201) {
        return "CREATED";
      } else if (response.statusCode == 409 &&
          response.body == 'Numéro d\'identification déjà utilisé !') {
        return "NAME_EXIST";
      } else {
        throw Exception("Erreur (${response.statusCode}) : ${response.body}");
      }
    } catch (e) {
      throw Exception("Erreur de connexion: $e");
    }
  }
}
