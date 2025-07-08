import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/models/packages.dart';

class Containers {
  final int? id;
  final String? reference;
  final String? size;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final bool? isAvailable;
  final Status? status;
  List<Packages>? packages;
  final int? userId;
  final String? userName;
  final int? supplier_id;
  final String? supplierName;
  final String? supplierPhone;
  // Nouveaux champs de frais
  final double? locationFee;
  final double? localCharge;
  final double? loadingFee;
  final double? overweightFee;
  final double? checkingFee;
  final double? telxFee;
  final double? otherFees;
  final double? margin;
  final double? amount;
  // final int? harborId;
  // final String? harborName;

  Containers copyWith({
    int? id,
    String? reference,
    String? size,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? isAvailable,
    Status? status,
    List<Packages>? packages,
    int? userId,
    String? userName,
    int? supplier_id,
    String? supplierName,
    String? supplierPhone,
    double? locationFee,
    double? localCharge,
    double? loadingFee,
    double? overweightFee,
    double? checkingFee,
    double? telxFee,
    double? otherFees,
    double? margin,
    double? amount,
  }) {
    return Containers(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      status: status ?? this.status,
      packages: packages ?? this.packages,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      supplier_id: supplier_id ?? this.supplier_id,
      supplierName: supplierName ?? this.supplierName,
      supplierPhone: supplierPhone ?? this.supplierPhone,
      locationFee: locationFee ?? this.locationFee,
      localCharge: localCharge ?? this.localCharge,
      loadingFee: loadingFee ?? this.loadingFee,
      overweightFee: overweightFee ?? this.overweightFee,
      checkingFee: checkingFee ?? this.checkingFee,
      telxFee: telxFee ?? this.telxFee,
      otherFees: otherFees ?? this.otherFees,
      margin: margin ?? this.margin,
      amount: amount ?? this.amount,
      // harborId: harborId ?? this.harborId,
      // harborName: harborName ?? this.harborName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'size': size,
      'createdAt': createdAt?.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'isAvailable': isAvailable,
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
  }

  Containers({
    this.id,
    this.reference,
    this.size,
    this.createdAt,
    this.editedAt,
    this.isAvailable,
    this.status,
    this.packages,
    this.userId,
    this.userName,
    this.supplier_id,
    this.supplierName,
    this.supplierPhone,
    this.locationFee,
    this.localCharge,
    this.loadingFee,
    this.overweightFee,
    this.checkingFee,
    this.telxFee,
    this.otherFees,
    this.margin,
    this.amount,
    // this.harborId,
    // this.harborName,
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
      isAvailable: json['isAvailable'] as bool?,
      status: status,
      packages: packageList,
      userId: json['userId'] as int?,
      userName: json['userName'] as String?,
      supplier_id: json['supplier_id'] as int?,
      supplierName: json['supplierName'] as String?,
      supplierPhone: json['supplierPhone'] as String?,
      locationFee: (json['locationFee'] as num?)?.toDouble(),
      localCharge: (json['localCharge'] as num?)?.toDouble(),
      loadingFee: (json['loadingFee'] as num?)?.toDouble(),
      overweightFee: (json['overweightFee'] as num?)?.toDouble(),
      checkingFee: (json['checkingFee'] as num?)?.toDouble(),
      telxFee: (json['telxFee'] as num?)?.toDouble(),
      otherFees: (json['otherFees'] as num?)?.toDouble(),
      margin: (json['margin'] as num?)?.toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }
}
