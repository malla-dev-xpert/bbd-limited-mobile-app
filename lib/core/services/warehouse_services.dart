import 'dart:convert';
import 'package:bbd_limited/models/warehouses.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WarehouseServices {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  Future<String> create(
    String name,
    String adresse,
    String storageType,
    int userId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/warehouses/create?userId=$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "adresse": adresse,
          "storageType": storageType,
        }),
      );

      if (response.statusCode == 201) {
        return "CREATED";
      } else if (response.body == 'Cet entrepot existe déjà !' &&
          response.statusCode == 409) {
        return "NAME_EXIST";
      } else if (response.body ==
              'Un entrepôt existe déjà avec cette adresse !' &&
          response.statusCode == 409) {
        return "ADRESS_EXIST";
      } else {
        return "Erreur (${response.statusCode}) : ${response.body}";
      }
    } catch (e) {
      return "Erreur de connexion : $e";
    }
  }

  Future<List<Warehouses>> findAllWarehouses({int page = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/warehouses?page=$page'),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      final List<dynamic> content = jsonBody['content'];
      return content.map((e) => Warehouses?.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des entrepots");
    }
  }

  Future<String?> deleteWarehouse(int id, int? userId) async {
    final url = Uri.parse("$baseUrl/warehouses/delete/$id?userId=$userId");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 201) {
        return "DELETED";
      } else if (response.statusCode == 409 &&
          response.body ==
              "Impossible de supprimer, des colis existent dans cet entrepôt.") {
        return "PACKAGE_FOUND";
      }
    } catch (e) {
      throw Exception("Erreur lors de la suppression de l'entrepôt : $e");
    }
  }

  Future<bool> updateWarehouse(int id, Warehouses dto, int? userId) async {
    try {
      final url = Uri.parse('$baseUrl/warehouses/update/$id?userId=$userId');
      final headers = {'Content-Type': 'application/json'};

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 409 &&
          response.body == 'Cet entrepot existe déjà !') {
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

  Future<Warehouses> getWarehouseById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/warehouses/$id'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return Warehouses.fromJson(jsonData);
    } else if (response.statusCode == 404) {
      throw Exception('Entrepôt non trouvé avec l\'ID : $id');
    } else {
      throw Exception('Erreur serveur : ${response.statusCode}');
    }
  }
}
