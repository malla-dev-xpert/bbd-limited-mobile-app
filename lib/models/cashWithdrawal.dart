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
    return CashWithdrawal(
      id: json['id'],
      montant: json['montant'],
      dateRetrait: json['dateRetrait'],
      note: json['note'],
      partner: Partner.fromJson(json['partner']),
      versement: Versement.fromJson(json['versement']),
      devise: Devise.fromJson(json['devise']),
      user: User.fromJson(json['user']),
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
      'versement': versement.toJson(),
      'devise': devise.toJson(),
      'user': user.toJson(),
      'status': status.name,
    };
  }
}
