import 'package:bbd_limited/core/enums/status.dart';

class Containers {
  final String? reference;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final bool? isAvailable;
  final Status? status;

  Containers({
    this.reference,
    this.createdAt,
    this.editedAt,
    this.isAvailable,
    this.status,
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
    return Containers(
      reference: json['reference'] as String?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      isAvailable: json['isAvailable'] as bool?,
      status: status,
    );
  }
}
