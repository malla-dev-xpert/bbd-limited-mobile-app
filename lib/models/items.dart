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
  final int? supplierId;
  final String? supplierName;
  final String? supplierPhone;
  final String? invoiceNumber;
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
    this.supplierId,
    this.supplierName,
    this.supplierPhone,
    this.invoiceNumber,
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
    int? supplierId,
    String? supplierName,
    String? supplierPhone,
    String? invoiceNumber,
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
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierPhone: supplierPhone ?? this.supplierPhone,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
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
      supplierId: json['supplierId'],
      supplierName: json['supplierName'],
      supplierPhone: json['supplierPhone'],
      invoiceNumber: json['invoiceNumber'],
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
      'supplierId': supplierId,
      'supplierName': supplierName,
      'supplierPhone': supplierPhone,
      'invoiceNumber': invoiceNumber,
      'status': status.name,
    };
  }
}
