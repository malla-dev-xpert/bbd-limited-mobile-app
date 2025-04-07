import 'dart:convert';
import 'package:bbd_limited/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend
  final storage = FlutterSecureStorage();
  static const String _usernameKey = 'username';
  static const String _tokenKey = 'jwt';

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/auth'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final token = response.body;
        await storage.write(key: _tokenKey, value: token);
        await storage.write(key: _usernameKey, value: username);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<String?> getToken() async {
    return await storage.read(key: "jwt");
  }

  Future<void> logout() async {
    await storage.delete(key: "jwt");
    await storage.delete(key: _usernameKey);
  }

  Future<String?> getUsername() async {
    return await storage.read(key: _usernameKey);
  }

  Future<User?> getUserInfo() async {
    try {
      final username = await getUsername();
      if (username == null) return null;

      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/users/$username'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        print('Données utilisateur reçues: $userData');
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des informations utilisateur: $e');
      return null;
    }
  }
}
