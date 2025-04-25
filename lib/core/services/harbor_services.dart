import 'dart:convert';
import 'package:bbd_limited/models/harbor.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HarborServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<List<Harbor>> findAll({int page = 0}) async {
    final response = await http.get(Uri.parse('$baseUrl/harbors?page=$page'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(response.body);
      return jsonBody.map((e) => Harbor.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des ports");
    }
  }
}
