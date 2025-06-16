import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  static const String exchangeRateBaseUrl =
      'https://open.er-api.com/v6/latest/CNY';

  Future<double> getExchangeRate(String fromCurrency) async {
    try {
      final response = await http.get(Uri.parse(exchangeRateBaseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          final rates = data['rates'] as Map<String, dynamic>;
          return rates[fromCurrency]?.toDouble() ?? 0.0;
        } else {
          throw Exception('API returned unsuccessful result');
        }
      } else {
        throw Exception('Failed to load exchange rate');
      }
    } catch (e) {
      log('Error fetching exchange rate: $e');
      return 0.0;
    }
  }
}
