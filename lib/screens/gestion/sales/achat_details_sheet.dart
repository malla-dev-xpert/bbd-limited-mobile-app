import 'package:flutter/material.dart';
import 'package:bbd_limited/models/achats/achat.dart';

class AchatDetailsSheet extends StatelessWidget {
  final Achat achat;

  const AchatDetailsSheet({super.key, required this.achat});

  String _formatAmount(double? amount) {
    if (amount == null) return "0,00";
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]} ',
        )
        .replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Détails de l\'achat',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  if (achat.isDebt == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7F78AF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF7F78AF)),
                      ),
                      child: const Text(
                        'Dette',
                        style: TextStyle(
                          color: Color(0xFF7F78AF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
              achat.isDebt == true ? 'Identifiant' : 'Référence',
              achat.isDebt == true
                  ? achat.id.toString()
                  : (achat.referenceVersement ?? "N/A")),
          _buildInfoRow('Client', achat.client ?? "N/A"),
          if (achat.clientPhone != null)
            _buildInfoRow('Téléphone', achat.clientPhone!),
          _buildInfoRow('Montant de l\'achat',
              '${_formatAmount(achat.montantTotal ?? 0)} ¥'),
          const SizedBox(height: 20),
          const Text(
            'Articles achetés',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (achat.items != null && achat.items!.isNotEmpty)
            ...achat.items!.map((item) => _buildItemCard(item))
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Aucun article trouvé'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isAmount ? 18 : 16,
              fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
              color: isAmount ? const Color(0xFF1A1E49) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Items item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.description ?? "N/A",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantité: ${item.quantity ?? 0}',
                style: TextStyle(color: Colors.grey[700]!, fontSize: 15),
              ),
              Text(
                'Prix unitaire: ${_formatAmount(item.unitPrice ?? 0)} ¥',
                style: TextStyle(color: Colors.grey[700]!, fontSize: 15),
              ),
            ],
          ),
          if (item.totalPrice != null) ...[
            const SizedBox(height: 8),
            Text(
              'Total: ${_formatAmount(item.totalPrice ?? 0)} ¥',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1E49),
              ),
            ),
          ],
          if (item.supplierName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.business_outlined,
                  size: 16,
                  color: Colors.grey[700]!,
                ),
                const SizedBox(width: 8),
                Text(
                  item.supplierName!,
                  style: TextStyle(color: Colors.grey[700]!, fontSize: 15),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
