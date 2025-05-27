import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/edit_package_bottom_sheet.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:intl/intl.dart';

class PackageDetailsBottomSheet extends StatefulWidget {
  final Packages packages;
  final Function(Packages)? onDelete;
  final Function(Packages)? onStart;
  final Function(Packages)? onEdit;

  const PackageDetailsBottomSheet({
    Key? key,
    required this.packages,
    this.onDelete,
    this.onStart,
    this.onEdit,
  }) : super(key: key);

  @override
  State<PackageDetailsBottomSheet> createState() =>
      _PackageDetailsBottomSheetState();
}

class _PackageDetailsBottomSheetState extends State<PackageDetailsBottomSheet> {
  bool _isLoading = false;

  Color _getStatusColor(Status? status) {
    switch (status) {
      case Status.DELIVERED:
        return Colors.lightGreen;
      case Status.RECEIVED:
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
        return 'Arrivée à destination';
      case Status.RECEIVED:
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {},
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 10,
                  children: [
                    widget.packages.status == Status.PENDING
                        ? Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: GestureDetector(
                              onTap: () => _showEditExpeditionDialog(context),
                              child: Icon(
                                Icons.edit,
                                color: Colors.grey[500],
                                size: 20,
                              ),
                            ),
                          )
                        : Container(),
                    Text(
                      'Détails du colis',
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
                      widget.packages.ref ?? 'N/A',
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
                        color: widget.packages.expeditionType?.toLowerCase() ==
                                'avion'
                            ? Colors.amber[50]
                            : Colors.deepPurple[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.packages.expeditionType?.toLowerCase() ==
                                    'avion'
                                ? Icons.airplanemode_active
                                : Icons.directions_boat,
                            size: 16,
                            color:
                                widget.packages.expeditionType?.toLowerCase() ==
                                        'avion'
                                    ? Colors.amber[800]
                                    : Colors.deepPurple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.packages.expeditionType ?? 'N/A',
                            style: TextStyle(
                              color: widget.packages.expeditionType
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
                          widget.packages.status,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.packages.status == Status.RECEIVED ||
                                    widget.packages.status == Status.DELIVERED
                                ? Icons.check_circle
                                : widget.packages.status == Status.INPROGRESS
                                    ? Icons.local_shipping
                                    : Icons.hourglass_empty,
                            size: 16,
                            color: _getStatusColor(widget.packages.status),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusText(widget.packages.status),
                            style: TextStyle(
                              color: _getStatusColor(widget.packages.status),
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
                  widget.packages.startCountry ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Pays de destination',
                  widget.packages.destinationCountry ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Entrepôt',
                  '${widget.packages.warehouseName ?? ''} | ${widget.packages.warehouseAddress ?? ''}'
                      .trim(),
                ),
                const SizedBox(height: 12),
                widget.packages.expeditionType == "Avion"
                    ? _buildInfoRow(
                        'Poids',
                        '${widget.packages.weight ?? 'N/A'} kg',
                      )
                    : _buildInfoRow(
                        'CBN',
                        '${widget.packages.cbn ?? 'N/A'} m³',
                      ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Quantité',
                  '${widget.packages.itemQuantity ?? 'N/A'}',
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Client', widget.packages.clientName ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Téléphone',
                  widget.packages.clientPhone ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Date de départ',
                  DateFormat('dd/MM/yyyy').format(widget.packages.startDate!),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Date d\'arrivée estimée',
                  DateFormat('dd/MM/yyyy').format(widget.packages.arrivalDate!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.packages.status == Status.PENDING) ...[
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
              ] else if (widget.packages.status == Status.INPROGRESS) ...[
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
              ] else if (widget.packages.status == Status.DELIVERED) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showReceivedConfirmationDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: Text(
                      'Confirmer la livraison',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    icon: Icon(Icons.verified, color: Colors.white),
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
            'Êtes-vous sûr de vouloir supprimer ce colis ? Cette action est irréversible.',
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
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      try {
                        final expeditionServices = PackageServices();
                        final result = await expeditionServices
                            .deleteExpedition(widget.packages.id!);

                        if (result == "SUCCESS") {
                          widget.packages.status = Status.DELETE;

                          if (widget.onStart != null) {
                            widget.onStart!(widget.packages);
                          }

                          if (context.mounted) {
                            Navigator.pop(
                              context,
                            ); // Fermer la boîte de dialogue
                            Navigator.pop(context); // Fermer le bottom sheet
                            showSuccessTopSnackBar(
                              context,
                              "Le colis ${widget.packages.ref} a été supprimer avec succès.",
                            );
                          }
                        } else {
                          if (context.mounted) {
                            showErrorTopSnackBar(
                              context,
                              "Erreur de suppression, veuillez réessayer",
                            );
                            setState(() => _isLoading = false);
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          showErrorTopSnackBar(
                            context,
                            "Erreur de suppression",
                          );
                          setState(() => _isLoading = false);
                        }
                      }
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
                    'Êtes-vous sûr de vouloir démarrer l\'expédition du colis ?',
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
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          try {
                            final expeditionServices = PackageServices();
                            final result = await expeditionServices
                                .startExpedition(widget.packages.id!);

                            if (result == "SUCCESS") {
                              widget.packages.status = Status.INPROGRESS;

                              if (widget.onStart != null) {
                                widget.onStart!(widget.packages);
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
                                  "Expédition du colis ${widget.packages.ref} démarrée avec succès.",
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
                    'Êtes-vous sûr de vouloir confirmer l\'arrivée de ce Colis ?',
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
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          try {
                            final expeditionServices = PackageServices();
                            final result = await expeditionServices
                                .deliverExpedition(widget.packages.id!);

                            if (result == "SUCCESS") {
                              widget.packages.status = Status.DELIVERED;

                              if (widget.onStart != null) {
                                widget.onStart!(widget.packages);
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                showSuccessTopSnackBar(
                                  context,
                                  "Colis ${widget.packages.ref} arrivé avec succès.",
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

  Future<void> _showReceivedConfirmationDialog(BuildContext context) async {
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
                    'Êtes-vous sûr de vouloir confirmer la livraison de ce Colis ?',
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
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          try {
                            final expeditionServices = PackageServices();
                            final result = await expeditionServices
                                .receivedExpedition(widget.packages.id!);

                            if (result == "SUCCESS") {
                              widget.packages.status = Status.DELIVERED;

                              if (widget.onStart != null) {
                                widget.onStart!(widget.packages);
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                showSuccessTopSnackBar(
                                  context,
                                  "Colis ${widget.packages.ref} livrée avec succès.",
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

  Future<void> _showEditExpeditionDialog(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return EditPackageBottomSheet(
          packages: widget.packages,
          onSave: (updatedExpedition) async {
            setState(() => _isLoading = true);
            try {
              final expeditionServices = PackageServices();
              final authService = AuthService();
              final user = await authService.getUserInfo();
              final result = await expeditionServices.updateExpedition(
                widget.packages.id!,
                updatedExpedition,
                user!.id,
              );

              if (result == "SUCCESS") {
                if (widget.onEdit != null) {
                  widget.onEdit!(updatedExpedition);
                }

                if (context.mounted) {
                  Navigator.pop(context, true);
                  showSuccessTopSnackBar(
                    context,
                    "Colis ${updatedExpedition.ref} mise à jour avec succès.",
                  );
                }
              } else {
                if (context.mounted) {
                  showErrorTopSnackBar(
                    context,
                    "Erreur de mise à jour, veuillez réessayer",
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                showErrorTopSnackBar(context, "Erreur de mise à jour");
              }
            } finally {
              setState(() => _isLoading = false);
            }
          },
        );
      },
    );

    if (result == true) {
      Navigator.pop(context, true);
    }
  }
}
