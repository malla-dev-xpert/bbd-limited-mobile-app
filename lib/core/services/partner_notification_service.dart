import 'dart:async';
import 'package:bbd_limited/models/partner.dart';

class PartnerNotificationService {
  static final PartnerNotificationService _instance =
      PartnerNotificationService._internal();
  factory PartnerNotificationService() => _instance;
  PartnerNotificationService._internal();

  final StreamController<Partner> _partnerUpdateController =
      StreamController<Partner>.broadcast();

  Stream<Partner> get partnerUpdateStream => _partnerUpdateController.stream;

  void notifyPartnerUpdate(Partner partner) {
    _partnerUpdateController.add(partner);
  }

  void dispose() {
    _partnerUpdateController.close();
  }
}
