import 'dart:convert';

import 'package:bbd_limited/models/payments/payment_response.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PaymentServices {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  Future<List<PaymentResponse>> getPaymentsByItem({
    required int itemId,
  }) async {
    final uri = Uri.parse('$baseUrl/payments/item/$itemId');
    final response = await http.get(uri);

    final decodedBody = response.body.isNotEmpty
        ? json.decode(utf8.decode(response.bodyBytes))
        : <dynamic>[];

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (decodedBody as List<dynamic>)
          .map((e) => PaymentResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      decodedBody is Map<String, dynamic> && decodedBody['message'] != null
          ? decodedBody['message']
          : 'Erreur lors de la récupération des paiements',
    );
  }

  Future<PaymentResponse> processSupplierPayment({
    required int itemId,
    required double amount,
    required DateTime paymentDate,
    required int paidBy,
  }) async {
    final uri = Uri.parse('$baseUrl/payments/supplier');
    final payload = {
      'itemId': itemId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paidBy': paidBy,
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final decodedBody = response.body.isNotEmpty
        ? json.decode(utf8.decode(response.bodyBytes))
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return PaymentResponse.fromJson(
        decodedBody as Map<String, dynamic>,
      );
    }

    throw Exception(
      decodedBody['message'] ??
          'Erreur lors du traitement du paiement fournisseur',
    );
  }
}
