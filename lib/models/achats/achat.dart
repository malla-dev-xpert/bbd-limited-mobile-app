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
  final List<LigneAchat>? lignes;
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
    List<LigneAchat>? lignes,
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
      lignes: lignes ?? this.lignes,
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
    this.lignes,
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
      'lignes': lignes?.map((ligne) => ligne.toJson()).toList(),
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
      montantVerser:
          json['montantVerser'] != null
              ? (json['montantVerser'] as num).toDouble()
              : null,
      montantRestant:
          json['montantRestant'] != null
              ? (json['montantRestant'] as num).toDouble()
              : null,
      fournisseur: json['fournisseur'] as String?,
      fournisseurPhone: json['fournisseurPhone'] as String?,
      client: json['client'] as String?,
      clientPhone: json['clientPhone'] as String?,
      lignes:
          json['lignes'] != null
              ? (json['lignes'] as List)
                  .map((ligne) => LigneAchat.fromJson(ligne))
                  .toList()
              : null,
      status: status,
    );
  }
}

class LigneAchat {
  final int? id;
  final int? achatId;
  final int? itemId;
  final String? descriptionItem;
  final double? quantityItem;
  final double? unitPriceItem;
  final int? quantity;
  final double? prixTotal;

  LigneAchat({
    this.id,
    this.achatId,
    this.itemId,
    this.descriptionItem,
    this.quantityItem,
    this.unitPriceItem,
    this.quantity,
    this.prixTotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'achatId': achatId,
      'itemId': itemId,
      'descriptionItem': descriptionItem,
      'quantityItem': quantityItem,
      'unitPriceItem': unitPriceItem,
      'quantity': quantity,
      'prixTotal': prixTotal,
    };
  }

  factory LigneAchat.fromJson(Map<String, dynamic> json) {
    return LigneAchat(
      id: json['id'] as int?,
      achatId: json['achatId'] as int?,
      itemId: json['itemId'] as int?,
      descriptionItem: json['descriptionItem'] as String?,
      quantityItem:
          json['quantityItem'] != null
              ? (json['quantityItem'] as num).toDouble()
              : null,
      unitPriceItem:
          json['unitPriceItem'] != null
              ? (json['unitPriceItem'] as num).toDouble()
              : null,
      quantity: json['quantity'] as int?,
      prixTotal:
          json['prixTotal'] != null
              ? (json['prixTotal'] as num).toDouble()
              : null,
    );
  }
}
