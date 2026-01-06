import 'dart:convert';
import 'package:bbd_limited/models/statistics.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StatisticsService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  Future<List<MostActiveClient>> getMostActiveClients({int limit = 10}) async {
    try {
      final url =
          Uri.parse('$baseUrl/statistics/clients/most-active?limit=$limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonBody =
            json.decode(utf8.decode(response.bodyBytes));
        return jsonBody
            .map((e) => MostActiveClient.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Erreur lors du chargement des clients actifs (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des clients actifs: $e');
    }
  }

  Future<List<MostSolicitedSupplier>> getMostSolicitedSuppliers(
      {int limit = 10}) async {
    try {
      final url = Uri.parse(
          '$baseUrl/statistics/suppliers/most-solicited?limit=$limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonBody =
            json.decode(utf8.decode(response.bodyBytes));
        return jsonBody
            .map((e) =>
                MostSolicitedSupplier.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Erreur lors du chargement des fournisseurs (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des fournisseurs: $e');
    }
  }

  Future<List<MostUsedHarbor>> getMostUsedHarborsForShipping(
      {int limit = 10}) async {
    try {
      final url = Uri.parse(
          '$baseUrl/statistics/harbors/most-used-for-shipping?limit=$limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonBody =
            json.decode(utf8.decode(response.bodyBytes));
        return jsonBody
            .map((e) => MostUsedHarbor.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Erreur lors du chargement des ports d\'envoi (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des ports d\'envoi: $e');
    }
  }

  Future<List<MostUsedHarbor>> getMostUsedHarborsForReceiving(
      {int limit = 10}) async {
    try {
      final url = Uri.parse(
          '$baseUrl/statistics/harbors/most-used-for-receiving?limit=$limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonBody =
            json.decode(utf8.decode(response.bodyBytes));
        return jsonBody
            .map((e) => MostUsedHarbor.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Erreur lors du chargement des ports de réception (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des ports de réception: $e');
    }
  }

  Future<List<MostPurchasedItem>> getMostPurchasedItems(
      {int limit = 10}) async {
    try {
      final url =
          Uri.parse('$baseUrl/statistics/items/most-purchased?limit=$limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonBody =
            json.decode(utf8.decode(response.bodyBytes));
        return jsonBody
            .map((e) => MostPurchasedItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Erreur lors du chargement des produits (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des produits: $e');
    }
  }
}
