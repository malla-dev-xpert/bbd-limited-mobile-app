import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/models/achats/achat.dart';

class Versement {
  final int? id;
  final String? reference;
  final double? montantVerser;
  final double? montantRestant;
  Status? status;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final String? partnerName;
  final String? partnerPhone;
  List<Achat>? achats;

  Versement copyWith({
    int? id,
    String? reference,
    double? montantVerser,
    double? montantRestant,
    Status? status,
    DateTime? createdAt,
    DateTime? editedAt,
    String? partnerName,
    String? partnerPhone,
    List<Achat>? achats,
  }) {
    return Versement(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      montantVerser: montantVerser ?? this.montantVerser,
      montantRestant: montantRestant ?? this.montantRestant,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      partnerName: partnerName ?? this.partnerName,
      partnerPhone: partnerPhone ?? this.partnerPhone,
      achats: achats ?? this.achats,
    );
  }

  Versement({
    this.id,
    this.reference,
    this.montantVerser,
    this.montantRestant,
    this.status,
    this.createdAt,
    this.editedAt,
    this.partnerName,
    this.partnerPhone,
    this.achats,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'montantVerser': montantVerser,
      'montantRestant': montantRestant,
      'status': status!.name,
      'createdAt': createdAt?.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'partnerName': partnerName,
      'partnerPhone': partnerPhone,
      'achats': achats?.map((item) => item.toJson()).toList(),
    };
  }

  factory Versement.fromJson(Map<String, dynamic> json) {
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

    List<Achat> achatList = [];
    if (json['achats'] != null) {
      achatList =
          (json['achats'] as List)
              .map((achat) => Achat.fromJson(achat))
              .toList();
    }

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      return int.tryParse(value.toString());
    }

    return Versement(
      id: json['id'] as int?,
      reference: json['reference'] as String?,
      montantVerser:
          json['montantVerser'] != null
              ? (json['montantVerser'] as num).toDouble()
              : null,
      montantRestant:
          json['montantRestant'] != null
              ? (json['montantRestant'] as num).toDouble()
              : null,
      status: status,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      partnerName: json['partnerName'] as String?,
      partnerPhone: json['partnerPhone'] as String?,
      achats: achatList,
    );
  }
}
