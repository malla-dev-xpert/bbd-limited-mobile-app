import 'dart:convert';
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
}
