class LogDetail {
  final int id;
  final String action;
  final String entityType;
  final int? entityId;
  final List<int>? entityIds;
  final DateTime createdAt;
  final int? userId;
  final String? userName;
  final Map<String, dynamic>? entityDetails;
  final Map<String, dynamic>? initialState;
  final Map<String, dynamic>? finalState;

  LogDetail({
    required this.id,
    required this.action,
    required this.entityType,
    this.entityId,
    this.entityIds,
    required this.createdAt,
    this.userId,
    this.userName,
    this.entityDetails,
    this.initialState,
    this.finalState,
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

    // Gérer initialState (nouveau champ backend)
    Map<String, dynamic>? initialStateMap;
    if (json['initialState'] != null && json['initialState'] is Map) {
      initialStateMap = Map<String, dynamic>.from(json['initialState'] as Map);
    }

    // Gérer finalState (nouveau champ backend)
    Map<String, dynamic>? finalStateMap;
    if (json['finalState'] != null && json['finalState'] is Map) {
      finalStateMap = Map<String, dynamic>.from(json['finalState'] as Map);
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
      entityDetails: entityDetailsMap,
      initialState: initialStateMap,
      finalState: finalStateMap,
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
      'entityDetails': entityDetails,
      'initialState': initialState,
      'finalState': finalState,
    };
  }
}
