import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/models/devises.dart';
import 'package:bbd_limited/models/user.dart';
import 'package:bbd_limited/core/enums/status.dart';

class CashWithdrawal {
  final int? id;
  final double montant;
  final DateTime? dateRetrait;
  final String? note;
  final Partner partner;
  final String? userName;
  final Versement versement;
  final Devise devise;
  final User user;
  final Status status;

  CashWithdrawal({
    this.id,
    required this.montant,
    this.dateRetrait,
    this.note,
    required this.partner,
    this.userName,
    required this.versement,
    required this.devise,
    required this.user,
    required this.status,
  });

  factory CashWithdrawal.fromJson(Map<String, dynamic> json) {
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

    Partner partner;
    if (json['partner'] != null) {
      partner = Partner.fromJson(json['partner']);
    } else {
      partner = Partner(
        id: json['partnerId'] ?? 0,
        firstName: '',
        lastName: '',
        phoneNumber: '',
        email: '',
        country: '',
        adresse: '',
        accountType: json['partnerAccountType'] ?? '',
      );
    }

    Versement versement;
    if (json['versement'] != null) {
      versement = Versement.fromJson(json['versement']);
    } else {
      versement = Versement(
        id: json['versementId'],
        reference: '',
        montantVerser: null,
        montantRestant: null,
        status: Status.CREATE,
        createdAt: null,
        partnerId: json['partnerId'],
        deviseId: json['deviseId'],
      );
    }

    Devise devise;
    if (json['devise'] != null) {
      devise = Devise.fromJson(json['devise']);
    } else {
      devise = Devise(
        id: json['deviseId'],
        name: '',
        code: '',
      );
    }

    User user;
    if (json['user'] != null) {
      user = User.fromJson(json['user']);
    } else {
      user = User(
        id: json['userId'] ?? 0,
        username: '',
        firstName: '',
        lastName: '',
        email: '',
        phoneNumber: '',
        roleName: '',
        role: null,
      );
    }

    DateTime? dateRetrait;
    if (json['dateRetrait'] != null) {
      if (json['dateRetrait'] is String) {
        dateRetrait = DateTime.tryParse(json['dateRetrait']);
      } else if (json['dateRetrait'] is int) {
        dateRetrait = DateTime.fromMillisecondsSinceEpoch(json['dateRetrait']);
      }
    }

    return CashWithdrawal(
      id: json['id'],
      montant: (json['montant'] as num?)?.toDouble() ?? 0.0,
      dateRetrait: dateRetrait,
      note: json['note'],
      partner: partner,
      userName: json['userName'] ?? '',
      versement: versement,
      devise: devise,
      user: user,
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'montant': montant,
      'dateRetrait': dateRetrait,
      'note': note,
      'partner': partner.toJson(),
      'userName': userName,
      'versement': versement.toJson(),
      'devise': devise.toJson(),
      'user': user.toJson(),
      'status': status.name,
    };
  }
}
