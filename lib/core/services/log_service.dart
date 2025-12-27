import 'dart:convert';
import 'dart:developer';
import 'package:bbd_limited/models/activity_log.dart';
import 'package:bbd_limited/models/log_detail.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LogService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  /// Récupère les détails d'un log spécifique
  Future<LogDetail> getLogDetails(int logId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/logs/$logId'),
      );

      log('Log Details API Response: ${response.statusCode}');
      log('Log Details API Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonBody = json.decode(utf8.decode(response.bodyBytes));
        return LogDetail.fromJson(jsonBody as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        throw Exception('Log introuvable');
      } else {
        throw Exception(
            'Erreur lors du chargement des détails (${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les logs d'activité paginés
  Future<List<ActivityLog>> getLogs({int page = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/logs?page=$page'),
      );

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
