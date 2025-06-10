import 'package:bbd_limited/core/enums/status.dart';

class Achat {
  final int? id;
  final String? referenceVersement;
  final double? montantVerser;
  final double? montantRestant;
  final String? fournisseur;
  final String? fournisseurPhone;
  final String? client;
  final String? clientPhone;
  final List<Items>? items;
  final String? invoiceNumber;
  Status? status;

  Achat copyWith({
    int? id,
    String? referenceVersement,
    double? montantVerser,
    double? montantRestant,
    String? fournisseur,
    String? fournisseurPhone,
    String? client,
    String? clientPhone,
    List<Items>? items,
    String? invoiceNumber,
    Status? status,
  }) {
    return Achat(
      id: id ?? this.id,
      referenceVersement: referenceVersement ?? this.referenceVersement,
      montantVerser: montantVerser ?? this.montantVerser,
      montantRestant: montantRestant ?? this.montantRestant,
      fournisseur: fournisseur ?? this.fournisseur,
      fournisseurPhone: fournisseurPhone ?? this.fournisseurPhone,
      client: client ?? this.client,
      clientPhone: clientPhone ?? this.clientPhone,
      items: items ?? this.items,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      status: status ?? this.status,
    );
  }

  Achat({
    this.id,
    this.referenceVersement,
    this.montantVerser,
    this.montantRestant,
    this.fournisseur,
    this.fournisseurPhone,
    this.client,
    this.clientPhone,
    this.items,
    this.invoiceNumber,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referenceVersement': referenceVersement,
      'montantVerser': montantVerser,
      'montantRestant': montantRestant,
      'fournisseur': fournisseur,
      'fournisseurPhone': fournisseurPhone,
      'client': client,
      'clientPhone': clientPhone,
      'items': items?.map((ligne) => ligne.toJson()).toList(),
      'invoiceNumber': invoiceNumber,
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
      fournisseur: json['fournisseur'] as String?,
      fournisseurPhone: json['fournisseurPhone'] as String?,
      client: json['client'] as String?,
      clientPhone: json['clientPhone'] as String?,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((ligne) => Items.fromJson(ligne))
              .toList()
          : null,
      invoiceNumber: json['invoiceNumber'] as String?,
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

  Items({
    this.id,
    this.description,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'description': description,
      'quantity': quantity,
    };
  }

  factory Items.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
