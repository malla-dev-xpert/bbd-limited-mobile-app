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
  final String? partnerAccountType;
  final int? partnerId;
  List<Achat>? achats;
  final String? commissionnaireName;
  final String? commissionnairePhone;
  final int? deviseId;
  final String? deviseCode;

  Versement copyWith(
      {int? id,
      String? reference,
      double? montantVerser,
      double? montantRestant,
      Status? status,
      DateTime? createdAt,
      DateTime? editedAt,
      String? partnerName,
      String? partnerPhone,
      String? partnerAccountType,
      int? partnerId,
      List<Achat>? achats,
      String? commissionnaireName,
      String? commissionnairePhone,
      int? deviseId,
      String? deviseCode}) {
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
        partnerAccountType: partnerAccountType ?? this.partnerAccountType,
        partnerId: partnerId ?? this.partnerId,
        achats: achats ?? this.achats,
        commissionnaireName: commissionnaireName ?? this.commissionnaireName,
        commissionnairePhone: commissionnairePhone ?? this.commissionnairePhone,
        deviseId: deviseId ?? this.deviseId,
        deviseCode: deviseCode ?? this.deviseCode);
  }

  Versement(
      {this.id,
      this.reference,
      this.montantVerser,
      this.montantRestant,
      this.status,
      this.createdAt,
      this.editedAt,
      this.partnerName,
      this.partnerPhone,
      this.partnerAccountType,
      this.partnerId,
      this.achats,
      this.commissionnaireName,
      this.commissionnairePhone,
      this.deviseId,
      this.deviseCode});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'montantVerser': montantVerser,
      'montantRestant': montantRestant,
      'status': status?.name ?? Status.CREATE.name,
      'createdAt': createdAt?.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'partnerName': partnerName,
      'partnerPhone': partnerPhone,
      'partnerAccountType': partnerAccountType,
      'partnerId': partnerId,
      'achats': achats?.map((item) => item.toJson()).toList(),
      'commissionnaireName': commissionnaireName,
      'commissionnairePhone': commissionnairePhone,
      'deviseId': deviseId,
      'deviseCode': deviseCode
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
      achatList = (json['achats'] as List)
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
        montantVerser: json['montantVerser'] != null
            ? (json['montantVerser'] as num).toDouble()
            : null,
        montantRestant: json['montantRestant'] != null
            ? (json['montantRestant'] as num).toDouble()
            : null,
        status: status,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        editedAt:
            json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
        partnerName: json['partnerName'] as String?,
        partnerPhone: json['partnerPhone'] as String?,
        partnerAccountType: json['partnerAccountType'] as String?,
        partnerId: json['partnerId'] as int?,
        achats: achatList,
        commissionnaireName: json['commissionnaireName'] as String?,
        commissionnairePhone: json['commissionnairePhone'] as String?,
        deviseId: json['deviseId'] as int?,
        deviseCode: json['deviseCode'] as String?);
  }
}
