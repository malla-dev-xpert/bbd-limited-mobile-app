import 'dart:convert';
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

  /// Récupère les logs d'activité paginés avec filtres optionnels
  Future<List<ActivityLog>> getLogs({
    int page = 0,
    int? userId,
    DateTime? dateStart,
    DateTime? dateEnd,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
      };

      if (userId != null) {
        queryParams['userId'] = userId.toString();
      }

      if (dateStart != null) {
        // Format ISO DATE_TIME: yyyy-MM-ddTHH:mm:ss
        // Le backend attend DateTimeFormat.ISO.DATE_TIME (LocalDateTime sans timezone)
        // Format manuel pour correspondre exactement au format attendu
        final formatted = '${dateStart.year.toString().padLeft(4, '0')}-'
            '${dateStart.month.toString().padLeft(2, '0')}-'
            '${dateStart.day.toString().padLeft(2, '0')}T'
            '${dateStart.hour.toString().padLeft(2, '0')}:'
            '${dateStart.minute.toString().padLeft(2, '0')}:'
            '${dateStart.second.toString().padLeft(2, '0')}';
        queryParams['dateStart'] = formatted;
      }

      if (dateEnd != null) {
        // Format ISO DATE_TIME: yyyy-MM-ddTHH:mm:ss
        // Le backend attend DateTimeFormat.ISO.DATE_TIME (LocalDateTime sans timezone)
        // Format manuel pour correspondre exactement au format attendu
        final formatted = '${dateEnd.year.toString().padLeft(4, '0')}-'
            '${dateEnd.month.toString().padLeft(2, '0')}-'
            '${dateEnd.day.toString().padLeft(2, '0')}T'
            '${dateEnd.hour.toString().padLeft(2, '0')}:'
            '${dateEnd.minute.toString().padLeft(2, '0')}:'
            '${dateEnd.second.toString().padLeft(2, '0')}';
        queryParams['dateEnd'] = formatted;
      }

      final finalUri =
          Uri.parse('$baseUrl/logs').replace(queryParameters: queryParams);

      final response = await http.get(finalUri);

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
