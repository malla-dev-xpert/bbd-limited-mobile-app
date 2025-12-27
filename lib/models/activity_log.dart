class ActivityLog {
  final int id;
  final String actionCode;
  final String entityType;
  final int? entityId;
  final List<int>? entityIds;
  final DateTime createdAt;
  final ActivityLogUser user;

  ActivityLog({
    required this.id,
    required this.actionCode,
    required this.entityType,
    this.entityId,
    this.entityIds,
    required this.createdAt,
    required this.user,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    // L'API retourne 'action' et non 'actionCode' (selon le DTO backend)
    final actionCode =
        json['action']?.toString() ?? json['actionCode']?.toString() ?? '';

    // Gérer l'objet user : soit un objet user complet (relation ManyToOne),
    // soit userId/userName séparés (DTO de réponse simplifié)
    ActivityLogUser user;
    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      // Cas 1: Objet user complet (relation ManyToOne sérialisée)
      user = ActivityLogUser.fromJson(json['user'] as Map<String, dynamic>);
    } else {
      // Cas 2: userId et userName séparés (DTO de réponse simplifié)
      final userId = json['userId'] is int
          ? json['userId'] as int
          : int.tryParse(json['userId']?.toString() ?? '0') ?? 0;
      final userName = json['userName']?.toString() ?? '';

      user = ActivityLogUser(
        id: userId,
        username: userName.isNotEmpty ? userName : null,
      );
    }

    // Gérer entityIds : peut être null, vide, ou contenir des valeurs
    // Le backend utilise List<Long> qui peut être vide
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

    // Gérer les types Long du backend (peuvent être int ou String en JSON)
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

    return ActivityLog(
      id: parseId(json['id']),
      actionCode: actionCode,
      entityType: json['entityType']?.toString() ?? '',
      entityId: parseNullableId(json['entityId']),
      entityIds: entityIdsList,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      user: user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionCode': actionCode,
      'entityType': entityType,
      'entityId': entityId,
      'entityIds': entityIds,
      'createdAt': createdAt.toIso8601String(),
      'user': user.toJson(),
    };
  }

  /// Retourne true si l'action concerne plusieurs entités
  bool get isBulkAction => entityIds != null && entityIds!.length > 1;

  /// Retourne le nombre d'entités concernées
  int get entityCount {
    if (isBulkAction) {
      return entityIds!.length;
    }
    return entityId != null ? 1 : 0;
  }
}

class ActivityLogUser {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? username;

  ActivityLogUser({
    required this.id,
    this.firstName,
    this.lastName,
    this.username,
  });

  factory ActivityLogUser.fromJson(Map<String, dynamic> json) {
    return ActivityLogUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      username: json['username']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
    };
  }

  /// Retourne le nom complet ou le username
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    } else if (username != null && username!.isNotEmpty) {
      return username!;
    }
    return 'Utilisateur inconnu';
  }
}
