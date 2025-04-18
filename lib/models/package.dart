import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/models/items.dart';

class Packages {
  final int id;
  final String? name;
  final double? weight;
  final String? reference;
  final String? dimensions;
  final Status status;
  final DateTime? createdAt;
  final String? partnerName;
  final String? partnerPhoneNumber;
  final int? warehouseId;
  final List<Item>? items;

  Packages({
    required this.id,
    this.weight,
    this.name,
    this.reference,
    this.dimensions,
    required this.status,
    this.createdAt,
    this.partnerName,
    this.partnerPhoneNumber,
    this.warehouseId,
    this.items,
  });

  factory Packages.fromJson(Map<String, dynamic> json) {
    String? statusString = json['status'];
    Status status;

    if (statusString != null) {
      status = Status.values.firstWhere(
        (e) => e.toString() == 'Status.+$statusString',
        orElse: () => Status.CREATE,
      );
    } else {
      status = Status.CREATE;
    }

    List<Item> itemList = [];
    if (json['items'] != null) {
      itemList =
          (json['items'] as List).map((item) => Item.fromJson(item)).toList();
    }

    return Packages(
      id: json['id'] as int,
      name: json['name'],
      reference: json['reference'],
      dimensions: json['dimensions'],
      createdAt: DateTime.parse(json['createdAt']),
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      status: status,
      partnerName: json['partnerName'],
      partnerPhoneNumber: json['partnerPhoneNumber'],
      warehouseId: json['warehouseId'],
      items: itemList,
    );
  }
}
