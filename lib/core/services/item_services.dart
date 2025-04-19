import 'dart:convert';
import 'package:bbd_limited/models/items.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ItemServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<List<Item>> findByPackageId(int packageId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/items/package/$packageId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(response.body);
      return jsonBody.map((e) => Item.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des articles");
    }
  }
}
