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
      final url = '$baseUrl/logs/$logId';

      final response = await http.get(
        Uri.parse(url),
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);

        final jsonBody = json.decode(responseBody);

        // Vérifier si c'est une erreur de sérialisation backend
        if (jsonBody is Map<String, dynamic> && jsonBody.containsKey('error')) {
          final errorMessage = jsonBody['message']?.toString() ??
              jsonBody['error']?.toString() ??
              'Erreur de sérialisation backend';
          throw Exception('Erreur backend: $errorMessage');
        }

        final logDetail = LogDetail.fromJson(jsonBody as Map<String, dynamic>);
        return logDetail;
      } else if (response.statusCode == 404) {
        throw Exception('Log introuvable');
      } else {
        final responseBody = utf8.decode(response.bodyBytes);

        // Essayer de parser le message d'erreur du backend
        try {
          final errorBody = json.decode(responseBody);
          if (errorBody is Map<String, dynamic> &&
              errorBody.containsKey('message')) {
            throw Exception(errorBody['message']?.toString() ??
                'Erreur lors du chargement des détails');
          }
        } catch (e) {
          // Ignorer si on ne peut pas parser l'erreur
        }
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
    String? entityType,
    String? action,
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

      if (entityType != null && entityType.isNotEmpty) {
        queryParams['entityType'] = entityType;
      }

      if (action != null && action.isNotEmpty) {
        queryParams['action'] = action;
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
        final responseBody = utf8.decode(response.bodyBytes);

        final List<dynamic> jsonBody = json.decode(responseBody);

        try {
          final logs = jsonBody.map((e) {
            try {
              return ActivityLog.fromJson(e as Map<String, dynamic>);
            } catch (e) {
              throw Exception('Erreur lors du parsing d\'un log: $e');
            }
          }).toList();

          return logs;
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
