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

  Future<String?> deleteItem(int id, int? userId, int packageId) async {
    final url = Uri.parse(
      "$baseUrl/items/delete/$id?userId=$userId&packageId=$packageId",
    );

    try {
      final response = await http.delete(url);

      if (response.statusCode == 201) {
        return "DELETED";
      } else if (response.statusCode == 409 &&
          response.body == "Article non trouve.") {
        return "ITEM_NOT_FOUND";
      } else if (response.statusCode == 409 &&
          response.body == "Colis non trouve.") {
        return "PACKAGE_NOT_FOUND";
      } else if (response.statusCode == 409 &&
          response.body == "Utilisateur non trouve.") {
        return "USER_NOT_FOUND";
      }
    } catch (e) {
      throw Exception("Erreur lors de la suppression de l'article : $e");
    }
  }

  Future<bool> updateItem(int id, int? packageId, Item dto) async {
    try {
      final url = Uri.parse('$baseUrl/items/update/$id?packageId=$packageId');
      final headers = {'Content-Type': 'application/json'};

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(dto.toJson()),
      );

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
