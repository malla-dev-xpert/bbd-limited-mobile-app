import 'package:bbd_limited/core/enums/status.dart';

class Warehouses {
  final int id;
  final String? name;
  final String? adresse;
  final String? storageType;
  final Status status;
  final DateTime createdAt;
  final DateTime? editedAt;

  Warehouses({
    required this.id,
    this.name,
    this.adresse,
    this.storageType,
    required this.status,
    required this.createdAt,
    this.editedAt,
  });

  factory Warehouses.fromJson(Map<String, dynamic> json) {
    return Warehouses(
      id: json['id'],
      name: json['name'],
      adresse: json['adresse'],
      storageType: json['storageType'],
      status: Status.values.firstWhere(
        (statut) => statut.name == json['status'],
        orElse: () => Status.CREATE,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
    );
  }
}
