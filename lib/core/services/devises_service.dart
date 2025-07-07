import 'dart:convert';
import 'dart:developer';
import 'package:bbd_limited/models/devises.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeviseServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<String> create({
    required String name,
    required String code,
    double? rate,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/devises/create?userId=$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "code": code,
          "rate": rate,
        }),
      );

      log(response.body);
      log(response.statusCode.toString());

      if (response.statusCode == 409) {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          final String? message = errorData['message'] as String?;
          if (message != null) {
            // Modification ici pour rendre la vérification plus flexible
            if (message.toLowerCase().contains("nom de devise")) {
              return "NAME_EXIST";
            } else if (message.toLowerCase().contains("code")) {
              return "CODE_EXIST";
            } else if (message.toLowerCase().contains("taux de conversion")) {
              return "RATE_NOT_FOUND";
            } else if (message.toLowerCase().contains("service de taux")) {
              return "RATE_SERVICE_ERROR";
            } else {
              return message; // Retourne le message original
            }
          } else {
            return "GENERAL_ERROR";
          }
        } catch (_) {
          return "GENERAL_ERROR";
        }
      }
      if (response.statusCode == 201 || response.statusCode == 200) {
        return "SUCCESS";
      } else {
        return "GENERAL_ERROR";
      }
    } catch (e) {
      return "CONNECTION_ERROR";
    }
  }

  Future<List<Devise>> findAllDevises({int page = 0}) async {
    final response = await http.get(Uri.parse('$baseUrl/devises?page=$page'));

    if (response.statusCode == 200) {
      final jsonBody = json.decode(utf8.decode(response.bodyBytes));
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

  Future<bool> updateDevise(int id, Devise dto) async {
    try {
      final url = Uri.parse('$baseUrl/devises/update/$id');
      final headers = {'Content-Type': 'application/json'};

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Échec de la mise à jour');
      }
    } catch (e) {
      rethrow;
    }
  }
}
