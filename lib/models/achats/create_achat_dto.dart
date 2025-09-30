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
              'carton': item.carton,
              'quantityPerCarton': item.quantityPerCarton,
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
  final int carton; // Nouveau champ : nombre de cartons
  final int quantityPerCarton; // Nouveau champ : quantité par carton
  final double unitPrice;
  final String invoiceNumber;
  final int supplierId;
  final double salesRate;

  CreateItemDto({
    required this.description,
    required this.quantity,
    required this.carton,
    required this.quantityPerCarton,
    required this.unitPrice,
    required this.invoiceNumber,
    required this.supplierId,
    required this.salesRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'carton': carton,
      'quantityPerCarton': quantityPerCarton,
      'unitPrice': unitPrice,
      'invoiceNumber': invoiceNumber,
      'supplierId': supplierId,
      'salesRate': salesRate,
    };
  }
}
