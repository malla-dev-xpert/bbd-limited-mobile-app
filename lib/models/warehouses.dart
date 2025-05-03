import 'package:bbd_limited/core/enums/status.dart';

class Warehouses {
  final int id;
  final String? name;
  final String? adresse;
  final String? storageType;
  final Status? status;
  final DateTime? createdAt;
  final DateTime? editedAt;

  Warehouses copyWith({
    int? id,
    String? name,
    String? adresse,
    String? storageType,
    Status? status,
    DateTime? createdAt,
    DateTime? editedAt,
  }) {
    return Warehouses(
      id: id ?? this.id,
      name: name ?? this.name,
      adresse: adresse ?? this.adresse,
      storageType: storageType ?? this.storageType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'adresse': adresse,
      'storageType': storageType,
      'status': status?.name ?? Status.CREATE.name, // Modification ici
      'createdAt': createdAt?.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
    };
  }

  Warehouses({
    required this.id,
    this.name,
    this.adresse,
    this.storageType,
    this.status,
    this.createdAt,
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
