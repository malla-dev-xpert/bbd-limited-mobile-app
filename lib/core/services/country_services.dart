import 'dart:convert';
import 'dart:developer';
import 'package:bbd_limited/models/country.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CountryServices {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  /// Récupère tous les pays disponibles
  Future<List<Country>> getAllCountries({int page = 0, String? query}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/countries?page=$page&query=${query ?? ''}'),
      );

      log('Countries API Response: ${response.statusCode}');
      log('Countries API Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonBody = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonBody.map((e) => Country.fromJson(e)).toList();
      } else {
        throw Exception('Erreur lors du chargement des pays');
      }
    } catch (e) {
      log('Error loading countries: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère un pays par son ID
  Future<Country> getCountryById(int countryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/countries/$countryId'),
      );

      if (response.statusCode == 200) {
        return Country.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Pays non trouvé');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement du pays: $e');
    }
  }

  /// Crée un nouveau pays
  Future<String> createCountry({
    required String name,
    required String isoCode,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/countries/create?userId=$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "isoCode": isoCode,
        }),
      );

      log('Create Country Response: ${response.statusCode}');
      log('Create Country Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return "SUCCESS";
      } else if (response.statusCode == 409) {
        return "NAME_EXIST";
      } else {
        return "ERROR: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      log('Error creating country: $e');
      return "CONNECTION_ERROR";
    }
  }

  /// Met à jour un pays
  Future<String> updateCountry({
    required int countryId,
    required String name,
    required String isoCode,
    required int userId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/countries/update/$countryId?userId=$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "isoCode": isoCode,
        }),
      );

      if (response.statusCode == 200) {
        return "SUCCESS";
      } else if (response.statusCode == 409) {
        return "NAME_EXIST";
      } else {
        return "ERROR: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "CONNECTION_ERROR";
    }
  }

  /// Supprime un pays
  Future<String> deleteCountry(int countryId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/countries/delete/$countryId?userId=$userId'),
      );

      if (response.statusCode == 200) {
        return "SUCCESS";
      } else if (response.statusCode == 409) {
        return "COUNTRY_IN_USE";
      } else {
        return "ERROR: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "CONNECTION_ERROR";
    }
  }
}
