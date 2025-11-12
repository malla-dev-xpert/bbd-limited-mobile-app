class Country {
  final int id;
  final String name;
  final String isoCode;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final String status;

  Country({
    required this.id,
    required this.name,
    required this.isoCode,
    this.createdAt,
    this.editedAt,
    this.status = 'CREATE',
  });

  Country copyWith({
    int? id,
    String? name,
    String? isoCode,
    DateTime? createdAt,
    DateTime? editedAt,
    String? status,
  }) {
    return Country(
      id: id ?? this.id,
      name: name ?? this.name,
      isoCode: isoCode ?? this.isoCode,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      status: status ?? this.status,
    );
  }

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as int,
      name: json['name'] as String,
      isoCode: json['isoCode'] as String,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      status: json['status'] as String? ?? 'CREATE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isoCode': isoCode,
      'createdAt': createdAt?.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'status': status,
    };
  }

  @override
  String toString() {
    return name;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Country && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
