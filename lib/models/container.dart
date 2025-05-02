import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/models/package.dart';

class Containers {
  final String? reference;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final bool? isAvailable;
  final Status? status;
  List<Packages>? packages;

  Containers copyWith({
    String? reference,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? isAvailable,
    Status? status,
    List<Packages>? packages,
  }) {
    return Containers(
      reference: reference ?? this.reference,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      status: status ?? this.status,
      packages: packages ?? this.packages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'createdAt': createdAt?.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'isAvailable': isAvailable,
      'status': status?.name,
      'packages': packages?.map((e) => e.toJson()).toList(),
    };
  }

  Containers({
    this.reference,
    this.createdAt,
    this.editedAt,
    this.isAvailable,
    this.status,
    this.packages,
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
    if (json['items'] != null) {
      packageList =
          (json['items'] as List)
              .map((item) => Packages.fromJson(item))
              .toList();
    }

    return Containers(
      reference: json['reference'] as String?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      isAvailable: json['isAvailable'] as bool?,
      status: status,
      packages: packageList,
    );
  }
}
