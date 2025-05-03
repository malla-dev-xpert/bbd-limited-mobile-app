import 'package:bbd_limited/core/enums/status.dart';

class Item {
  final int id;
  final String description;
  final double quantity;
  Status status;

  Item copyWith({
    int? id,
    String? description,
    double? quantity,
    Status? status,
  }) {
    return Item(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
    );
  }

  Item({
    required this.id,
    required this.description,
    required this.quantity,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'status': status.name,
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
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
    return Item(
      id: json['id'],
      description: json['description'],
      quantity: json['quantity'],
      status: status,
    );
  }
}
