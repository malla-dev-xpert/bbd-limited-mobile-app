import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      );

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse<String>.fromJson(responseBody);

      if (response.statusCode == 200) {
        return ApiResult.success(
            apiResponse.data ?? "ACHAT_CREATED_SUCCESSFULLY");
      } else {
        return ApiResult.failure(
          errorMessage: apiResponse.message ?? 'Operation failed',
          errorCode: response.statusCode,
          errors: apiResponse.errors ?? [],
        );
      }
    } on SocketException {
      return ApiResult.failure(
        errorMessage: 'No Internet connection',
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
}
