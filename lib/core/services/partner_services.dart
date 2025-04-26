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

  Future<List<Partner>> findAll({int page = 0, String? query}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/partners?page=$page&query=${query ?? ''}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(response.body);
      return jsonBody.map((e) => Partner.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des partenaires");
    }
  }

  Future<String?> create(
    String firstName,
    String lastName,
    String phoneNumber,
    String email,
    String country,
    String adresse,
    String accountType,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/partners/create'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "phoneNumber": phoneNumber,
          "accountType": accountType,
          "adresse": adresse,
          "country": country,
        }),
      );

      if (response.statusCode == 201) {
        return "CREATED";
      } else if (response.statusCode == 409 &&
          response.body == 'Email déjà utilisé par un partenaire !') {
        return "EMAIL_EXIST";
      } else if (response.statusCode == 409 &&
          response.body ==
              'Numéro de téléphone déjà enregistré au nom d\'un partenaire !') {
        return "PHONE_EXIST";
      } else {
        throw Exception("Erreur (${response.statusCode}) : ${response.body}");
      }
    } catch (e) {
      throw Exception("Erreur de connexion: $e");
    }
  }
}
