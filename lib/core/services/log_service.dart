import 'dart:convert';
import 'dart:developer';
import 'package:bbd_limited/models/activity_log.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LogService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  /// Récupère les logs d'activité paginés
  Future<List<ActivityLog>> getLogs({int page = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/logs?page=$page'),
      );

      log('Logs API Response: ${response.statusCode}');
      log('Logs API Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonBody = json.decode(
          utf8.decode(response.bodyBytes),
        );
        try {
          return jsonBody.map((e) {
            try {
              return ActivityLog.fromJson(e as Map<String, dynamic>);
            } catch (e) {
              throw Exception('Erreur lors du parsing d\'un log: $e');
            }
          }).toList();
        } catch (e) {
          throw Exception('Erreur lors du parsing des logs: $e');
        }
      } else {
        throw Exception(
            'Erreur lors du chargement des logs (${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur de connexion: $e');
    }
  }
}
