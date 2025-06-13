class CreateAchatDto {
  final int versementId;
  final String invoiceNumber;
  final List<CreateItemDto> items;

  CreateAchatDto(
      {required this.versementId,
      required this.invoiceNumber,
      required this.items});

  Map<String, dynamic> toJson() {
    return {
      'versementId': versementId,
      'invoiceNumber': invoiceNumber,
      'items': items
          .map(
            (item) => {
              'description': item.description,
              'quantity': item.quantity.toInt(),
              'unitPrice': item.unitPrice,
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

  CreateItemDto({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.invoiceNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'invoiceNumber': invoiceNumber,
    };
  }
}
