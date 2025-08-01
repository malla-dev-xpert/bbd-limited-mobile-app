import 'package:bbd_limited/core/enums/status.dart';

class Achat {
  final int? id;
  final String? referenceVersement;
  final String? client;
  final String? clientPhone;
  final List<Items>? items;
  final double? montantTotal;
  final DateTime? createdAt;
  final bool? isDebt;
  final int? clientId;
  Status? status;

  Achat copyWith({
    int? id,
    String? referenceVersement,
    String? client,
    String? clientPhone,
    List<Items>? items,
    double? montantTotal,
    DateTime? createdAt,
    bool? isDebt,
    int? clientId,
    Status? status,
  }) {
    return Achat(
      id: id ?? this.id,
      referenceVersement: referenceVersement ?? this.referenceVersement,
      client: client ?? this.client,
      clientPhone: clientPhone ?? this.clientPhone,
      items: items ?? this.items,
      montantTotal: montantTotal ?? this.montantTotal,
      createdAt: createdAt ?? this.createdAt,
      isDebt: isDebt ?? this.isDebt,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
    );
  }

  Achat({
    this.id,
    this.referenceVersement,
    this.client,
    this.clientPhone,
    this.items,
    this.montantTotal,
    this.createdAt,
    this.isDebt,
    this.clientId,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referenceVersement': referenceVersement,
      'client': client,
      'clientPhone': clientPhone,
      'items': items?.map((ligne) => ligne.toJson()).toList(),
      'montantTotal': montantTotal,
      'createdAt': createdAt,
      'isDebt': isDebt,
      'clientId': clientId,
      'status': status?.name,
    };
  }

  factory Achat.fromJson(Map<String, dynamic> json) {
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

    return Achat(
      id: json['id'] as int?,
      referenceVersement: json['referenceVersement'] as String?,
      client: json['client'] as String?,
      clientPhone: json['clientPhone'] as String?,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((ligne) => Items.fromJson(ligne))
              .toList()
          : null,
      montantTotal: json['montantTotal'] != null
          ? (json['montantTotal'] as num).toDouble()
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      isDebt: json['isDebt'] as bool?,
      clientId: json['clientId'] as int?,
      status: status,
    );
  }
}

class Items {
  final int? id;
  final String? description;
  final int? quantity;
  final double? unitPrice;
  final double? totalPrice;
  final int? supplierId;
  final String? supplierName;
  final int? packageId;
  final String? supplierPhone;
  final double? salesRate;
  final String? invoiceNumber;
  Status? status;

  Items({
    this.id,
    this.description,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
    this.supplierId,
    this.supplierName,
    this.supplierPhone,
    this.packageId,
    this.salesRate,
    this.invoiceNumber,
    this.status,
  });

  Items copyWith({
    int? id,
    String? description,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    int? supplierId,
    String? supplierName,
    String? supplierPhone,
    int? packageId,
    double? salesRate,
    String? invoiceNumber,
    Status? status,
  }) {
    return Items(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierPhone: supplierPhone ?? this.supplierPhone,
      packageId: packageId ?? this.packageId,
      salesRate: salesRate ?? this.salesRate,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'description': description,
      'quantity': quantity,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'supplierPhone': supplierPhone,
      'packageId': packageId,
      'salesRate': salesRate,
      'invoiceNumber': invoiceNumber,
      'status': status?.name,
    };
  }

  factory Items.fromJson(Map<String, dynamic> json) {
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

    return Items(
      id: json['id'] as int?,
      quantity: json['quantity'] as int?,
      description: json['description'] as String?,
      unitPrice: json['unitPrice'] != null
          ? (json['unitPrice'] as num).toDouble()
          : null,
      totalPrice: json['totalPrice'] != null
          ? (json['totalPrice'] as num).toDouble()
          : null,
      supplierId: json['supplierId'] as int?,
      supplierName: json['supplierName'] as String?,
      supplierPhone: json['supplierPhone'] as String?,
      packageId: json['packageId'] as int?,
      salesRate: json['salesRate'] != null
          ? (json['salesRate'] as num).toDouble()
          : null,
      invoiceNumber: json['invoiceNumber'] as String?,
      status: status,
    );
  }
}
