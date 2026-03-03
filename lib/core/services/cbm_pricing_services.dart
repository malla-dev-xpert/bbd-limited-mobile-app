import 'dart:convert';
import 'package:bbd_limited/models/cbm_pricing.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CbmPricingServices {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  Future<List<CbmPricing>> findAll({int page = 0, int size = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cbm-pricing?page=$page&size=$size'),
      );

      if (response.statusCode == 200) {
        final jsonBody = json.decode(utf8.decode(response.bodyBytes));

        // Handle both paginated (with 'content' field) and flat list responses
        if (jsonBody is Map && jsonBody.containsKey('content')) {
          final List<dynamic> content = jsonBody['content'];
          return content.map((e) => CbmPricing.fromJson(e)).toList();
        } else if (jsonBody is List) {
          return jsonBody.map((e) => CbmPricing.fromJson(e)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception("cbm_pricing_loading_error");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<CbmPricing> create(CbmPricing pricing) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cbm-pricing'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(pricing.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonBody = json.decode(utf8.decode(response.bodyBytes));
        return CbmPricing.fromJson(jsonBody);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'cbm_pricing_create_error');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<CbmPricing> update(int id, CbmPricing pricing) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/cbm-pricing/$id'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(pricing.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonBody = json.decode(utf8.decode(response.bodyBytes));
        return CbmPricing.fromJson(jsonBody);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'cbm_pricing_update_error');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cbm-pricing/$id'),
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception("cbm_pricing_delete_error");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<CbmPricing?> findByCbmValue(double value) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cbm-pricing/by-cbm/$value'),
      );

      if (response.statusCode == 200) {
        final jsonBody = json.decode(utf8.decode(response.bodyBytes));
        return CbmPricing.fromJson(jsonBody);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception("cbm_pricing_find_by_value_error");
      }
    } catch (e) {
      rethrow;
    }
  }
}
