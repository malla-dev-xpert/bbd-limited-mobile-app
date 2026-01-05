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
      print('🔍 [LogService] Récupération des détails du log #$logId');
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
      );

      print('📡 [LogService] Réponse reçue - Status: ${response.statusCode}');
      print('📦 [LogService] Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        print('📄 [LogService] Body brut (${responseBody.length} caractères):');
        print(responseBody);

        final jsonBody = json.decode(responseBody);
        print('✅ [LogService] JSON parsé:');
        print(jsonBody);

        // Log détaillé des champs importants
        if (jsonBody is Map<String, dynamic>) {
          print('🔍 [LogService] Détails du log:');
          print('  - id: ${jsonBody['id']}');
          print('  - action: ${jsonBody['action']}');
          print('  - entityType: ${jsonBody['entityType']}');
          print('  - entityId: ${jsonBody['entityId']}');
          print('  - entityIds: ${jsonBody['entityIds']}');
          print('  - createdAt: ${jsonBody['createdAt']}');
          print('  - userId: ${jsonBody['userId']}');
          print('  - userName: ${jsonBody['userName']}');
          print('  - actorName: ${jsonBody['actorName']}');
          print('  - actorRole: ${jsonBody['actorRole']}');
          print('  - entityLabel: ${jsonBody['entityLabel']}');
          print('  - description: ${jsonBody['description']}');
          print('  - entityDetails: ${jsonBody['entityDetails']}');
          print('  - beforeState: ${jsonBody['beforeState']}');
          print('  - afterState: ${jsonBody['afterState']}');

          if (jsonBody['beforeState'] != null) {
            print('📊 [LogService] beforeState détaillé:');
            print(jsonBody['beforeState']);
          }

          if (jsonBody['afterState'] != null) {
            print('📊 [LogService] afterState détaillé:');
            print(jsonBody['afterState']);
          }

          if (jsonBody['entityDetails'] != null) {
            print('📊 [LogService] entityDetails détaillé:');
            print(jsonBody['entityDetails']);
          }
        }

        // Vérifier si c'est une erreur de sérialisation backend
        if (jsonBody is Map<String, dynamic> && jsonBody.containsKey('error')) {
          final errorMessage = jsonBody['message']?.toString() ??
              jsonBody['error']?.toString() ??
              'Erreur de sérialisation backend';
          print('❌ [LogService] Erreur backend détectée: $errorMessage');
          throw Exception('Erreur backend: $errorMessage');
        }

        final logDetail = LogDetail.fromJson(jsonBody as Map<String, dynamic>);
        print('✅ [LogService] LogDetail créé avec succès');
        return logDetail;
      } else if (response.statusCode == 404) {
        print('❌ [LogService] Log introuvable (404)');
        throw Exception('Log introuvable');
      } else {
        print('❌ [LogService] Erreur HTTP ${response.statusCode}');
        final responseBody = utf8.decode(response.bodyBytes);
        print('📄 [LogService] Body d\'erreur: $responseBody');

        // Essayer de parser le message d'erreur du backend
        try {
          final errorBody = json.decode(responseBody);
          print('📊 [LogService] Erreur parsée: $errorBody');
          if (errorBody is Map<String, dynamic> &&
              errorBody.containsKey('message')) {
            throw Exception(errorBody['message']?.toString() ??
                'Erreur lors du chargement des détails');
          }
        } catch (e) {
          print('⚠️ [LogService] Impossible de parser l\'erreur: $e');
          // Ignorer si on ne peut pas parser l'erreur
        }
        throw Exception(
            'Erreur lors du chargement des détails (${response.statusCode})');
      }
    } catch (e) {
      print(
          '💥 [LogService] Exception lors de la récupération des détails: $e');
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

      print('🔍 [LogService] Récupération de la liste des logs');
      print('📍 URL: $finalUri');
      print('📋 Paramètres: $queryParams');

      final response = await http.get(finalUri);

      print('📡 [LogService] Réponse reçue - Status: ${response.statusCode}');
      print('📦 [LogService] Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        print('📄 [LogService] Body brut (${responseBody.length} caractères)');

        final List<dynamic> jsonBody = json.decode(responseBody);
        print('✅ [LogService] JSON parsé - ${jsonBody.length} logs trouvés');

        // Log détaillé pour chaque log
        for (int i = 0; i < jsonBody.length && i < 3; i++) {
          final log = jsonBody[i];
          if (log is Map<String, dynamic>) {
            print('📊 [LogService] Log #$i:');
            print('  - id: ${log['id']}');
            print('  - action: ${log['action']}');
            print('  - entityType: ${log['entityType']}');
            print('  - entityId: ${log['entityId']}');
            print('  - entityIds: ${log['entityIds']}');
            print('  - createdAt: ${log['createdAt']}');
            print('  - userId: ${log['userId']}');
            print('  - userName: ${log['userName']}');
            print('  - actorName: ${log['actorName']}');
            print('  - actorRole: ${log['actorRole']}');
            print('  - entityLabel: ${log['entityLabel']}');
            print('  - description: ${log['description']}');
            print(
                '  - beforeState: ${log['beforeState'] != null ? "${log['beforeState'].toString().length} caractères" : "null"}');
            print(
                '  - afterState: ${log['afterState'] != null ? "${log['afterState'].toString().length} caractères" : "null"}');
            print('  - user: ${log['user']}');
          }
        }

        if (jsonBody.length > 3) {
          print('... et ${jsonBody.length - 3} autres logs');
        }

        try {
          final logs = jsonBody.map((e) {
            try {
              return ActivityLog.fromJson(e as Map<String, dynamic>);
            } catch (e) {
              print('❌ [LogService] Erreur lors du parsing d\'un log: $e');
              print('📄 [LogService] Données du log: $e');
              throw Exception('Erreur lors du parsing d\'un log: $e');
            }
          }).toList();

          print('✅ [LogService] ${logs.length} ActivityLog créés avec succès');
          return logs;
        } catch (e) {
          print('❌ [LogService] Erreur lors du parsing des logs: $e');
          throw Exception('Erreur lors du parsing des logs: $e');
        }
      } else {
        print('❌ [LogService] Erreur HTTP ${response.statusCode}');
        final responseBody = utf8.decode(response.bodyBytes);
        print('📄 [LogService] Body d\'erreur: $responseBody');
        throw Exception(
            'Erreur lors du chargement des logs (${response.statusCode})');
      }
    } catch (e) {
      print('💥 [LogService] Exception lors de la récupération des logs: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur de connexion: $e');
    }
  }
}
