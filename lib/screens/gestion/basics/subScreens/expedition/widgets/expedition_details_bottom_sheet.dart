import 'package:flutter/material.dart';
import 'package:bbd_limited/models/expedition.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:intl/intl.dart';

class ExpeditionDetailsBottomSheet extends StatelessWidget {
  final Expedition expedition;

  const ExpeditionDetailsBottomSheet({Key? key, required this.expedition})
    : super(key: key);

  Color _getStatusColor(Status? status) {
    switch (status) {
      case Status.DELIVERED:
        return Colors.green;
      case Status.INPROGRESS:
        return Colors.orange;
      case Status.PENDING:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(Status? status) {
    switch (status) {
      case Status.DELIVERED:
        return 'Livrée';
      case Status.INPROGRESS:
        return 'En transit';
      case Status.PENDING:
        return 'En attente';
      default:
        return 'Inconnu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {},
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.edit,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                    ),
                    Text(
                      'Détails de l\'expédition',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1E49),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Référence',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Text(
                      expedition.ref ?? 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Type',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            expedition.expeditionType?.toLowerCase() == 'avion'
                                ? Colors.amber[50]
                                : Colors.deepPurple[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            expedition.expeditionType?.toLowerCase() == 'avion'
                                ? Icons.airplanemode_active
                                : Icons.directions_boat,
                            size: 16,
                            color:
                                expedition.expeditionType?.toLowerCase() ==
                                        'avion'
                                    ? Colors.amber[800]
                                    : Colors.deepPurple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            expedition.expeditionType ?? 'N/A',
                            style: TextStyle(
                              color:
                                  expedition.expeditionType?.toLowerCase() ==
                                          'avion'
                                      ? Colors.amber[800]
                                      : Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Statut',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          expedition.status,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            expedition.status == Status.DELIVERED
                                ? Icons.check_circle
                                : expedition.status == Status.INPROGRESS
                                ? Icons.local_shipping
                                : Icons.hourglass_empty,
                            size: 16,
                            color: _getStatusColor(expedition.status),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusText(expedition.status),
                            style: TextStyle(
                              color: _getStatusColor(expedition.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Informations supplémentaires',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1E49),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  'Pays de départ',
                  expedition.startCountry ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Pays de destination',
                  expedition.destinationCountry ?? 'N/A',
                ),
                const SizedBox(height: 12),
                expedition.expeditionType == "avion"
                    ? _buildInfoRow('Poids', '${expedition.weight ?? 'N/A'} kg')
                    : _buildInfoRow('CBN', '${expedition.cbn ?? 'N/A'} m³'),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Quantité',
                  '${expedition.itemQuantity ?? 'N/A'}',
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Client', expedition.clientName ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow('Téléphone', expedition.clientPhone ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Date de départ',
                  DateFormat('dd/MM/yyyy').format(expedition.startDate!),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Date d\'arrivée estimée',
                  DateFormat('dd/MM/yyyy').format(expedition.arrivalDate!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement edit functionality
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: const Text(
                    'Supprimer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  icon: Icon(Icons.delete, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: Text(
                    'Démarer l\'expédition',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  icon: Icon(
                    Icons.check_circle_outline_outlined,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 10,
      children: [
        Expanded(
          // flex: 2,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        Expanded(
          // flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
