import 'dart:convert';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ItemServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<List<Items>> findByPackageId(int packageId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/items/package/$packageId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
      return jsonBody.map((e) => Items.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des articles");
    }
  }

  Future<List<Items>> findItemsByClient(int clientId) async {
    try {
      final url = Uri.parse('$baseUrl/items/customer?clientId=$clientId');
      print("Appel API: $url");

      final response = await http.get(url);

      print("Status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonBody =
            json.decode(utf8.decode(response.bodyBytes));
        print("JSON décodé: $jsonBody");
        final items = jsonBody.map((e) => Items.fromJson(e)).toList();
        print("Items créés: ${items.length}");
        return items;
      } else {
        print("Erreur HTTP: ${response.statusCode} - ${response.body}");
        throw Exception(
            "Erreur lors du chargement des articles éligibles (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      print("Exception dans findItemsByClient: $e");
      rethrow;
    }
  }

  Future<String?> deleteItem(int id, int? userId, int clientId) async {
    final url = Uri.parse(
      "$baseUrl/items/delete/$id?userId=$userId&clientId=$clientId",
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
        return "CLIENT_NOT_FOUND_OR_MISMATCH";
      } else if (response.statusCode == 409 &&
          response.body == "Utilisateur non trouve.") {
        return "USER_NOT_FOUND";
      }
    } catch (e) {
      throw Exception("Erreur lors de la suppression de l'article : $e");
    }
  }

  Future<String> updateItem({
    required int itemId,
    required int userId,
    required int clientId,
    required Items item,
  }) async {
    final url = Uri.parse('$baseUrl/items/update/$itemId?userId=$userId');
    final headers = {'Content-Type': 'application/json'};
    final body = item.toJson();
    body['clientId'] = clientId;

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else {
      throw Exception('Erreur lors de la modification : ${response.body}');
    }
  }
}
