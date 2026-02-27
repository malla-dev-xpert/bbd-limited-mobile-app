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
    return Carrier(
      id: json['id'] as int?,
      name: json['name'] as String?,
      contact: json['contact'] as String?,
      services: (json['services'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'services': services,
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
      'services': services,
    };
  }
}
