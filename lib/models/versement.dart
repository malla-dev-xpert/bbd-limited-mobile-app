import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/cashWithdrawal.dart';

enum VersementType { General, Dette, Commande, CompteBancaire, Autres }

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
  List<CashWithdrawal>? cashWithdrawalDtoList;
  final String? commissionnaireName;
  final String? commissionnairePhone;
  final int? deviseId;
  final String? deviseCode;
  final String? type;
  final String? note;
  final double? tauxUtilise;

  /// Montant converti en CNY par le backend (lecture seule, jamais calculé côté Flutter).
  /// Correspond à la colonne backend montant_converti_cny / montantConvertiCNY.
  final double? montantCNY;

  /// Alias pour montantCNY (montant converti en CNY).
  double? get montantConvertiCNY => montantCNY;

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
      List<CashWithdrawal>? cashWithdrawalDtoList,
      String? commissionnaireName,
      String? commissionnairePhone,
      int? deviseId,
      String? deviseCode,
      String? type,
      String? note,
      double? tauxUtilise,
      double? montantCNY}) {
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
        cashWithdrawalDtoList:
            cashWithdrawalDtoList ?? this.cashWithdrawalDtoList,
        commissionnaireName: commissionnaireName ?? this.commissionnaireName,
        commissionnairePhone: commissionnairePhone ?? this.commissionnairePhone,
        deviseId: deviseId ?? this.deviseId,
        deviseCode: deviseCode ?? this.deviseCode,
        type: type ?? this.type,
        note: note ?? this.note,
        tauxUtilise: tauxUtilise ?? this.tauxUtilise,
        montantCNY: montantCNY ?? this.montantCNY);
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
      this.cashWithdrawalDtoList,
      this.commissionnairePhone,
      this.deviseId,
      this.deviseCode,
      this.type,
      this.note,
      this.tauxUtilise,
      this.montantCNY});

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
      'cashWithdrawalDtoList':
          cashWithdrawalDtoList?.map((item) => item.toJson()).toList(),
      'commissionnaireName': commissionnaireName,
      'commissionnairePhone': commissionnairePhone,
      'deviseId': deviseId,
      'deviseCode': deviseCode,
      'type': type,
      'note': note,
      'tauxUtilise': tauxUtilise,
      // montantCNY n'est jamais envoyé : calculé exclusivement par le backend
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

    List<CashWithdrawal> cashWithdrawalList = [];
    if (json['cashWithdrawalDtoList'] != null) {
      cashWithdrawalList = (json['cashWithdrawalDtoList'] as List)
          .map((cashWithdrawal) => CashWithdrawal.fromJson(cashWithdrawal))
          .toList();
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
        cashWithdrawalDtoList: cashWithdrawalList,
        commissionnaireName: json['commissionnaireName'] as String?,
        commissionnairePhone: json['commissionnairePhone'] as String?,
        deviseId: json['deviseId'] as int?,
        deviseCode: json['deviseCode'] as String?,
        type: json['type'] as String?,
        note: json['note'] as String?,
        tauxUtilise: json['tauxUtilise'] != null
            ? (json['tauxUtilise'] as num).toDouble()
            : null,
        montantCNY: _parseMontantConvertiCNY(json));
  }

  /// Lit le montant converti en CNY (backend peut envoyer montantConvertiCNY ou montantCNY).
  static double? _parseMontantConvertiCNY(Map<String, dynamic> json) {
    final value = json['montantConvertiCNY'] ?? json['montantCNY'];
    return value != null ? (value as num).toDouble() : null;
  }
}
