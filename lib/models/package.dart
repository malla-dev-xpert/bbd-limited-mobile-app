import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/models/items.dart';

class Packages {
  final int id;
  final String? name;
  final double? weight;
  final String? reference;
  final String? dimensions;
  Status status;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final String? partnerName;
  final int? partnerId;
  final String? partnerPhoneNumber;
  final String? warehouseName;
  final String? warehouseAddress;
  final int? warehouseId;
  final int? containerId;
  List<Item>? items;

  Packages copyWith({
    int? id,
    String? name,
    double? weight,
    String? reference,
    String? dimensions,
    Status? status,
    DateTime? createdAt,
    DateTime? editedAt,
    String? partnerName,
    int? partnerId,
    String? partnerPhoneNumber,
    String? warehouseName,
    String? warehouseAddress,
    int? warehouseId,
    int? containerId,
    List<Item>? items,
  }) {
    return Packages(
      id: id ?? this.id,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      reference: reference ?? this.reference,
      dimensions: dimensions ?? this.dimensions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      partnerName: partnerName ?? this.partnerName,
      partnerId: partnerId ?? this.partnerId,
      partnerPhoneNumber: partnerPhoneNumber ?? this.partnerPhoneNumber,
      warehouseName: warehouseName ?? this.warehouseName,
      warehouseAddress: warehouseAddress ?? this.warehouseAddress,
      warehouseId: warehouseId ?? this.warehouseId,
      containerId: containerId ?? this.containerId,
      items: items ?? this.items,
    );
  }

  Packages({
    required this.id,
    this.weight,
    this.name,
    this.reference,
    this.dimensions,
    required this.status,
    this.createdAt,
    this.editedAt,
    this.partnerName,
    this.partnerId,
    this.partnerPhoneNumber,
    this.warehouseId,
    this.items,
    this.warehouseName,
    this.warehouseAddress,
    this.containerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'weight': weight,
      'reference': reference,
      'dimensions': dimensions,
      'status': status.name,
      'createdAt': createdAt?.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'partnerName': partnerName,
      'partnerId': partnerId,
      'partnerPhoneNumber': partnerPhoneNumber,
      'warehouseName': warehouseName,
      'warehouseAddress': warehouseAddress,
      'warehouseId': warehouseId,
      'containerId': containerId,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }

  factory Packages.fromJson(Map<String, dynamic> json) {
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

    List<Item> itemList = [];
    if (json['items'] != null) {
      itemList =
          (json['items'] as List).map((item) => Item.fromJson(item)).toList();
    }

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      return int.tryParse(value.toString());
    }

    return Packages(
      id: json['id'] as int,
      name: json['name'] as String?,
      reference: json['reference'] as String?,
      dimensions: json['dimensions'] as String?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      status: status,
      partnerName: json['partnerName'] as String?,
      partnerPhoneNumber: json['partnerPhoneNumber'] as String?,
      warehouseName: json['warehouseName'] as String?,
      warehouseAddress: json['warehouseAddress'] as String?,
      items: itemList,
      containerId: parseNullableInt(json['containerId']),
      partnerId: parseNullableInt(json['partnerId']),
      warehouseId: parseNullableInt(json['warehouseId']),
    );
  }
}
