import 'package:bbd_limited/core/enums/status.dart';

class Devise {
  final int? id;
  final String name;
  final String code;
  final Status? status;
  final DateTime? createdAt;
  final DateTime? editedAt;

  Devise copyWith({
    int? id,
    String? name,
    String? code,
    Status? status,
    DateTime? createdAt,
    DateTime? editedAt,
  }) {
    return Devise(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'status': status?.name,
      'createdAt': createdAt?.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
    };
  }

  Devise({
    this.id,
    required this.name,
    required this.code,
    this.status,
    this.createdAt,
    this.editedAt,
  });

  factory Devise.fromJson(Map<String, dynamic> json) {
    return Devise(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      status: Status.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => Status.CREATE,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
    );
  }
}
