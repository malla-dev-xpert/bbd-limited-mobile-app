class CbmPricing {
  final int? id;
  final double cbmValue;
  final double price;
  final String? currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CbmPricing({
    this.id,
    required this.cbmValue,
    required this.price,
    this.currency,
    this.createdAt,
    this.updatedAt,
  });

  CbmPricing copyWith({
    int? id,
    double? cbmValue,
    double? price,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CbmPricing(
      id: id ?? this.id,
      cbmValue: cbmValue ?? this.cbmValue,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'cbmValue': cbmValue,
      'price': price,
      'currency': currency,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory CbmPricing.fromJson(Map<String, dynamic> json) {
    return CbmPricing(
      id: json['id'],
      cbmValue: (json['cbmValue'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}
