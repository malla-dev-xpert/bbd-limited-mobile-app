import 'package:bbd_limited/core/services/expedition_services.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/expedition.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:intl/intl.dart';

class ExpeditionDetailsBottomSheet extends StatefulWidget {
  final Expedition expedition;
  final Function(Expedition)? onDelete;
  final Function(Expedition)? onStart;

  const ExpeditionDetailsBottomSheet({
    Key? key,
    required this.expedition,
    this.onDelete,
    this.onStart,
  }) : super(key: key);

  @override
  State<ExpeditionDetailsBottomSheet> createState() =>
      _ExpeditionDetailsBottomSheetState();
}

class _ExpeditionDetailsBottomSheetState
    extends State<ExpeditionDetailsBottomSheet> {
  bool _isLoading = false;

  Color _getStatusColor(Status? status) {
    switch (status) {
      case Status.DELIVERED:
        return Colors.green;
      case Status.INPROGRESS:
        return Colors.purple;
      case Status.PENDING:
        return Colors.orange;
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
                    widget.expedition.status == Status.PENDING
                        ? Container(
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
                        )
                        : Container(),
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
                      widget.expedition.ref ?? 'N/A',
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
                            widget.expedition.expeditionType?.toLowerCase() ==
                                    'avion'
                                ? Colors.amber[50]
                                : Colors.deepPurple[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.expedition.expeditionType?.toLowerCase() ==
                                    'avion'
                                ? Icons.airplanemode_active
                                : Icons.directions_boat,
                            size: 16,
                            color:
                                widget.expedition.expeditionType
                                            ?.toLowerCase() ==
                                        'avion'
                                    ? Colors.amber[800]
                                    : Colors.deepPurple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.expedition.expeditionType ?? 'N/A',
                            style: TextStyle(
                              color:
                                  widget.expedition.expeditionType
                                              ?.toLowerCase() ==
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
                          widget.expedition.status,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.expedition.status == Status.DELIVERED
                                ? Icons.check_circle
                                : widget.expedition.status == Status.INPROGRESS
                                ? Icons.local_shipping
                                : Icons.hourglass_empty,
                            size: 16,
                            color: _getStatusColor(widget.expedition.status),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusText(widget.expedition.status),
                            style: TextStyle(
                              color: _getStatusColor(widget.expedition.status),
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
                  widget.expedition.startCountry ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Pays de destination',
                  widget.expedition.destinationCountry ?? 'N/A',
                ),
                const SizedBox(height: 12),
                widget.expedition.expeditionType == "avion"
                    ? _buildInfoRow(
                      'Poids',
                      '${widget.expedition.weight ?? 'N/A'} kg',
                    )
                    : _buildInfoRow(
                      'CBN',
                      '${widget.expedition.cbn ?? 'N/A'} m³',
                    ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Quantité',
                  '${widget.expedition.itemQuantity ?? 'N/A'}',
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Client', widget.expedition.clientName ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Téléphone',
                  widget.expedition.clientPhone ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Date de départ',
                  DateFormat('dd/MM/yyyy').format(widget.expedition.startDate!),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Date d\'arrivée estimée',
                  DateFormat(
                    'dd/MM/yyyy',
                  ).format(widget.expedition.arrivalDate!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.expedition.status == Status.PENDING) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmationDialog(context),
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
                    onPressed: () => _showStartConfirmationDialog(context),
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
              ] else if (widget.expedition.status == Status.INPROGRESS) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeliveryConfirmationDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: Text(
                      'Arrivée à destination',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    icon: Icon(Icons.local_shipping, color: Colors.white),
                  ),
                ),
              ],
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

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[400]),
              const SizedBox(width: 8),
              const Text('Confirmation'),
            ],
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette expédition ? Cette action est irréversible.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (widget.onDelete != null) {
                  widget.onDelete!(widget.expedition);
                }
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showStartConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green[400]),
                  const SizedBox(width: 8),
                  const Text('Confirmation'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Êtes-vous sûr de vouloir démarrer cette expédition ?',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () async {
                            setState(() => _isLoading = true);
                            try {
                              final expeditionServices = ExpeditionServices();
                              final result = await expeditionServices
                                  .startExpedition(widget.expedition.id!);

                              if (result == "SUCCESS") {
                                widget.expedition.status = Status.INPROGRESS;

                                if (widget.onStart != null) {
                                  widget.onStart!(widget.expedition);
                                }

                                if (context.mounted) {
                                  Navigator.pop(
                                    context,
                                  ); // Fermer la boîte de dialogue
                                  Navigator.pop(
                                    context,
                                  ); // Fermer le bottom sheet
                                  showSuccessTopSnackBar(
                                    context,
                                    "Expédition ${widget.expedition.ref} démarrée avec succès.",
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  showErrorTopSnackBar(
                                    context,
                                    "Erreur de démarrage, veuillez réessayer",
                                  );
                                  setState(() => _isLoading = false);
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showErrorTopSnackBar(
                                  context,
                                  "Erreur de démarrage",
                                );
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isLoading ? 'Démarrage...' : 'Démarrer',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeliveryConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green[400]),
                  const SizedBox(width: 8),
                  const Text('Confirmation'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Êtes-vous sûr de vouloir confirmer l\'arrivée de cette expédition ?',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () async {
                            setState(() => _isLoading = true);
                            try {
                              final expeditionServices = ExpeditionServices();
                              final result = await expeditionServices
                                  .deliverExpedition(widget.expedition.id!);

                              if (result == "SUCCESS") {
                                widget.expedition.status = Status.DELIVERED;

                                if (widget.onStart != null) {
                                  widget.onStart!(widget.expedition);
                                }

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  showSuccessTopSnackBar(
                                    context,
                                    "Expédition ${widget.expedition.ref} livrée avec succès.",
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  showErrorTopSnackBar(
                                    context,
                                    "Erreur de confirmation, veuillez réessayer",
                                  );
                                  setState(() => _isLoading = false);
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showErrorTopSnackBar(
                                  context,
                                  "Erreur de confirmation",
                                );
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isLoading ? 'Confirmation...' : 'Confirmer',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
