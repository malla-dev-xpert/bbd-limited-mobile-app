import 'package:bbd_limited/core/enums/status.dart';

class Achat {
  final int? id;
  final String? referenceVersement;
  final String? client;
  final String? clientPhone;
  final List<Items>? items;
  final double? montantTotal;
  final DateTime? createdAt;
  final bool? isDebt;
  final int? clientId;
  Status? status;
  final double? tauxUtiliseToCNY;
  final double? montantTotalCNY;
  final double? totalCbn;
  final double? totalWeight;

  Achat copyWith({
    int? id,
    String? referenceVersement,
    String? client,
    String? clientPhone,
    List<Items>? items,
    double? montantTotal,
    DateTime? createdAt,
    bool? isDebt,
    int? clientId,
    Status? status,
    double? tauxUtiliseToCNY,
    double? montantTotalCNY,
    double? totalCbn,
    double? totalWeight,
  }) {
    return Achat(
      id: id ?? this.id,
      referenceVersement: referenceVersement ?? this.referenceVersement,
      client: client ?? this.client,
      clientPhone: clientPhone ?? this.clientPhone,
      items: items ?? this.items,
      montantTotal: montantTotal ?? this.montantTotal,
      createdAt: createdAt ?? this.createdAt,
      isDebt: isDebt ?? this.isDebt,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      tauxUtiliseToCNY: tauxUtiliseToCNY ?? this.tauxUtiliseToCNY,
      montantTotalCNY: montantTotalCNY ?? this.montantTotalCNY,
      totalCbn: totalCbn ?? this.totalCbn,
      totalWeight: totalWeight ?? this.totalWeight,
    );
  }

  Achat({
    this.id,
    this.referenceVersement,
    this.client,
    this.clientPhone,
    this.items,
    this.montantTotal,
    this.createdAt,
    this.isDebt,
    this.clientId,
    this.status,
    this.tauxUtiliseToCNY,
    this.montantTotalCNY,
    this.totalCbn,
    this.totalWeight,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referenceVersement': referenceVersement,
      'client': client,
      'clientPhone': clientPhone,
      'items': items?.map((ligne) => ligne.toJson()).toList(),
      'montantTotal': montantTotal,
      'createdAt': createdAt,
      'isDebt': isDebt,
      'clientId': clientId,
      'status': status?.name,
      'tauxUtiliseToCNY': tauxUtiliseToCNY,
      'montantTotalCNY': montantTotalCNY,
      'totalCbn': totalCbn,
      'totalWeight': totalWeight,
    };
  }

  factory Achat.fromJson(Map<String, dynamic> json) {
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

    return Achat(
      id: json['id'] as int?,
      referenceVersement: json['referenceVersement'] as String?,
      client: json['client'] as String?,
      clientPhone: json['clientPhone'] as String?,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((ligne) => Items.fromJson(ligne))
              .toList()
          : null,
      montantTotal: json['montantTotal'] != null
          ? (json['montantTotal'] as num).toDouble()
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      isDebt: json['isDebt'] as bool?,
      clientId: json['clientId'] as int?,
      status: status,
      tauxUtiliseToCNY: json['tauxUtiliseToCNY'] != null
          ? (json['tauxUtiliseToCNY'] as num).toDouble()
          : null,
      montantTotalCNY: json['montantTotalCNY'] != null
          ? (json['montantTotalCNY'] as num).toDouble()
          : null,
      totalCbn: json['totalCbn'] != null
          ? (json['totalCbn'] as num).toDouble()
          : null,
      totalWeight: json['totalWeight'] != null
          ? (json['totalWeight'] as num).toDouble()
          : null,
    );
  }
}

class Items {
  final int? id;
  final String? description;
  final int? quantity;
  final int? carton; // Nouveau champ : nombre de cartons
  final int? quantityPerCarton; // Nouveau champ : quantité par carton
  final double? unitPrice;
  final double? totalPrice;
  final int? supplierId;
  final String? supplierName;
  final int? packageId;

  /// When set, item is assigned to this container (for filtering available items).
  final int? containerId;
  final String? supplierPhone;
  final double? salesRate;
  final String? invoiceNumber;
  Status? status;
  bool? paid;
  final DateTime? paiementDate;
  final int? paidByUserId;
  final double? amountPaid;
  final String? paidByUserName;
  final double? totalPriceRateToCNY;
  final double? totalPriceCNY;
  final double? weight;
  final double? cartonLength;
  final double? cartonWidth;
  final double? cartonHeight;
  final double? cbn;
  Items({
    this.id,
    this.description,
    this.quantity,
    this.carton,
    this.quantityPerCarton,
    this.unitPrice,
    this.totalPrice,
    this.supplierId,
    this.supplierName,
    this.supplierPhone,
    this.packageId,
    this.containerId,
    this.salesRate,
    this.invoiceNumber,
    this.status,
    this.paid,
    this.paiementDate,
    this.paidByUserId,
    this.amountPaid,
    this.paidByUserName,
    this.totalPriceRateToCNY,
    this.totalPriceCNY,
    this.weight,
    this.cartonLength,
    this.cartonWidth,
    this.cartonHeight,
    this.cbn,
  });

  Items copyWith({
    int? id,
    String? description,
    int? quantity,
    int? carton,
    int? quantityPerCarton,
    double? unitPrice,
    double? totalPrice,
    int? supplierId,
    String? supplierName,
    String? supplierPhone,
    int? packageId,
    int? containerId,
    double? salesRate,
    String? invoiceNumber,
    Status? status,
    bool? paid,
    DateTime? paiementDate,
    int? paidByUserId,
    double? amountPaid,
    String? paidByUserName,
    double? totalPriceRateToCNY,
    double? totalPriceCNY,
    double? weight,
    double? cartonLength,
    double? cartonWidth,
    double? cartonHeight,
    double? cbn,
  }) {
    return Items(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      carton: carton ?? this.carton,
      quantityPerCarton: quantityPerCarton ?? this.quantityPerCarton,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierPhone: supplierPhone ?? this.supplierPhone,
      packageId: packageId ?? this.packageId,
      containerId: containerId ?? this.containerId,
      salesRate: salesRate ?? this.salesRate,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      status: status ?? this.status,
      paid: paid ?? this.paid,
      paiementDate: paiementDate ?? this.paiementDate,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      amountPaid: amountPaid ?? this.amountPaid,
      paidByUserName: paidByUserName ?? this.paidByUserName,
      totalPriceRateToCNY: totalPriceRateToCNY ?? this.totalPriceRateToCNY,
      totalPriceCNY: totalPriceCNY ?? this.totalPriceCNY,
      weight: weight ?? this.weight,
      cartonLength: cartonLength ?? this.cartonLength,
      cartonWidth: cartonWidth ?? this.cartonWidth,
      cartonHeight: cartonHeight ?? this.cartonHeight,
      cbn: cbn ?? this.cbn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'description': description,
      'quantity': quantity,
      'carton': carton,
      'quantityPerCarton': quantityPerCarton,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'supplierPhone': supplierPhone,
      'packageId': packageId,
      'containerId': containerId,
      'salesRate': salesRate,
      'invoiceNumber': invoiceNumber,
      'status': status?.name,
      'paid': paid,
      'paiementDate': paiementDate?.toIso8601String(),
      'paidByUserId': paidByUserId,
      'amountPaid': amountPaid,
      'paidByUserName': paidByUserName,
      'totalPriceRateToCNY': totalPriceRateToCNY,
      'totalPriceCNY': totalPriceCNY,
      'weight': weight,
      'cartonLength': cartonLength,
      'cartonWidth': cartonWidth,
      'cartonHeight': cartonHeight,
      'cbn': cbn,
    };
  }

  factory Items.fromJson(Map<String, dynamic> json) {
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

    return Items(
      id: json['id'] as int?,
      quantity: json['quantity'] as int?,
      description: json['description'] as String?,
      carton: json['carton'] as int?,
      quantityPerCarton: json['quantityPerCarton'] as int?,
      unitPrice: json['unitPrice'] != null
          ? (json['unitPrice'] as num).toDouble()
          : null,
      totalPrice: json['totalPrice'] != null
          ? (json['totalPrice'] as num).toDouble()
          : null,
      supplierId: json['supplierId'] as int?,
      supplierName: json['supplierName'] as String?,
      supplierPhone: json['supplierPhone'] as String?,
      packageId: json['packageId'] as int?,
      containerId: json['containerId'] as int?,
      salesRate: json['salesRate'] != null
          ? (json['salesRate'] as num).toDouble()
          : null,
      invoiceNumber: json['invoiceNumber'] as String?,
      status: status,
      paid: json['paid'] as bool?,
      paiementDate: json['paiementDate'] != null
          ? DateTime.parse(json['paiementDate'])
          : null,
      paidByUserId: json['paidByUserId'] as int?,
      amountPaid: json['amountPaid'] != null
          ? (json['amountPaid'] as num).toDouble()
          : null,
      paidByUserName: json['paidByUserName'] as String?,
      totalPriceRateToCNY: json['totalPriceRateToCNY'] != null
          ? (json['totalPriceRateToCNY'] as num).toDouble()
          : null,
      totalPriceCNY: json['totalPriceCNY'] != null
          ? (json['totalPriceCNY'] as num).toDouble()
          : null,
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      cartonLength: json['cartonLength'] != null
          ? (json['cartonLength'] as num).toDouble()
          : null,
      cartonWidth: json['cartonWidth'] != null
          ? (json['cartonWidth'] as num).toDouble()
          : null,
      cartonHeight: json['cartonHeight'] != null
          ? (json['cartonHeight'] as num).toDouble()
          : null,
      cbn: json['cbn'] != null ? (json['cbn'] as num).toDouble() : null,
    );
  }
}
