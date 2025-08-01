class CreateAchatDto {
  final int? versementId;
  final List<CreateItemDto> items;

  CreateAchatDto({this.versementId, required this.items});

  Map<String, dynamic> toJson() {
    return {
      'versementId': versementId,
      'items': items
          .map(
            (item) => {
              'description': item.description,
              'quantity': item.quantity.toInt(),
              'unitPrice': item.unitPrice,
              'invoiceNumber': item.invoiceNumber,
              'supplierId': item.supplierId,
              'salesRate': item.salesRate,
            },
          )
          .toList(),
    };
  }
}

class CreateItemDto {
  final String description;
  final int quantity;
  final double unitPrice;
  final String invoiceNumber;
  final int supplierId;
  final double salesRate;

  CreateItemDto({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.invoiceNumber,
    required this.supplierId,
    required this.salesRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'invoiceNumber': invoiceNumber,
      'supplierId': supplierId,
      'salesRate': salesRate,
    };
  }
}
