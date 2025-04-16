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
    Status status;
    try {
      status = Status.values.firstWhere(
        (statut) => statut.name == json['status'],
        orElse: () => Status.CREATE,
      );
    } catch (e) {
      status = Status.CREATE;
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
