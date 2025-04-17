import 'package:bbd_limited/core/enums/status.dart';

class Packages {
  final int id;
  final String? name;
  final double? weight;
  final String? reference;
  final String? dimensions;
  final Status status;

  Packages({
    required this.id,
    this.weight,
    this.name,
    this.reference,
    this.dimensions,
    required this.status,
  });

  factory Packages.fromJson(Map<String, dynamic> json) {
    String? statusString = json['status']; // Get status as String?
    Status status;

    if (statusString != null) {
      status = Status.values.firstWhere(
        (e) => e.toString() == 'Status.+$statusString',
        orElse: () => Status.CREATE, // Default value if not found
      );
    } else {
      status = Status.CREATE; // Default value if json['status'] is null
    }

    return Packages(
      id: json['id'] as int,
      name: json['name'],
      reference: json['reference'],
      dimensions: json['dimensions'],
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      status: status,
    );
  }
}
