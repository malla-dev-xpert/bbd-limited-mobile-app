import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/achats/create_achat_dto.dart';
import 'package:bbd_limited/core/api/api_result.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AchatServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<ApiResult<String>> createAchatForClient({
    required int clientId,
    required int userId,
    required CreateAchatDto dto,
  }) async {
    final url =
        Uri.parse('$baseUrl/achats/create?clientId=$clientId&userId=$userId');

    try {
      // Log des données avant envoi
      log('=== CRÉATION ACHAT ===');
      log('URL: $url');
      log('Client ID: $clientId');
      log('User ID: $userId');
      log('Versement ID: ${dto.versementId}');
      log('Nombre d\'articles: ${dto.items.length}');
      log('DTO JSON: ${jsonEncode(dto.toJson())}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      );

      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse<String>.fromJson(responseBody);

      switch (response.statusCode) {
        case 200:
          final successMessage =
              apiResponse.data == "ACHAT_CREATED_AS_DEBT_SUCCESSFULLY"
                  ? "Achat créé avec succès (enregistré comme dette)"
                  : "Achat créé avec succès";
          log('✅ Succès: $successMessage');
          return ApiResult.success(apiResponse.data.toString());

        case 400:
          // Bad Request (BusinessException ou validation errors)
          final errorMessage = apiResponse.errors?.isNotEmpty == true
              ? apiResponse.errors!.join(', ')
              : apiResponse.message ?? 'Requête invalide';
          log('❌ Erreur 400: $errorMessage');
          return ApiResult.failure(
            errorMessage: errorMessage,
            errorCode: response.statusCode,
            errors: apiResponse.errors ?? [],
          );

        case 404:
          // Not Found (EntityNotFoundException)
          log('❌ Erreur 404: ${apiResponse.message}');
          return ApiResult.failure(
            errorMessage: apiResponse.message ?? 'Ressource non trouvée',
            errorCode: response.statusCode,
            errors: apiResponse.errors ?? [],
          );

        case 500:
          // Internal Server Error - Gestion spéciale pour les erreurs de dette
          log('❌ Erreur 500: ${apiResponse.message}');
          String errorMessage = apiResponse.message ?? 'Erreur serveur';

          // Vérifier si c'est une erreur liée à getTotalDebt()
          if (apiResponse.message?.contains('getTotalDebt()') == true ||
              apiResponse.message?.contains('Cannot invoke') == true) {
            errorMessage =
                'Erreur lors de la création de la dette. Veuillez vérifier les informations du client et réessayer.';
          }

          return ApiResult.failure(
            errorMessage: errorMessage,
            errorCode: response.statusCode,
            errors: apiResponse.errors ?? [],
          );

        default:
          log('❌ Erreur ${response.statusCode}: ${apiResponse.message}');
          return ApiResult.failure(
            errorMessage: apiResponse.message ?? 'Erreur serveur',
            errorCode: response.statusCode,
            errors: apiResponse.errors ?? [],
          );
      }
    } on SocketException {
      log('❌ Erreur réseau: Pas de connexion Internet');
      return ApiResult.failure(
        errorMessage: 'Pas de connexion Internet',
        errorCode: 0,
      );
    } on FormatException {
      log('❌ Erreur format: Format de réponse du serveur invalide');
      return ApiResult.failure(
        errorMessage: 'Format de réponse du serveur invalide',
        errorCode: 0,
      );
    } on http.ClientException catch (e) {
      log('❌ Erreur client HTTP: ${e.message}');
      return ApiResult.failure(
        errorMessage: 'Erreur réseau: ${e.message}',
        errorCode: 0,
      );
    } catch (e) {
      log('❌ Erreur inattendue: $e');
      return ApiResult.failure(
        errorMessage: 'Erreur inattendue: ${e.toString()}',
        errorCode: 0,
      );
    }
  }

  Future<ApiResult<void>> confirmDelivery({
    required List<int> itemIds,
    required int userId,
  }) async {
    final url = Uri.parse('$baseUrl/achats/items/confirm-delivery');
    final headers = {
      'Content-Type': 'application/json',
      'X-User-Id': userId.toString(),
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'itemIds': itemIds,
        }),
      );

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse<void>.fromJson(responseBody);
      log('Response status: ${response.statusCode}');
      log('Response body: $responseBody');
      log('Api Response: $apiResponse');

      if (response.statusCode == 200) {
        return ApiResult.success(null);
      } else {
        return ApiResult.failure(
          errorMessage: apiResponse.message,
          errorCode: response.statusCode,
          errors: apiResponse.errors ?? [],
        );
      }
    } on SocketException {
      return ApiResult.failure(
        errorMessage: 'No internet connection',
        errorCode: 0,
      );
    } on FormatException {
      return ApiResult.failure(
        errorMessage: 'Invalid server response format',
        errorCode: 0,
      );
    } on http.ClientException catch (e) {
      return ApiResult.failure(
        errorMessage: 'Network error: ${e.message}',
        errorCode: 0,
      );
    } catch (e) {
      return ApiResult.failure(
        errorMessage: 'Unexpected error: ${e.toString()}',
        errorCode: 0,
      );
    }
  }

  Future<List<Achat>> findAll({int page = 0}) async {
    try {
      final url = Uri.parse('$baseUrl/achats?page=$page');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonBody = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonBody.map((e) => Achat.fromJson(e)).toList();
      } else {
        throw Exception("Erreur lors du chargement des achats");
      }
    } catch (e) {
      rethrow;
    }
  }
}
