class Containers {
  final int id;
  final String name;
  final String location;

  Containers({required this.id, required this.name, required this.location});

  factory Containers.fromJson(Map<String, dynamic> json) {
    return Containers(
      id: json['id'] as int,
      name: json['name'],
      location: json['location'],
    );
  }
}
