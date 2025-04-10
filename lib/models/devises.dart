import 'package:bbd_limited/core/enums/status.dart';

class Devise {
  final int id;
  final String name;
  final double rate;
  final String code;
  final Status status;
  final DateTime createdAt;
  final DateTime? editedAt;

  Devise({
    required this.id,
    required this.name,
    required this.rate,
    required this.code,
    required this.status,
    required this.createdAt,
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
