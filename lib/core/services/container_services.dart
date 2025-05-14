import 'dart:convert';
import 'dart:developer';
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

  Future<Containers> getContainerDetails(int containerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/containers/$containerId'),
    );

    if (response.statusCode == 200) {
      return Containers.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors du chargement du conteneur');
    }
  }

  Future<String?> create(
    String reference,
    String size,
    bool isAvailable,
    int? userId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/containers/create?userId=$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "reference": reference,
          "size": size,
          "isAvailable": isAvailable,
        }),
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

  Future<String?> startDelivery(int id, int? userId) async {
    final url = Uri.parse("$baseUrl/containers/delivery/$id?userId=$userId");

    try {
      final response = await http.get(url);

      log(response.body);
      log(response.statusCode.toString());

      if (response.statusCode == 201 || response.statusCode == 200) {
        return "SUCCESS";
      } else if (response.statusCode == 409 &&
          response.body ==
              'Impossible de démarrer la livraison, pas de colis dans le conteneur.') {
        return "NO_PACKAGE_FOR_DELIVERY";
      }
    } catch (e) {
      throw Exception("Erreur lors du démarrage de la livraison : $e");
    }
  }

  Future<String?> update(int id, int? userId, Containers dto) async {
    try {
      final url = Uri.parse('$baseUrl/containers/update/$id?userId=$userId');
      final headers = {'Content-Type': 'application/json'};

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 409 &&
          response.body == 'Ce conteneur existe déjà !') {
        return "REF_EXIST";
      }

      if (response.statusCode == 201) {
        return "UPDATED";
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Échec de la mise à jour');
      }
    } catch (e) {
      rethrow;
    }
  }
}
