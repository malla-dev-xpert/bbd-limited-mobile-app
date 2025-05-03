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

  Future<String?> delete(int id, int? userId) async {
    final url = Uri.parse("$baseUrl/containers/delete/$id?userId=$userId");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 201) {
        return "DELETED";
      } else if (response.statusCode == 409 &&
          response.body == 'Conteneur introuvable.') {
        return "CONTAINER_NOT_FOUND";
      } else if (response.statusCode == 409 &&
          response.body == 'Utilisateur introuvable.') {
        return "USER_NOT_FOUND";
      } else if (response.statusCode == 409 &&
          response.body ==
              'Impossible de supprimer : Des colis existent dans ce conteneur.') {
        return "PACKAGE_EXIST";
      }
    } catch (e) {
      throw Exception("Erreur lors de la suppression du conteneur : $e");
    }
  }
}
