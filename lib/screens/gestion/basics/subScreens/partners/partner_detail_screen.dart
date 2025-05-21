import 'package:flutter/material.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:intl/intl.dart';

class PartnerDetailScreen extends StatelessWidget {
  final Partner partner;

  const PartnerDetailScreen({Key? key, required this.partner})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du Partenaire', textAlign: TextAlign.left),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1E49),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton.icon(
          onPressed: () {},
          label: Text(
            'Nouveau versement',
            style: TextStyle(color: Colors.white),
          ),
          icon: Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildContactInfoCard(),
            const SizedBox(height: 16),
            _buildBalanceCard(currencyFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(NumberFormat currencyFormat) {
    final balance = partner.balance ?? 0.0;
    final isNegative = balance <= 0;
    final statusColor = isNegative ? Colors.red[400] : Colors.green[400];

    final totalVersement =
        partner.versements?.fold(
          0.0,
          (sum, versement) => sum + (versement.montantVerser ?? 0.0),
        ) ??
        0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Balance Actuelle',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]!),
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
                    color: Colors.blue[50],
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
                      "Montant total versé",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      currencyFormat.format(totalVersement),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              Icons.person_3,
              'Client',
              '${partner.firstName} ${partner.lastName} | ${partner.phoneNumber}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'Pays', partner.country),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
