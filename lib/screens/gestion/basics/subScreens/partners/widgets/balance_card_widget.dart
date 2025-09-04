import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class PartnerBalanceCard extends StatelessWidget {
  final Partner partner;
  final double totalVersementsUSD;

  const PartnerBalanceCard({
    Key? key,
    required this.partner,
    required this.totalVersementsUSD,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final balance = partner.balance ?? 0.0;
    final isNegative = balance <= 0;
    final statusColor = isNegative ? Colors.red[200] : Colors.green[200];
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'CNY',
    );

    return Card(
      elevation: 4,
      color: const Color(0xFF7F78AF),
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/ports.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('current_balance'),
                      style: TextStyle(fontSize: 16, color: Colors.grey[50]!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      isNegative ? Icons.arrow_downward : Icons.arrow_upward,
                      color: statusColor,
                      size: 24,
                    ),
                    Text(
                      currencyFormat.format(balance),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  spacing: 10,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[300]!),
                      ),
                      child: Icon(
                        Icons.attach_money_rounded,
                        color: Colors.blue[600]!,
                        size: 24,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('total_amount_paid'),
                          style: TextStyle(color: Colors.grey[50]),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'fr_FR',
                            symbol: 'CNY',
                          ).format(totalVersementsUSD),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
