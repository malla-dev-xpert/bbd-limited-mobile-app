import 'dart:convert';
import 'package:bbd_limited/models/devises.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeviseServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

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

  Future<List<Devise>> findAllDevises({int page = 0}) async {
    final response = await http.get(Uri.parse('$baseUrl/devises?page=$page'));

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      final List<dynamic> content = jsonBody['content'];
      return content.map((e) => Devise.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des devises");
    }
  }

  Future<void> deleteDevise(int id) async {
    final url = Uri.parse("$baseUrl/devises/delete/$id");

    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception("Erreur lors de la suppression de la devise");
    }
  }
}
