import 'package:flutter/material.dart';
import 'package:bbd_limited/models/achats/achat.dart';

class AchatDetailsSheet extends StatelessWidget {
  final Achat achat;

  const AchatDetailsSheet({super.key, required this.achat});

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
              const Text(
                'Détails de l\'achat',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Référence', achat.referenceVersement ?? "N/A"),
          _buildInfoRow('Client', achat.client ?? "N/A"),
          if (achat.clientPhone != null)
            _buildInfoRow('Téléphone', achat.clientPhone!),
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
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                'Prix unitaire: ${item.unitPrice?.toStringAsFixed(2) ?? "0"} €',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          if (item.totalPrice != null) ...[
            const SizedBox(height: 8),
            Text(
              'Total: ${item.totalPrice?.toStringAsFixed(2)} €',
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
                const Icon(
                  Icons.business_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  item.supplierName!,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
