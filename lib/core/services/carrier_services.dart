import 'dart:convert';
import 'package:bbd_limited/models/carrier.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CarrierServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<List<Carrier>> getAllCarriers({int page = 0}) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/carriers?page=$page',
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
      return jsonBody.map((e) => Carrier.fromJson(e)).toList();
    } else {
      throw Exception("partner_loading_error");
    }
  }

  Future<String?> updateCarrier(int id, CarrierDto dto, int userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/carriers/update/$id?userId=$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 201) {
        return "UPDATED";
      } else if (response.statusCode == 409) {
        return "CONTACT_EXIST";
      } else {
        throw Exception("carrier_update_error");
      }
    } catch (e) {
      throw Exception("network_error");
    }
  }

  Future<String?> createCarrier(CarrierDto dto, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/carriers/create?userId=$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(dto.toJson()),
      );

      final body = response.body.trim();

      if (body == 'CONTACT_REQUIRED') return "CONTACT_REQUIRED";
      if (body == 'CONTACT_EXIST') return "CONTACT_EXIST";
      if (response.statusCode == 201 || body == 'SUCCESS') return "SUCCESS";

      throw Exception("carrier_creation_error");
    } catch (e) {
      if (e.toString().contains('carrier_creation_error')) rethrow;
      throw Exception("network_error");
    }
  }

  Future<String> deleteCarrier(int id, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/carriers/delete/$id?userId=$userId'),
      );

      if (response.statusCode == 200) {
        return "SUCCESS";
      } else if (response.statusCode == 409) {
        return "CARRIER_LINKED_TO_CONTAINER";
      } else {
        throw Exception("carrier_delete_error");
      }
    } catch (e) {
      throw Exception("network_error");
    }
  }
}
