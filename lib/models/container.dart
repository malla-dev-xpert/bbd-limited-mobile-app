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
    );
  }
}
