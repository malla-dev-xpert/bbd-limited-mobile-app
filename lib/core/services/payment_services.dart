import 'dart:convert';

import 'package:bbd_limited/models/payments/payment_response.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PaymentServices {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

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
