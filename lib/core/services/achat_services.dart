import 'dart:async';
import 'dart:convert';
import 'package:bbd_limited/models/achats/create_achat_dto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AchatServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<String?> createAchatForClient({
    required int clientId,
    required int supplierId,
    required int userId,
    required CreateAchatDto dto,
  }) async {
    final url = Uri.parse(
      '$baseUrl/achats/create?clientId=$clientId&supplierId=$supplierId&userId=$userId',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 200) {
        try {
          final responseBody = jsonDecode(response.body);
          return responseBody['code'] ?? "ACHAT_CREATED";
        } catch (e) {
          // If response is not JSON, return it directly
          return response.body.trim();
        }
      } else if (response.statusCode == 400) {
        try {
          final responseBody = jsonDecode(response.body);
          return responseBody['code'] ?? 'VALIDATION_ERROR';
        } catch (e) {
          return response.body.trim();
        }
      } else {
        try {
          final responseBody = jsonDecode(response.body);
          return responseBody['message'] ?? 'SERVER_ERROR';
        } catch (e) {
          return response.body.trim();
        }
      }
    } catch (e) {
      return 'UNEXPECTED_ERROR';
    }
  }
}
