import 'dart:convert';
import 'package:bbd_limited/models/partner.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PartnerServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<List<Partner>> fetchPartnersByType(String type, {int page = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/partners/account-type?type=$type&page=$page'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List content = jsonData['content'];

      return content.map((e) => Partner.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des partenaires");
    }
  }
}
