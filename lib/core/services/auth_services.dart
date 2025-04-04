import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend
  final storage = FlutterSecureStorage();

  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/auth'), // Utilise l’URL du .env
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)["token"];
      await storage.write(key: "jwt", value: token);
      return true;
    } else {
      return false;
    }
  }

  Future<String?> getToken() async {
    return await storage.read(key: "jwt");
  }

  Future<void> logout() async {
    await storage.delete(key: "jwt");
  }
}
