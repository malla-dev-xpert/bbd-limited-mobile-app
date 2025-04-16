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
}
