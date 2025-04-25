class Containers {
  final String? reference;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final bool? isAvailable;

  Containers({this.reference, this.createdAt, this.editedAt, this.isAvailable});

  factory Containers.fromJson(Map<String, dynamic> json) {
    return Containers(
      reference: json['reference'] as String?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      isAvailable: json['isAvailable'] as bool?,
    );
  }
}
