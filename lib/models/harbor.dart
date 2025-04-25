import 'package:bbd_limited/models/container.dart';

class Harbor {
  final int id;
  final String? name;
  final String? location;
  List<Containers>? containers;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final String? userName;
  final int? userId;

  Harbor({
    required this.id,
    this.name,
    this.location,
    this.containers,
    this.createdAt,
    this.editedAt,
    this.userId,
    this.userName,
  });

  factory Harbor.fromJson(Map<String, dynamic> json) {
    List<Containers> containerList = [];
    if (json['containers'] != null) {
      containerList =
          (json['containers'] as List)
              .map((item) => Containers.fromJson(item))
              .toList();
    }

    return Harbor(
      id: json['id'] as int,
      name: json['name'] as String?,
      location: json['location'] as String?,
      userId: json['userid'] as int?,
      userName: json['userName'] as String?,
      containers: containerList,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
    );
  }
}
