import 'dart:convert';
import 'dart:developer';
import 'package:bbd_limited/core/api/api_result.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Exception personnalisée pour les erreurs de mise à jour d'item
class ItemUpdateException implements Exception {
  final String message;
  final String? errorCode;
  final int? statusCode;

  ItemUpdateException(this.message, {this.errorCode, this.statusCode});

  @override
  String toString() => message;
}

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

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonBody =
            json.decode(utf8.decode(response.bodyBytes));
        final items = jsonBody.map((e) => Items.fromJson(e)).toList();
        return items;
      } else {
        throw Exception(
            "Erreur lors du chargement des articles éligibles (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Items>> findItemsBySupplier(int supplierId) async {
    try {
      final url = Uri.parse('$baseUrl/items/supplier?supplierId=$supplierId');

      final response = await http.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> jsonBody =
            json.decode(utf8.decode(response.bodyBytes));
        final items = jsonBody.map((e) => Items.fromJson(e)).toList();
        return items;
      } else {
        throw Exception(
            "Erreur lors du chargement des articles du fournisseur (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> reverseItem(int id, int? userId, int clientId) async {
    final url = Uri.parse(
      "$baseUrl/items/reverse/$id?userId=$userId&clientId=$clientId",
    );

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        return "DELETED_AND_REVERTED";
      } else if (response.statusCode == 404 &&
          response.body == "Article non trouvé.") {
        return "ITEM_NOT_FOUND";
      } else if (response.statusCode == 404 &&
          response.body == "Client non trouvé.") {
        return "CLIENT_NOT_FOUND_OR_MISMATCH";
      } else if (response.statusCode == 404 &&
          response.body == "Utilisateur non trouvé.") {
        return "USER_NOT_FOUND";
      }
    } catch (e) {
      throw Exception("Erreur lors de la suppression de l'article : $e");
    }
    return null;
  }

  Future<ApiResponse<String>> updateItem({
    required int itemId,
    required int userId,
    required Items item,
    int? clientId,
  }) async {
    final url = Uri.parse('$baseUrl/items/update/$itemId?userId=$userId');
    final headers = {'Content-Type': 'application/json'};
    final body = item.toJson();

    // Ajouter le clientId au body si fourni
    if (clientId != null) {
      body['clientId'] = clientId;
    }

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      // Décoder la réponse
      final responseBody = response.body.isNotEmpty
          ? json.decode(utf8.decode(response.bodyBytes))
          : <String, dynamic>{};

      final apiResponse = ApiResponse<String>.fromJson(
        responseBody as Map<String, dynamic>,
        dataParser: (data) => data.toString(),
      );

      // Gérer les différents codes de statut HTTP selon le backend
      if (response.statusCode == 200 && apiResponse.success == true) {
        return apiResponse;
      } else {
        throw ItemUpdateException(
          apiResponse.message ?? 'Erreur lors de la mise à jour',
          errorCode: apiResponse.errorCode,
          statusCode: response.statusCode,
        );
      }
    } on ItemUpdateException {
      rethrow;
    } catch (e) {
      // Gérer les erreurs de parsing ou autres exceptions
      if (e is ItemUpdateException) {
        rethrow;
      }
      throw ItemUpdateException(
        'Erreur lors de la modification de l\'item: ${e.toString()}',
        errorCode: 'INTERNAL_ERROR',
      );
    }
  }

  Future<ApiResult<String>> deleteItem({
    required int itemId,
    required int userId,
  }) async {
    final url = Uri.parse('$baseUrl/items/delete/$itemId?userId=$userId');
    try {
      final response =
          await http.delete(url).timeout(const Duration(seconds: 10));

      // On décode TOUJOURS le JSON, même en cas d'erreur (400, 404, etc.)
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final apiResponse = ApiResponse<String>.fromJson(jsonResponse);

      if (response.statusCode == 200 && (apiResponse.success ?? false)) {
        return ApiResult.success(apiResponse.message ?? 'Suppression réussie');
      } else {
        // On retourne le message d'erreur précis envoyé par le backend (ex: "ITEM_NOT_FOUND")
        return ApiResult.failure(
          errorMessage: apiResponse.message ?? 'Erreur lors de la suppression',
          errorCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResult.failure(errorMessage: 'Erreur réseau : $e');
    }
  }
}
