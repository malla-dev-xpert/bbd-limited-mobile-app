class PaymentResponse {
  final int? paymentId;
  final int? itemId;
  final double? amountPaid;
  final double? totalPaid;
  final double? remainingAmount;
  final bool? isFullyPaid;
  final DateTime? paymentDate;
  final String? paidBy;
  final String? supplierName;
  final String? itemDescription;
  final String? message;

  PaymentResponse({
    this.paymentId,
    this.itemId,
    this.amountPaid,
    this.totalPaid,
    this.remainingAmount,
    this.isFullyPaid,
    this.paymentDate,
    this.paidBy,
    this.supplierName,
    this.itemDescription,
    this.message,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? value) =>
        value != null ? DateTime.tryParse(value) : null;

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return PaymentResponse(
      paymentId: json['paymentId'] is int
          ? json['paymentId'] as int
          : int.tryParse(json['paymentId']?.toString() ?? ''),
      itemId: json['itemId'] is int
          ? json['itemId'] as int
          : int.tryParse(json['itemId']?.toString() ?? ''),
      amountPaid: parseDouble(json['amountPaid']),
      totalPaid: parseDouble(json['totalPaid']),
      remainingAmount: parseDouble(json['remainingAmount']),
      isFullyPaid: json['isFullyPaid'] as bool?,
      paymentDate: parseDate(json['paymentDate']?.toString()),
      paidBy: json['paidBy']?.toString(),
      supplierName: json['supplierName']?.toString(),
      itemDescription: json['itemDescription']?.toString(),
      message: json['message']?.toString(),
    );
  }
}
