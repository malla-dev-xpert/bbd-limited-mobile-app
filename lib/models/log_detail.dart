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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      userId: parseNullableId(json['userId']),
      userName: json['userName']?.toString(),
      entityDetails: entityDetailsMap,
    );
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
    };
  }
}
