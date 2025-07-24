import 'package:bbd_limited/core/enums/status.dart';

class Packages {
  final int? id;
  final String? ref;
  final String? expeditionType;
  final String? startCountry;
  final String? destinationCountry;
  final double? weight;
  final double? itemQuantity;
  final double? cbn;
  final int? clientId;
  final String? clientName;
  final String? clientPhone;
  final DateTime? arrivalDate;
  final DateTime? startDate;
  final DateTime? receivedDate;
  Status? status;
  final String? warehouseName;
  final String? warehouseAddress;
  final int? warehouseId;
  final int? containerId;
  final List<int>? itemIds;
  final int? startHarborId;
  final int? destinationHarborId;

  Packages copyWith({
    int? id,
    String? ref,
    String? expeditionType,
    String? startCountry,
    String? destinationCountry,
    double? weight,
    double? itemQuantity,
    double? cbn,
    int? clientId,
    String? clientName,
    String? clientPhone,
    DateTime? arrivalDate,
    DateTime? startDate,
    DateTime? receivedDate,
    Status? status,
    String? warehouseName,
    String? warehouseAddress,
    int? warehouseId,
    int? containerId,
    List<int>? itemIds,
    int? startHarborId,
    int? destinationHarborId,
  }) {
    return Packages(
      id: id ?? this.id,
      ref: ref ?? this.ref,
      expeditionType: expeditionType ?? this.expeditionType,
      startCountry: startCountry ?? this.startCountry,
      destinationCountry: destinationCountry ?? this.destinationCountry,
      weight: weight ?? this.weight,
      itemQuantity: itemQuantity ?? this.itemQuantity,
      cbn: cbn ?? this.cbn,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      receivedDate: receivedDate ?? this.receivedDate,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
      warehouseName: warehouseName ?? this.warehouseName,
      warehouseAddress: warehouseAddress ?? this.warehouseAddress,
      warehouseId: warehouseId ?? this.warehouseId,
      containerId: containerId ?? this.containerId,
      itemIds: itemIds ?? this.itemIds,
      startHarborId: startHarborId ?? this.startHarborId,
      destinationHarborId: destinationHarborId ?? this.destinationHarborId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ref': ref,
        'expeditionType': expeditionType,
        'startCountry': startCountry,
        'destinationCountry': destinationCountry,
        'weight': weight,
        'itemQuantity': itemQuantity,
        'cbn': cbn,
        'clientId': clientId,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'arrivalDate': arrivalDate?.toUtc().toIso8601String() ?? '',
        'receivedDate': receivedDate?.toUtc().toIso8601String(),
        'startDate': startDate?.toUtc().toIso8601String(),
        'status': status?.name,
        'warehouseName': warehouseName,
        'warehouseAddress': warehouseAddress,
        'warehouseId': warehouseId,
        'containerId': containerId,
        'itemIds': itemIds,
        'startHarborId': startHarborId,
        'destinationHarborId': destinationHarborId,
      };

  Packages({
    this.id,
    this.ref,
    this.expeditionType,
    this.startCountry,
    this.destinationCountry,
    this.weight,
    this.itemQuantity,
    this.cbn,
    this.clientId,
    this.clientName,
    this.clientPhone,
    this.arrivalDate,
    this.startDate,
    this.receivedDate,
    this.status,
    this.warehouseId,
    this.warehouseName,
    this.warehouseAddress,
    this.containerId,
    this.itemIds,
    this.startHarborId,
    this.destinationHarborId,
  });

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

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      return int.tryParse(value.toString());
    }

    return Packages(
      id: json['id'] as int?,
      ref: json['ref'] as String?,
      expeditionType: json['expeditionType'] as String?,
      startCountry: json['startCountry'] as String?,
      destinationCountry: json['destinationCountry'] as String?,
      weight: json['weight'] as double?,
      itemQuantity: json['itemQuantity'] as double?,
      cbn: json['cbn'] as double?,
      clientId: json['clientId'] as int?,
      clientName: json['clientName'] as String?,
      clientPhone: json['clientPhone'] as String?,
      arrivalDate: json['arrivalDate'] != null
          ? DateTime.parse(json['arrivalDate'])
          : null,
      receivedDate: json['receivedDate'] != null
          ? DateTime.parse(json['receivedDate'])
          : null,
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      status: status,
      warehouseName: json['warehouseName'] as String?,
      warehouseAddress: json['warehouseAddress'] as String?,
      containerId: parseNullableInt(json['containerId']),
      warehouseId: parseNullableInt(json['warehouseId']),
      itemIds: json['itemIds'] as List<int>?,
      startHarborId: parseNullableInt(json['startHarborId']),
      destinationHarborId: parseNullableInt(json['destinationHarborId']),
    );
  }
}
