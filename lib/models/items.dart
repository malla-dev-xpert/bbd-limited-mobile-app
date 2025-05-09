import 'package:bbd_limited/core/enums/status.dart';

class Item {
  final int id;
  final String description;
  final double quantity;
  final double unitPrice;
  final DateTime? achatDate;
  final int? clientId;
  final String? clientName;
  final String? clientPhone;
  Status status;

  Item({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.achatDate,
    this.clientId,
    this.clientName,
    this.clientPhone,
    required this.status,
  });

  Item copyWith({
    int? id,
    String? description,
    double? quantity,
    double? unitPrice,
    DateTime? achatDate,
    int? clientId,
    String? clientName,
    String? clientPhone,
    Status? status,
  }) {
    return Item(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      achatDate: achatDate ?? this.achatDate,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      status: status ?? this.status,
    );
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    String? statusString = json['status'];
    Status status;

    if (statusString != null) {
      status = Status.values.firstWhere(
        (e) => e.name.toUpperCase() == statusString.toUpperCase(),
        orElse: () => Status.CREATE,
      );
    } else {
      status = Status.CREATE;
    }

    return Item(
      id: json['id'],
      description: json['description'],
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      achatDate:
          json['achatDate'] != null ? DateTime.parse(json['achatDate']) : null,
      clientId: json['clientId'],
      clientName: json['clientName'],
      clientPhone: json['clientPhone'],
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'achatDate': achatDate?.toIso8601String(),
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'status': status.name,
    };
  }
}
