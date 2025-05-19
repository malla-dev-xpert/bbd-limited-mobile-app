import 'dart:convert';
import 'dart:developer';
import 'package:bbd_limited/models/expedition.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ExpeditionServices {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  Future<List<Expedition>> findAll({int page = 0, String? query}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/expeditions?page=$page&query=${query ?? ''}'),
    );

    log(response.body);

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
      return jsonBody.map((e) => Expedition.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des expeditions");
    }
  }
}
