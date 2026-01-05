import 'dart:convert';

class LogDetail {
  final int id;
  final String action;
  final String entityType;
  final int? entityId;
  final List<int>? entityIds;
  final DateTime createdAt;
  final int? userId;
  final String? userName;
  final String? actorName;
  final String? actorRole;
  final String? entityLabel;
  final String? description;
  final Map<String, dynamic>? entityDetails;
  final String? beforeState; // JSON string
  final String? afterState; // JSON string

  LogDetail({
    required this.id,
    required this.action,
    required this.entityType,
    this.entityId,
    this.entityIds,
    required this.createdAt,
    this.userId,
    this.userName,
    this.actorName,
    this.actorRole,
    this.entityLabel,
    this.description,
    this.entityDetails,
    this.beforeState,
    this.afterState,
  });

  factory LogDetail.fromJson(Map<String, dynamic> json) {
    // Gérer entityIds
    List<int>? entityIdsList;
    if (json['entityIds'] != null && json['entityIds'] is List) {
      final entityIds = json['entityIds'] as List;
      if (entityIds.isNotEmpty) {
        entityIdsList = entityIds
            .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0)
            .toList();
        entityIdsList = entityIdsList.isEmpty ? null : entityIdsList;
      }
    }

    // Gérer entityDetails
    Map<String, dynamic>? entityDetailsMap;
    if (json['entityDetails'] != null && json['entityDetails'] is Map) {
      entityDetailsMap =
          Map<String, dynamic>.from(json['entityDetails'] as Map);
    }

    // Gérer beforeState (JSON string depuis le backend)
    String? beforeStateStr;
    if (json['beforeState'] != null) {
      if (json['beforeState'] is String) {
        beforeStateStr = json['beforeState'] as String;
      } else if (json['beforeState'] is Map) {
        // Fallback: si le backend envoie encore un Map, le convertir en JSON string
        beforeStateStr = jsonEncode(json['beforeState']);
      }
    }
    // Support rétro-compatibilité : initialState (ancien format)
    if (beforeStateStr == null && json['initialState'] != null) {
      if (json['initialState'] is String) {
        beforeStateStr = json['initialState'] as String;
      } else if (json['initialState'] is Map) {
        beforeStateStr = jsonEncode(json['initialState']);
      }
    }

    // Gérer afterState (JSON string depuis le backend)
    String? afterStateStr;
    if (json['afterState'] != null) {
      if (json['afterState'] is String) {
        afterStateStr = json['afterState'] as String;
      } else if (json['afterState'] is Map) {
        // Fallback: si le backend envoie encore un Map, le convertir en JSON string
        afterStateStr = jsonEncode(json['afterState']);
      }
    }
    // Support rétro-compatibilité : finalState (ancien format)
    if (afterStateStr == null && json['finalState'] != null) {
      if (json['finalState'] is String) {
        afterStateStr = json['finalState'] as String;
      } else if (json['finalState'] is Map) {
        afterStateStr = jsonEncode(json['finalState']);
      }
    }

    int parseId(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return int.tryParse(value?.toString() ?? '0') ?? 0;
    }

    int? parseNullableId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return int.tryParse(value.toString());
    }

    return LogDetail(
      id: parseId(json['id']),
      action: json['action']?.toString() ?? '',
      entityType: json['entityType']?.toString() ?? '',
      entityId: parseNullableId(json['entityId']),
      entityIds: entityIdsList,
      createdAt: _parseDateTime(json['createdAt']),
      userId: parseNullableId(json['userId']),
      userName: json['userName']?.toString(),
      actorName: json['actorName']?.toString(),
      actorRole: json['actorRole']?.toString(),
      entityLabel: json['entityLabel']?.toString(),
      description: json['description']?.toString(),
      entityDetails: entityDetailsMap,
      beforeState: beforeStateStr,
      afterState: afterStateStr,
    );
  }

  /// Parse une date depuis JSON de manière robuste
  /// Gère différents formats et les erreurs de sérialisation backend
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    // Si c'est déjà un DateTime (peu probable mais possible)
    if (value is DateTime) return value;

    // Si c'est une String, essayer de la parser
    if (value is String) {
      // Essayer le format ISO 8601 standard
      try {
        return DateTime.parse(value);
      } catch (e) {
        // Essayer le format sans timezone (LocalDateTime)
        // Format: "2024-01-15T10:30:00" ou "2024-01-15 10:30:00"
        try {
          final cleaned = value.replaceAll(' ', 'T');
          if (!cleaned.contains('Z') &&
              !cleaned.contains('+') &&
              !cleaned.contains('-', 10)) {
            // Format LocalDateTime sans timezone
            return DateTime.parse('${cleaned}Z');
          }
          return DateTime.parse(cleaned);
        } catch (e2) {
          // Si tout échoue, retourner la date actuelle
          return DateTime.now();
        }
      }
    }

    // Si c'est un nombre (timestamp en millisecondes ou secondes)
    if (value is num) {
      final timestamp = value.toInt();
      // Si c'est en secondes (timestamp < 1e12), convertir en millisecondes
      if (timestamp < 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    // Fallback
    return DateTime.now();
  }

  /// Getter de compatibilité : parse beforeState (JSON string) en Map
  /// Utilisé pour la compatibilité avec le code existant qui attend initialState comme Map
  Map<String, dynamic>? get initialState {
    if (beforeState == null || beforeState!.isEmpty) return null;
    try {
      return jsonDecode(beforeState!) as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Getter de compatibilité : parse afterState (JSON string) en Map
  /// Utilisé pour la compatibilité avec le code existant qui attend finalState comme Map
  Map<String, dynamic>? get finalState {
    if (afterState == null || afterState!.isEmpty) return null;
    try {
      return jsonDecode(afterState!) as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'entityIds': entityIds,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'actorName': actorName,
      'actorRole': actorRole,
      'entityLabel': entityLabel,
      'description': description,
      'entityDetails': entityDetails,
      'beforeState': beforeState,
      'afterState': afterState,
    };
  }
}
