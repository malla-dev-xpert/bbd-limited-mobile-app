import 'dart:convert';
import 'dart:developer';
import 'package:bbd_limited/models/partner.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PartnerServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<List<Partner>> fetchPartnersByType(
    String type, {
    int page = 0,
    String? query,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/partners/account-type?type=$type&page=$page&query=${query ?? ''}&includeVersements=true&includeAchats=true',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(utf8.decode(response.bodyBytes));
      final List content = jsonData['content'];

      return content.map((e) => Partner.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des partenaires");
    }
  }

  Future<List<Partner>> findAll({int page = 0, String? query}) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/partners?page=$page&query=${query ?? ''}&includeVersements=true&includeAchats=true',
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
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
    int userId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/partners/create?userId=$userId'),
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
          response.body == 'User not found') {
        return "USER_NOT_FOUND";
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

  Future<String?> deletePartner(int id, int? userId) async {
    final url = Uri.parse("$baseUrl/partners/delete/$id?userId=$userId");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 201) {
        return "DELETED";
      } else if (response.statusCode == 409 &&
          response.body == "Partenaire non trouvé !") {
        return "PARTNER_NOT_FOUND";
      } else if (response.statusCode == 409 &&
          response.body ==
              "Impossible de supprimer, des colis existent pour ce partenaire.") {
        return "PACKAGE_FOUND";
      }
    } catch (e) {
      throw Exception("Erreur lors de la suppression du partenaire : $e");
    }
  }

  Future<bool> updatePartner(int id, Partner dto) async {
    final url = Uri.parse('$baseUrl/partners/update/$id');
    final headers = {'Content-Type': 'application/json'};

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(dto),
    );

    log(response.body);

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Erreur: ${response.statusCode}, ${response.body}');
      throw Exception('Échec de la mise à jour');
    }
  }
}
