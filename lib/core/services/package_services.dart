import 'dart:convert';
import 'dart:developer';
import 'package:bbd_limited/models/embarquement.dart';
import 'package:bbd_limited/models/package.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PackageServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<List<Packages>> findByWarehouse(int warehouseId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/packages/warehouse?warehouseId=$warehouseId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(response.body);
      return jsonBody.map((e) => Packages.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des colis");
    }
  }

  Future<List<Packages>> findAll({int page = 0}) async {
    final response = await http.get(Uri.parse('$baseUrl/packages?page=$page'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(response.body);
      return jsonBody.map((e) => Packages.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des colis");
    }
  }

  Future<List<Packages>> findAllPackageReceived({int page = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/packages/received?page=$page'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(response.body);
      return jsonBody.map((e) => Packages.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des colis");
    }
  }

  Future<int?> create(
    String reference,
    String dimension,
    double weight,
    int userId,
    int warehouseId,
    int partnerId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/packages/create?userId=$userId&warehouseId=$warehouseId&partnerId=$partnerId',
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "reference": reference,
          "dimensions": dimension,
          "weight": weight,
        }),
      );

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['id'];
      } else if (response.statusCode == 409 &&
          response.body == 'Ce colis existe deja !') {
        return null;
      } else {
        throw Exception("Erreur (${response.statusCode}) : ${response.body}");
      }
    } catch (e) {
      throw Exception("Erreur de connexion: $e");
    }
  }

  Future<void> deletePackage(int id, int? userId) async {
    final url = Uri.parse("$baseUrl/packages/delete/$id?userId=$userId");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 201) {
        return;
      }
    } catch (e) {
      throw Exception("Erreur lors de la suppression du colis : $e");
    }
  }

  Future<String?> deletePackageOnContainer(
    int id,
    int? userId,
    int? containerId,
  ) async {
    final url = Uri.parse(
      "$baseUrl/packages/$id/container/$containerId/delete?userId=$userId",
    );

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "DELETED";
      } else if (response.body == "Le colis n'appartient pas à ce conteneur") {
        return "PACKAGES_NOT_FOR_CONTAINER";
      } else if (response.body ==
          "Impossible de retirer un colis d'un conteneur en cours de livraison") {
        return "CONTAINER_IN_PROGRESS";
      }
    } catch (e) {
      throw Exception("Erreur lors de la suppression du colis : $e");
    }
  }

  Future<void> receivePackage(int id, int? userId, int? warehouseId) async {
    final url = Uri.parse(
      "$baseUrl/packages/receive/$id?userId=$userId&warehouseId=$warehouseId",
    );

    try {
      final response = await http.delete(url);

      if (response.statusCode == 201) {
        return;
      }
    } catch (e) {
      throw Exception("Erreur lors de la réception du colis : $e");
    }
  }

  Future<Map<String, dynamic>> embarquerColis(
    EmbarquementRequest request,
  ) async {
    final url = Uri.parse('$baseUrl/containers/embarquer');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    log(response.body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de l\'embarquement');
    }
  }

  Future<void> addItemsToPackage(
    int packageId,
    List<Map<String, dynamic>> items,
    int userId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/packages/$packageId/add-items?userId=$userId',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(items),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add items to package');
      }
    } catch (e) {
      throw Exception('Error adding items to package: $e');
    }
  }

  Future<bool> updatePackage(int id, int? userId, Packages dto) async {
    try {
      final url = Uri.parse('$baseUrl/packages/update/$id?userId=$userId');
      final headers = {'Content-Type': 'application/json'};

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 409 &&
          response.body == 'Nom de colis déjà utilisé !') {
        return false;
      }

      if (response.statusCode == 201) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Échec de la mise à jour');
      }
    } catch (e) {
      rethrow;
    }
  }
}
