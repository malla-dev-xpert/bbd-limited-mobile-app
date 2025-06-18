import 'package:bbd_limited/core/enums/status.dart';

class Achat {
  final int? id;
  final String? referenceVersement;
  final double? montantVerser;
  final double? montantRestant;
  final String? client;
  final String? clientPhone;
  final List<Items>? items;
  Status? status;

  Achat copyWith({
    int? id,
    String? referenceVersement,
    double? montantVerser,
    double? montantRestant,
    String? client,
    String? clientPhone,
    List<Items>? items,
    Status? status,
  }) {
    return Achat(
      id: id ?? this.id,
      referenceVersement: referenceVersement ?? this.referenceVersement,
      montantVerser: montantVerser ?? this.montantVerser,
      montantRestant: montantRestant ?? this.montantRestant,
      client: client ?? this.client,
      clientPhone: clientPhone ?? this.clientPhone,
      items: items ?? this.items,
      status: status ?? this.status,
    );
  }

  Achat({
    this.id,
    this.referenceVersement,
    this.montantVerser,
    this.montantRestant,
    this.client,
    this.clientPhone,
    this.items,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referenceVersement': referenceVersement,
      'montantVerser': montantVerser,
      'montantRestant': montantRestant,
      'client': client,
      'clientPhone': clientPhone,
      'items': items?.map((ligne) => ligne.toJson()).toList(),
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
      montantVerser: json['montantVerser'] != null
          ? (json['montantVerser'] as num).toDouble()
          : null,
      montantRestant: json['montantRestant'] != null
          ? (json['montantRestant'] as num).toDouble()
          : null,
      client: json['client'] as String?,
      clientPhone: json['clientPhone'] as String?,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((ligne) => Items.fromJson(ligne))
              .toList()
          : null,
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
  final String? supplierPhone;
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
    this.status,
  });

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
      status: status,
    );
  }
}
