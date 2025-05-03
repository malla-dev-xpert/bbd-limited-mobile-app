class Partner {
  final int id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String country;
  final String adresse;
  final String accountType;

  Partner({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.country,
    required this.adresse,
    required this.accountType,
  });

  // Convertir Partner en Map (pour JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'email': email,
      'accountType': accountType,
      'adresse': adresse,
      'country': country,
    };
  }

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      country: json['country'] ?? '',
      adresse: json['adresse'] ?? '',
      accountType: json['accountType'] ?? '',
    );
  }
}
