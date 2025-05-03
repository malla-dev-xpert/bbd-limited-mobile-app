import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/models/package.dart';

class Containers {
  final int? id;
  final String? reference;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final bool? isAvailable;
  final Status? status;
  List<Packages>? packages;
  final int? userId;
  final String? userName;
  // final int? harborId;
  // final String? harborName;

  Containers copyWith({
    int? id,
    String? reference,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? isAvailable,
    Status? status,
    List<Packages>? packages,
    int? userId,
    String? userName,
    // int? harborId,
    // String? harborName,
  }) {
    return Containers(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      status: status ?? this.status,
      packages: packages ?? this.packages,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      // harborId: harborId ?? this.harborId,
      // harborName: harborName ?? this.harborName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'createdAt': createdAt?.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'isAvailable': isAvailable,
      'status': status?.name,
      'packages': packages?.map((e) => e.toJson()).toList(),
      'userId': userId,
      'userName': userName,
      // 'harborId': harborId,
      // 'harborName': harborName,
    };
  }

  Containers({
    this.id,
    this.reference,
    this.createdAt,
    this.editedAt,
    this.isAvailable,
    this.status,
    this.packages,
    this.userId,
    this.userName,
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
      packageList =
          (json['packages'] as List)
              .map((item) => Packages.fromJson(item))
              .toList();
    }

    return Containers(
      id: json['id'] as int?,
      reference: json['reference'] as String?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      isAvailable: json['isAvailable'] as bool?,
      status: status,
      packages: packageList,
      userId: json['userId'] as int?,
      userName: json['userName'] as String?,
    );
  }
}
