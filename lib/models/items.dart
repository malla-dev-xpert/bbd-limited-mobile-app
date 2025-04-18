class Item {
  final int id;
  final String description;
  final double quantity;

  Item({required this.id, required this.description, required this.quantity});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      description: json['description'],
      quantity: json['quantity'],
    );
  }
}
