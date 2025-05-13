import 'dart:async';
import 'dart:convert';
import 'package:bbd_limited/models/versement.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VersementServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<List<Versement>> getByClient(int cliendId, {int page = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/versements?cliendId=$cliendId&page=$page'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(response.body);
      return jsonBody.map((e) => Versement.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des versements");
    }
  }

  Future<List<Versement>> getAll({int page = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/versements?page=$page'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(response.body);
      return jsonBody.map((e) => Versement.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des colis");
    }
  }
}
