import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/models/packages.dart';

class Containers {
  final int? id;
  final String? reference;
  final String? size;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final DateTime? startDeliveryDate;
  final DateTime? confirmDeliveryDate;
  final bool? isAvailable;
  bool? isTeam;
  final Status? status;
  List<Packages>? packages;
  final int? userId;
  final String? userName;
  final int? supplier_id;
  final String? supplierName;
  final String? supplierPhone;
  // Nouveaux champs de frais
  final double? locationFee;
  final String? locationFeeCurrencyCode;
  final double? locationFeeRateToCNY;
  final double? localCharge;
  final String? localChargeCurrencyCode;
  final double? localChargeRateToCNY;
  final double? loadingFee;
  final String? loadingFeeCurrencyCode;
  final double? loadingFeeRateToCNY;
  final double? overweightFee;
  final String? overweightFeeCurrencyCode;
  final double? overweightFeeRateToCNY;
  final double? checkingFee;
  final String? checkingFeeCurrencyCode;
  final double? checkingFeeRateToCNY;
  final double? telxFee;
  final String? telxFeeCurrencyCode;
  final double? telxFeeRateToCNY;
  final double? otherFees;
  final String? otherFeesCurrencyCode;
  final double? otherFeesRateToCNY;
  final double? margin;
  final String? marginCurrencyCode;
  final double? marginRateToCNY;
  final double? amount;

  /// Montants CNY calculés par le backend (lecture seule, jamais calculés côté Flutter)
  final double? locationFeeCNY;
  final double? localChargeCNY;
  final double? loadingFeeCNY;
  final double? overweightFeeCNY;
  final double? checkingFeeCNY;
  final double? telxFeeCNY;
  final double? otherFeesCNY;
  final double? marginCNY;

  /** Port de départ. */
  final int? departureHarborId;
  final String? departureHarborName;
  final String? departureHarborLocation;
  /** Port d'arrivée. */
  final int? arrivalHarborId;
  final String? arrivalHarborName;
  final String? arrivalHarborLocation;

  Containers copyWith({
    int? id,
    String? reference,
    String? size,
    DateTime? createdAt,
    DateTime? editedAt,
    DateTime? startDeliveryDate,
    DateTime? confirmDeliveryDate,
    bool? isAvailable,
    bool? isTeam,
    Status? status,
    List<Packages>? packages,
    int? userId,
    String? userName,
    int? supplier_id,
    String? supplierName,
    String? supplierPhone,
    double? locationFee,
    String? locationFeeCurrencyCode,
    double? locationFeeRateToCNY,
    double? localCharge,
    String? localChargeCurrencyCode,
    double? localChargeRateToCNY,
    double? loadingFee,
    String? loadingFeeCurrencyCode,
    double? loadingFeeRateToCNY,
    double? overweightFee,
    String? overweightFeeCurrencyCode,
    double? overweightFeeRateToCNY,
    double? checkingFee,
    String? checkingFeeCurrencyCode,
    double? checkingFeeRateToCNY,
    double? telxFee,
    String? telxFeeCurrencyCode,
    double? telxFeeRateToCNY,
    double? otherFees,
    String? otherFeesCurrencyCode,
    double? otherFeesRateToCNY,
    double? margin,
    String? marginCurrencyCode,
    double? marginRateToCNY,
    double? amount,
    double? locationFeeCNY,
    double? localChargeCNY,
    double? loadingFeeCNY,
    double? overweightFeeCNY,
    double? checkingFeeCNY,
    double? telxFeeCNY,
    double? otherFeesCNY,
    double? marginCNY,
    int? departureHarborId,
    String? departureHarborName,
    String? departureHarborLocation,
    int? arrivalHarborId,
    String? arrivalHarborName,
    String? arrivalHarborLocation,
  }) {
    return Containers(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      startDeliveryDate: startDeliveryDate ?? this.startDeliveryDate,
      confirmDeliveryDate: confirmDeliveryDate ?? this.confirmDeliveryDate,
      isAvailable: isAvailable ?? this.isAvailable,
      isTeam: isTeam ?? this.isTeam,
      status: status ?? this.status,
      packages: packages ?? this.packages,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      supplier_id: supplier_id ?? this.supplier_id,
      supplierName: supplierName ?? this.supplierName,
      supplierPhone: supplierPhone ?? this.supplierPhone,
      locationFee: locationFee ?? this.locationFee,
      locationFeeCurrencyCode:
          locationFeeCurrencyCode ?? this.locationFeeCurrencyCode,
      locationFeeRateToCNY: locationFeeRateToCNY ?? this.locationFeeRateToCNY,
      localCharge: localCharge ?? this.localCharge,
      localChargeCurrencyCode:
          localChargeCurrencyCode ?? this.localChargeCurrencyCode,
      localChargeRateToCNY: localChargeRateToCNY ?? this.localChargeRateToCNY,
      loadingFee: loadingFee ?? this.loadingFee,
      loadingFeeCurrencyCode:
          loadingFeeCurrencyCode ?? this.loadingFeeCurrencyCode,
      loadingFeeRateToCNY: loadingFeeRateToCNY ?? this.loadingFeeRateToCNY,
      overweightFee: overweightFee ?? this.overweightFee,
      overweightFeeCurrencyCode:
          overweightFeeCurrencyCode ?? this.overweightFeeCurrencyCode,
      overweightFeeRateToCNY:
          overweightFeeRateToCNY ?? this.overweightFeeRateToCNY,
      checkingFee: checkingFee ?? this.checkingFee,
      checkingFeeCurrencyCode:
          checkingFeeCurrencyCode ?? this.checkingFeeCurrencyCode,
      checkingFeeRateToCNY: checkingFeeRateToCNY ?? this.checkingFeeRateToCNY,
      telxFee: telxFee ?? this.telxFee,
      telxFeeCurrencyCode: telxFeeCurrencyCode ?? this.telxFeeCurrencyCode,
      telxFeeRateToCNY: telxFeeRateToCNY ?? this.telxFeeRateToCNY,
      otherFees: otherFees ?? this.otherFees,
      otherFeesCurrencyCode:
          otherFeesCurrencyCode ?? this.otherFeesCurrencyCode,
      otherFeesRateToCNY: otherFeesRateToCNY ?? this.otherFeesRateToCNY,
      margin: margin ?? this.margin,
      marginCurrencyCode: marginCurrencyCode ?? this.marginCurrencyCode,
      marginRateToCNY: marginRateToCNY ?? this.marginRateToCNY,
      amount: amount ?? this.amount,
      locationFeeCNY: locationFeeCNY ?? this.locationFeeCNY,
      localChargeCNY: localChargeCNY ?? this.localChargeCNY,
      loadingFeeCNY: loadingFeeCNY ?? this.loadingFeeCNY,
      overweightFeeCNY: overweightFeeCNY ?? this.overweightFeeCNY,
      checkingFeeCNY: checkingFeeCNY ?? this.checkingFeeCNY,
      telxFeeCNY: telxFeeCNY ?? this.telxFeeCNY,
      otherFeesCNY: otherFeesCNY ?? this.otherFeesCNY,
      marginCNY: marginCNY ?? this.marginCNY,
      departureHarborId: departureHarborId ?? this.departureHarborId,
      departureHarborName: departureHarborName ?? this.departureHarborName,
      departureHarborLocation:
          departureHarborLocation ?? this.departureHarborLocation,
      arrivalHarborId: arrivalHarborId ?? this.arrivalHarborId,
      arrivalHarborName: arrivalHarborName ?? this.arrivalHarborName,
      arrivalHarborLocation:
          arrivalHarborLocation ?? this.arrivalHarborLocation,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id,
      'reference': reference,
      'size': size,
      'createdAt': createdAt?.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'startDeliveryDate': startDeliveryDate?.toIso8601String(),
      'confirmDeliveryDate': confirmDeliveryDate?.toIso8601String(),
      'isAvailable': isAvailable,
      'isTeam': isTeam,
      'status': status?.name,
      'packages': packages?.map((e) => e.toJson()).toList(),
      'userId': userId,
      'userName': userName,
      'supplier_id': supplier_id,
      'supplierName': supplierName,
      'supplierPhone': supplierPhone,
      'locationFee': locationFee,
      'localCharge': localCharge,
      'loadingFee': loadingFee,
      'overweightFee': overweightFee,
      'checkingFee': checkingFee,
      'telxFee': telxFee,
      'otherFees': otherFees,
      'margin': margin,
      'amount': amount,
      // 'harborId': harborId,
      // 'harborName': harborName,
    };

    // Ajouter les champs de devises et taux seulement s'ils ne sont pas null
    if (locationFeeCurrencyCode != null)
      json['locationFeeCurrencyCode'] = locationFeeCurrencyCode;
    if (locationFeeRateToCNY != null)
      json['locationFeeRateToCNY'] = locationFeeRateToCNY;
    if (localChargeCurrencyCode != null)
      json['localChargeCurrencyCode'] = localChargeCurrencyCode;
    if (localChargeRateToCNY != null)
      json['localChargeRateToCNY'] = localChargeRateToCNY;
    if (loadingFeeCurrencyCode != null)
      json['loadingFeeCurrencyCode'] = loadingFeeCurrencyCode;
    if (loadingFeeRateToCNY != null)
      json['loadingFeeRateToCNY'] = loadingFeeRateToCNY;
    if (overweightFeeCurrencyCode != null)
      json['overweightFeeCurrencyCode'] = overweightFeeCurrencyCode;
    if (overweightFeeRateToCNY != null)
      json['overweightFeeRateToCNY'] = overweightFeeRateToCNY;
    if (checkingFeeCurrencyCode != null)
      json['checkingFeeCurrencyCode'] = checkingFeeCurrencyCode;
    if (checkingFeeRateToCNY != null)
      json['checkingFeeRateToCNY'] = checkingFeeRateToCNY;
    if (telxFeeCurrencyCode != null)
      json['telxFeeCurrencyCode'] = telxFeeCurrencyCode;
    if (telxFeeRateToCNY != null) json['telxFeeRateToCNY'] = telxFeeRateToCNY;
    if (otherFeesCurrencyCode != null)
      json['otherFeesCurrencyCode'] = otherFeesCurrencyCode;
    if (otherFeesRateToCNY != null)
      json['otherFeesRateToCNY'] = otherFeesRateToCNY;
    if (marginCurrencyCode != null)
      json['marginCurrencyCode'] = marginCurrencyCode;
    if (marginRateToCNY != null) json['marginRateToCNY'] = marginRateToCNY;
    if (departureHarborId != null)
      json['departureHarborId'] = departureHarborId;
    if (departureHarborName != null)
      json['departureHarborName'] = departureHarborName;
    if (departureHarborLocation != null)
      json['departureHarborLocation'] = departureHarborLocation;
    if (arrivalHarborId != null) json['arrivalHarborId'] = arrivalHarborId;
    if (arrivalHarborName != null)
      json['arrivalHarborName'] = arrivalHarborName;
    if (arrivalHarborLocation != null)
      json['arrivalHarborLocation'] = arrivalHarborLocation;

    return json;
  }

  Containers({
    this.id,
    this.reference,
    this.size,
    this.createdAt,
    this.editedAt,
    this.startDeliveryDate,
    this.confirmDeliveryDate,
    this.isAvailable,
    this.isTeam,
    this.status,
    this.packages,
    this.userId,
    this.userName,
    this.supplier_id,
    this.supplierName,
    this.supplierPhone,
    this.locationFee,
    this.locationFeeCurrencyCode,
    this.locationFeeRateToCNY,
    this.localCharge,
    this.localChargeCurrencyCode,
    this.localChargeRateToCNY,
    this.loadingFee,
    this.loadingFeeCurrencyCode,
    this.loadingFeeRateToCNY,
    this.overweightFee,
    this.overweightFeeCurrencyCode,
    this.overweightFeeRateToCNY,
    this.checkingFee,
    this.checkingFeeCurrencyCode,
    this.checkingFeeRateToCNY,
    this.telxFee,
    this.telxFeeCurrencyCode,
    this.telxFeeRateToCNY,
    this.otherFees,
    this.otherFeesCurrencyCode,
    this.otherFeesRateToCNY,
    this.margin,
    this.marginCurrencyCode,
    this.marginRateToCNY,
    this.amount,
    this.locationFeeCNY,
    this.localChargeCNY,
    this.loadingFeeCNY,
    this.overweightFeeCNY,
    this.checkingFeeCNY,
    this.telxFeeCNY,
    this.otherFeesCNY,
    this.marginCNY,
    this.departureHarborId,
    this.departureHarborName,
    this.departureHarborLocation,
    this.arrivalHarborId,
    this.arrivalHarborName,
    this.arrivalHarborLocation,
  });

  factory Containers.fromJson(Map<String, dynamic> json) {
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

    List<Packages> packageList = [];
    if (json['packages'] != null) {
      packageList = (json['packages'] as List)
          .map((item) => Packages.fromJson(item))
          .toList();
    }

    return Containers(
      id: json['id'] as int?,
      reference: json['reference'] as String?,
      size: json['size'] as String?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      startDeliveryDate: json['startDeliveryDate'] != null
          ? DateTime.parse(json['startDeliveryDate'])
          : null,
      confirmDeliveryDate: json['confirmDeliveryDate'] != null
          ? DateTime.parse(json['confirmDeliveryDate'])
          : null,
      isAvailable: json['isAvailable'] as bool?,
      isTeam: json['isTeam'] as bool?,
      status: status,
      packages: packageList,
      userId: json['userId'] as int?,
      userName: json['userName'] as String?,
      supplier_id: json['supplier_id'] as int?,
      supplierName: json['supplierName'] as String?,
      supplierPhone: json['supplierPhone'] as String?,
      locationFee: (json['locationFee'] as num?)?.toDouble(),
      locationFeeCurrencyCode: json['locationFeeCurrencyCode'] as String?,
      locationFeeRateToCNY: (json['locationFeeRateToCNY'] as num?)?.toDouble(),
      localCharge: (json['localCharge'] as num?)?.toDouble(),
      localChargeCurrencyCode: json['localChargeCurrencyCode'] as String?,
      localChargeRateToCNY: (json['localChargeRateToCNY'] as num?)?.toDouble(),
      loadingFee: (json['loadingFee'] as num?)?.toDouble(),
      loadingFeeCurrencyCode: json['loadingFeeCurrencyCode'] as String?,
      loadingFeeRateToCNY: (json['loadingFeeRateToCNY'] as num?)?.toDouble(),
      overweightFee: (json['overweightFee'] as num?)?.toDouble(),
      overweightFeeCurrencyCode: json['overweightFeeCurrencyCode'] as String?,
      overweightFeeRateToCNY:
          (json['overweightFeeRateToCNY'] as num?)?.toDouble(),
      checkingFee: (json['checkingFee'] as num?)?.toDouble(),
      checkingFeeCurrencyCode: json['checkingFeeCurrencyCode'] as String?,
      checkingFeeRateToCNY: (json['checkingFeeRateToCNY'] as num?)?.toDouble(),
      telxFee: (json['telxFee'] as num?)?.toDouble(),
      telxFeeCurrencyCode: json['telxFeeCurrencyCode'] as String?,
      telxFeeRateToCNY: (json['telxFeeRateToCNY'] as num?)?.toDouble(),
      otherFees: (json['otherFees'] as num?)?.toDouble(),
      otherFeesCurrencyCode: json['otherFeesCurrencyCode'] as String?,
      otherFeesRateToCNY: (json['otherFeesRateToCNY'] as num?)?.toDouble(),
      margin: (json['margin'] as num?)?.toDouble(),
      marginCurrencyCode: json['marginCurrencyCode'] as String?,
      marginRateToCNY: (json['marginRateToCNY'] as num?)?.toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
      locationFeeCNY: (json['locationFeeCNY'] as num?)?.toDouble(),
      localChargeCNY: (json['localChargeCNY'] as num?)?.toDouble(),
      loadingFeeCNY: (json['loadingFeeCNY'] as num?)?.toDouble(),
      overweightFeeCNY: (json['overweightFeeCNY'] as num?)?.toDouble(),
      checkingFeeCNY: (json['checkingFeeCNY'] as num?)?.toDouble(),
      telxFeeCNY: (json['telxFeeCNY'] as num?)?.toDouble(),
      otherFeesCNY: (json['otherFeesCNY'] as num?)?.toDouble(),
      marginCNY: (json['marginCNY'] as num?)?.toDouble(),
      departureHarborId: json['departureHarborId'] as int?,
      departureHarborName: json['departureHarborName'] as String?,
      departureHarborLocation: json['departureHarborLocation'] as String?,
      arrivalHarborId: json['arrivalHarborId'] as int?,
      arrivalHarborName: json['arrivalHarborName'] as String?,
      arrivalHarborLocation: json['arrivalHarborLocation'] as String?,
    );
  }
}
