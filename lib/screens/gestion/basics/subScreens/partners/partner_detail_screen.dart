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

    final partnerName =
        "${partner.firstName} ${partner.lastName} | ${partner.phoneNumber}";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          partnerName,
          textAlign: TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
            _buildBalanceCard(currencyFormat),
            const SizedBox(height: 16),
            _buildVersementsList(currencyFormat),
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
        color: Colors.grey[50],
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

  Widget _buildVersementsList(NumberFormat currencyFormat) {
    if (partner.versements == null || partner.versements!.isEmpty) {
      return Center(
        child: Text(
          'Aucun versement trouvé',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              'Historique des versements',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: partner.versements!.length,
            itemBuilder: (context, index) {
              final versement = partner.versements![index];
              final montantRestant = versement.montantRestant ?? 0.0;
              final isNegative = montantRestant < 0;
              final statusColor =
                  isNegative ? Colors.red[400] : Colors.green[400];

              return Container(
                padding: EdgeInsets.all(0),
                child: ListTile(
                  title: Text(
                    versement.reference ?? 'Sans référence',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    versement.createdAt != null
                        ? DateFormat('dd/MM/yyyy').format(versement.createdAt!)
                        : 'Date inconnue',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 5,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(versement.montantVerser),
                            style: TextStyle(fontSize: 13, color: Colors.blue),
                          ),
                          Text(
                            currencyFormat.format(versement.montantRestant),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        isNegative ? Icons.arrow_downward : Icons.arrow_upward,
                        color: statusColor,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
