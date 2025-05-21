import 'package:bbd_limited/models/versement.dart';

class Partner {
  final int id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String country;
  final String adresse;
  final String accountType;
  final double? balance;
  List<Versement>? versements;

  Partner({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.country,
    required this.adresse,
    required this.accountType,
    this.balance,
    this.versements,
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
      'balance': balance,
      'versements': versements,
    };
  }

  factory Partner.fromJson(Map<String, dynamic> json) {
    List<Versement> versementList = [];
    if (json['versements'] != null) {
      versementList =
          (json['versements'] as List)
              .map((v) => Versement.fromJson(v))
              .toList();
    }
    return Partner(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      country: json['country'] ?? '',
      adresse: json['adresse'] ?? '',
      accountType: json['accountType'] ?? '',
      balance:
          json['balance'] != null ? (json['balance'] as num).toDouble() : null,
      versements: versementList,
    );
  }
}
