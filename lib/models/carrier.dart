import 'dart:developer';

class Carrier {
  final int? id;
  final String? name;
  final String? contact;
  final List<String>? services;
  final DateTime? createdAt;
  final DateTime? editedAt;

  Carrier({
    this.id,
    this.name,
    this.contact,
    this.services,
    this.createdAt,
    this.editedAt,
  });

  factory Carrier.fromJson(Map<String, dynamic> json) {
    try {
      // Le backend peut renvoyer 'carrierService' ou 'services'
      final rawServices = (json['carrierService'] as List<dynamic>?) ??
          (json['services'] as List<dynamic>?) ??
          [];

      // Chaque élément peut être un objet {id, name, ...} ou une simple String
      final List<String> parsedServices = rawServices.map((e) {
        if (e is Map<String, dynamic>) {
          return (e['name'] as String?) ?? e.toString();
        }
        return e.toString();
      }).toList();

      return Carrier(
        id: json['id'] is num ? (json['id'] as num).toInt() : null,
        name: json['name'] as String?,
        contact: json['contact'] as String?,
        services: parsedServices,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        editedAt: json['editedAt'] != null
            ? DateTime.tryParse(json['editedAt'].toString())
            : null,
      );
    } catch (e, stack) {
      log('Carrier.fromJson error: $e\n$stack');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'carrierService': services,
      'createdAt': createdAt?.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
    };
  }
}

class CarrierDto {
  final String? name;
  final String? contact;
  final List<String>? services;

  CarrierDto({
    this.name,
    this.contact,
    this.services,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'contact': contact,
      'carrierService': services,
    };
  }
}
