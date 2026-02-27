import 'dart:convert';
import 'package:bbd_limited/models/carrier.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CarrierServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<List<Carrier>> getAllCarriers({int page = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/carriers?page=$page'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
      // Le backend retourne une Page<Carriers>, on récupère la liste dans 'content'
      final List<dynamic> content = jsonBody['content'] ?? [];
      return content.map((e) => Carrier.fromJson(e)).toList();
    } else {
      throw Exception("carrier_loading_error");
    }
  }

  Future<String?> createCarrier(CarrierDto dto, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/carriers/create?userId=$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 201) {
        return "CREATED";
      } else if (response.statusCode == 409 &&
          response.body == 'Contact déjà utilisé !') {
        return "CONTACT_EXIST";
      } else {
        throw Exception("carrier_creation_error");
      }
    } catch (e) {
      throw Exception("network_error");
    }
  }
}
