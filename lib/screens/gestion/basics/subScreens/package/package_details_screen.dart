import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/edit_package_bottom_sheet.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/add_items_to_package_modal.dart';

class PackageDetailsScreen extends StatefulWidget {
  final Packages packages;
  final Function(Packages)? onDelete;
  final Function(Packages)? onStart;
  final Function(Packages)? onEdit;

  const PackageDetailsScreen({
    Key? key,
    required this.packages,
    this.onDelete,
    this.onStart,
    this.onEdit,
  }) : super(key: key);

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  bool _isLoading = false;
  bool _isLoadingItems = false;
  List<Items> _items = [];
  final ItemServices _itemServices = ItemServices();
  DateTime? selectedDeliveryDate;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    if (widget.packages.id == null) return;

    setState(() {
      _isLoadingItems = true;
    });

    try {
      final items = await _itemServices.findByPackageId(widget.packages.id!);
      setState(() {
        _items = items;
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingItems = false;
      });
      if (mounted) {
        showErrorTopSnackBar(context, "Erreur lors du chargement des articles");
      }
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du colis'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1E49),
        elevation: 0,
        actions: [
          if (widget.packages.status == Status.PENDING)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(right: 10),
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
            ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
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
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                widget.packages.expeditionType?.toLowerCase() ==
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
                                color: widget.packages.expeditionType
                                            ?.toLowerCase() ==
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
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
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
                                        widget.packages.status ==
                                            Status.DELIVERED
                                    ? Icons.check_circle
                                    : widget.packages.status ==
                                            Status.INPROGRESS
                                        ? Icons.local_shipping
                                        : Icons.hourglass_empty,
                                size: 16,
                                color: _getStatusColor(widget.packages.status),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getStatusText(widget.packages.status),
                                style: TextStyle(
                                  color:
                                      _getStatusColor(widget.packages.status),
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
                      'Port de départ',
                      widget.packages.startCountry ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Port d\'arrivée',
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
                    _buildInfoRow(
                        'Client', widget.packages.clientName ?? 'N/A'),
                    const SizedBox(height: 12),
                    if (widget.packages.clientPhone != null)
                      _buildInfoRow(
                        'Téléphone',
                        widget.packages.clientPhone ?? 'N/A',
                      ),
                    if (widget.packages.clientPhone != null)
                      const SizedBox(height: 12),
                    _buildInfoRow(
                      'Date de départ',
                      widget.packages.startDate != null
                          ? DateFormat('dd/MM/yyyy')
                              .format(widget.packages.startDate!)
                          : 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Date d\'arrivée estimée',
                      widget.packages.arrivalDate != null
                          ? DateFormat('dd/MM/yyyy')
                              .format(widget.packages.arrivalDate!)
                          : 'N/A',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '(${_items.length}) Articles',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1E49),
                          ),
                    ),
                  ),
                  if (widget.packages.status == Status.PENDING) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                          onPressed: () async {
                            final clientId = widget.packages.clientId;
                            if (clientId == null) {
                              showErrorTopSnackBar(
                                  context, "Client inconnu pour ce colis");
                              return;
                            }
                            // Récupérer les IDs des articles déjà dans le colis
                            final alreadyInPackageIds =
                                _items.map((e) => e.id!).toList();
                            final result = await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (context) {
                                return SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.7,
                                  child: AddItemsToPackageModal(
                                    clientId: clientId,
                                    alreadyInPackageIds: alreadyInPackageIds,
                                    onValidate: (selectedItems) async {
                                      final user =
                                          await AuthService().getUserInfo();
                                      if (user == null || user.id == null) {
                                        showErrorTopSnackBar(context,
                                            "Utilisateur non connecté");
                                        return;
                                      }
                                      final result = await PackageServices()
                                          .addItemsToPackage(
                                        packageId: widget.packages.id!,
                                        itemIds: selectedItems
                                            .map((e) => e.id!)
                                            .toList(),
                                        userId: user.id,
                                      );
                                      if (result == "SUCCESS") {
                                        await _loadItems();
                                        Navigator.pop(context, true);
                                        showSuccessTopSnackBar(context,
                                            "Articles ajoutés au colis avec succès");
                                      } else {
                                        showErrorTopSnackBar(context, result);
                                      }
                                    },
                                  ),
                                );
                              },
                            );
                            if (result == true) {
                              showSuccessTopSnackBar(context,
                                  "Articles ajoutés au colis avec succès");
                            }
                          },
                          label: const Text("Ajouter des articles",
                              overflow: TextOverflow.ellipsis),
                          icon: const Icon(Icons.add)),
                    )
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // items lists section
              _buildItemsSection(),
              const SizedBox(height: 24),
              // actions buttons
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
                        icon: const Icon(Icons.delete, color: Colors.white),
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
                        label: const Text(
                          'Expédier',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        icon: const Icon(
                          Icons.check_circle_outline_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ] else if (widget.packages.status == Status.INPROGRESS) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showDeliveryConfirmationDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: const Text(
                          'Arrivée à destination',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        icon: const Icon(Icons.local_shipping,
                            color: Colors.white),
                      ),
                    ),
                  ] else if (widget.packages.status == Status.DELIVERED) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showReceivedConfirmationDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: const Text(
                          'Confirmer la livraison',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        icon: const Icon(Icons.verified, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        Expanded(
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
                            Navigator.pop(context);
                            Navigator.pop(context);
                            showSuccessTopSnackBar(
                              context,
                              "Le colis 24{widget.packages.ref} a été supprimer avec succès.",
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
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
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
                                Navigator.pop(context);
                                Navigator.pop(context);
                                showSuccessTopSnackBar(
                                  context,
                                  "Expédition du colis 24{widget.packages.ref} démarrée avec succès.",
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
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
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
                                  "Colis 24{widget.packages.ref} arrivé avec succès.",
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
    DateTime? tempSelectedDate = selectedDeliveryDate;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Êtes-vous sûr de vouloir confirmer la livraison de ce Colis ?',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      tempSelectedDate != null
                          ? 'Date de livraison : '
                              '${DateFormat('dd/MM/yyyy').format(tempSelectedDate!)}'
                          : 'Choisir la date de livraison (optionnel)',
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempSelectedDate ?? now,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 2),
                      );
                      if (picked != null) {
                        setState(() {
                          tempSelectedDate = picked;
                        });
                      }
                    },
                  ),
                  if (tempSelectedDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Date sélectionnée : '
                        '${DateFormat('dd/MM/yyyy').format(tempSelectedDate!)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (tempSelectedDate == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Si aucune date n\'est choisie, la date du jour sera utilisée.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
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
                                  "Colis 24{widget.packages.ref} livrée avec succès.",
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
                    "Colis 24{updatedExpedition.ref} mise à jour avec succès.",
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

  Widget _buildItemsSection() {
    if (_isLoadingItems) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text(
            'Aucun article dans ce colis',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: _items.map((item) => _buildItemRow(item)).toList(),
      ),
    );
  }

  Widget _buildItemRow(Items item) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.description ?? 'Sans description',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Qté: ${item.quantity ?? 0}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (item.supplierName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${item.supplierName} | ${item.supplierPhone}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (item.unitPrice != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Prix unitaire: ${item.unitPrice!.toStringAsFixed(2)} ¥',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Prix total: ${item.totalPrice!.toStringAsFixed(2)} ¥',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.percent,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Taux d\'achat: ${item.salesRate} ¥',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
