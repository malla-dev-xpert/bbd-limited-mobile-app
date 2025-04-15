import 'dart:convert';
import 'package:bbd_limited/models/warehouses.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WarehouseServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<String> create(String name, String adresse, String storageType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/warehouses/create'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "adresse": adresse,
          "storageType": storageType,
        }),
      );

      if (response.statusCode == 200) {
        return "CREATED";
      } else if (response.statusCode == 409) {
        return "NAME_EXIST";
      } else {
        return "Erreur (${response.statusCode}) : ${response.body}";
      }
    } catch (e) {
      return "Erreur générale : $e";
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

  Future<void> deleteWarehouse(int id, int userID) async {
    final url = Uri.parse("$baseUrl/warehouses/delete/$id?userId=$userID");

    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception("Erreur lors de la suppression de l'entrepot");
    }
  }
}
