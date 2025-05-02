import 'package:bbd_limited/core/enums/status.dart';

class Devise {
  final int? id;
  final String name;
  final double rate;
  final String code;
  final Status? status;
  final DateTime? createdAt;
  final DateTime? editedAt;

  Devise copyWith({
    int? id,
    String? name,
    double? rate,
    String? code,
    Status? status,
    DateTime? createdAt,
    DateTime? editedAt,
  }) {
    return Devise(
      id: id ?? this.id,
      name: name ?? this.name,
      rate: rate ?? this.rate,
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
      'rate': rate,
      'code': code,
      'status': status?.name,
      'createdAt': createdAt?.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
    };
  }

  Devise({
    this.id,
    required this.name,
    required this.rate,
    required this.code,
    this.status,
    this.createdAt,
    this.editedAt,
  });

  factory Devise.fromJson(Map<String, dynamic> json) {
    return Devise(
      id: json['id'],
      name: json['name'],
      rate: (json['rate'] as num).toDouble(),
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
