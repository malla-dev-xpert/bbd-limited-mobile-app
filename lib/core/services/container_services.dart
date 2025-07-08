import 'dart:convert';
import 'dart:io';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/embarquement.dart';
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
      final List<dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
      return jsonBody.map((e) => Containers.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des conteneurs");
    }
  }

  Future<List<Containers>> findAllContainerNotInHarbor({int page = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/containers/not-in-harbor?page=$page'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
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
      return Containers.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Erreur lors du chargement du conteneur');
    }
  }

  Future<String?> create(
    String reference,
    String size,
    bool isAvailable,
    int? userId,
    int? supplierId,
    double? locationFee,
    double? localCharge,
    double? loadingFee,
    double? overweightFee,
    double? checkingFee,
    double? telxFee,
    double? otherFees,
    double? margin,
  ) async {
    try {
      String url = '$baseUrl/containers/create?userId=$userId';
      if (supplierId != null) {
        url += '&supplierId=$supplierId';
      }
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "reference": reference,
          "size": size,
          "isAvailable": isAvailable,
          "locationFee": locationFee,
          "localCharge": localCharge,
          "loadingFee": loadingFee,
          "overweightFee": overweightFee,
          "checkingFee": checkingFee,
          "telxFee": telxFee,
          "otherFees": otherFees,
          "margin": margin,
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

  Future<String?> confirmReceiving(int id, int? userId) async {
    final url =
        Uri.parse("$baseUrl/containers/delivery-received/$id?userId=$userId");

    try {
      final response = await http.get(url);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return "SUCCESS";
      } else if (response.statusCode == 409 &&
          response.body ==
              'Impossible de confirmer la réception, pas de colis dans le conteneur.') {
        return "NO_PACKAGE_FOR_DELIVERY";
      } else if (response.statusCode == 409 &&
          response.body == 'Le conteneur n\'est pas en status INPROGRESS.') {
        return "CONTAINER_NOT_IN_PROGRESS";
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

  Future<String> embarquerContainerToHarbor(
      HarborEmbarquementRequest request, int userId) async {
    try {
      final url =
          Uri.parse('$baseUrl/containers/embarquer/in-harbor?userId=$userId');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == HttpStatus.created) {
        return "SUCCESS";
      } else if (response.statusCode == HttpStatus.conflict) {
        final errorMessage = response.body;

        if (errorMessage.contains("Le port n'est pas disponible")) {
          return "HARBOR_NOT_AVAILABLE";
        } else if (errorMessage.contains("est déjà dans le port")) {
          return "CONTAINER_ALREADY_IN_ANOTHER_HARBOR";
        }
        return "CONFLICT_ERROR";
      } else if (response.statusCode == HttpStatus.notFound) {
        return "HARBOR_NOT_FOUND";
      } else {
        return "SERVER_ERROR: ${response.statusCode}";
      }
    } catch (e) {
      return "UNEXPECTED_ERROR: ${e.toString()}";
    }
  }
}
