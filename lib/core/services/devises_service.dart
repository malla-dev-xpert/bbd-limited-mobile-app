import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeviseServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend
  final storage = FlutterSecureStorage();

  Future<String> create(String name, String code, double rate) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/devises/create'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "code": code, "rate": rate}),
      );

      if (response.statusCode == 200) {
        return "CREATED";
      } else if (response.statusCode == 409) {
        return "CODE_EXIST";
      } else {
        return "Erreur (${response.statusCode}) : ${response.body}";
      }
    } catch (e) {
      return "Erreur générale : $e";
    }
  }
}
