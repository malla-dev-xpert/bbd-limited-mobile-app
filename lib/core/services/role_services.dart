import 'dart:convert';
import 'package:bbd_limited/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RoleServices {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  Future<List<Role>> getAllRoles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/roles'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonBody = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonBody.map((e) => Role.fromJson(e)).toList();
      } else {
        throw Exception('Erreur lors du chargement des rôles');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
