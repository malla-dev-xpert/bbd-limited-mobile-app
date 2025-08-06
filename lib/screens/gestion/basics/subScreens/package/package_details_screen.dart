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
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/localization/translation_helper.dart';

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
        title: Text(
            AppLocalizations.of(context).translate('package_details_title')),
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
                          AppLocalizations.of(context)
                              .translate('package_reference'),
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        Text(
                          widget.packages.ref ??
                              AppLocalizations.of(context).translate('na'),
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
                          AppLocalizations.of(context)
                              .translate('package_type'),
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
                                widget.packages.expeditionType ??
                                    AppLocalizations.of(context)
                                        .translate('na'),
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
                          AppLocalizations.of(context)
                              .translate('package_status'),
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
                    const SizedBox(height: 12),
                    if (widget.packages.receivedDate != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate('package_delivered_on'),
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy')
                                .format(widget.packages.receivedDate!),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)
                    .translate('package_additional_info'),
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
                      AppLocalizations.of(context)
                          .translate('package_start_port'),
                      widget.packages.startCountry ??
                          AppLocalizations.of(context).translate('na'),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      AppLocalizations.of(context)
                          .translate('package_destination_port'),
                      widget.packages.destinationCountry ??
                          AppLocalizations.of(context).translate('na'),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      AppLocalizations.of(context)
                          .translate('package_warehouse'),
                      '${widget.packages.warehouseName ?? ''} | ${widget.packages.warehouseAddress ?? ''}'
                          .trim(),
                    ),
                    const SizedBox(height: 12),
                    widget.packages.expeditionType == "Avion"
                        ? _buildInfoRow(
                            AppLocalizations.of(context)
                                .translate('package_weight'),
                            '${widget.packages.weight ?? AppLocalizations.of(context).translate('na')} ${AppLocalizations.of(context).translate('kg')}',
                          )
                        : _buildInfoRow(
                            AppLocalizations.of(context)
                                .translate('package_cbn'),
                            '${widget.packages.cbn ?? AppLocalizations.of(context).translate('na')} ${AppLocalizations.of(context).translate('m3')}',
                          ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      AppLocalizations.of(context)
                          .translate('package_quantity'),
                      '${widget.packages.itemQuantity ?? AppLocalizations.of(context).translate('na')}',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                        AppLocalizations.of(context)
                            .translate('package_client'),
                        widget.packages.clientName ??
                            AppLocalizations.of(context).translate('na')),
                    const SizedBox(height: 12),
                    if (widget.packages.clientPhone != null)
                      _buildInfoRow(
                        AppLocalizations.of(context).translate('package_phone'),
                        widget.packages.clientPhone ??
                            AppLocalizations.of(context).translate('na'),
                      ),
                    if (widget.packages.clientPhone != null)
                      const SizedBox(height: 12),
                    _buildInfoRow(
                      AppLocalizations.of(context)
                          .translate('package_start_date'),
                      widget.packages.startDate != null
                          ? DateFormat('dd/MM/yyyy')
                              .format(widget.packages.startDate!)
                          : AppLocalizations.of(context).translate('na'),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      AppLocalizations.of(context)
                          .translate('package_estimated_arrival_date'),
                      widget.packages.arrivalDate != null
                          ? DateFormat('dd/MM/yyyy')
                              .format(widget.packages.arrivalDate!)
                          : AppLocalizations.of(context).translate('na'),
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
                      '(${_items.length}) ${AppLocalizations.of(context).translate('package_items')}',
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
                                  context,
                                  AppLocalizations.of(context)
                                      .translate('unknown_client_for_package'));
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
                                        showErrorTopSnackBar(
                                            context,
                                            AppLocalizations.of(context)
                                                .translate(
                                                    'user_not_logged_in'));
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
                                        showSuccessTopSnackBar(
                                            context,
                                            AppLocalizations.of(context).translate(
                                                'items_added_to_package_success'));
                                      } else {
                                        showErrorTopSnackBar(context, result);
                                      }
                                    },
                                  ),
                                );
                              },
                            );
                            if (result == true) {
                              showSuccessTopSnackBar(
                                  context,
                                  AppLocalizations.of(context).translate(
                                      'items_added_to_package_success'));
                            }
                          },
                          label: Text(
                              AppLocalizations.of(context)
                                  .translate('add_items'),
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
                        label: Text(
                          AppLocalizations.of(context).translate('delete'),
                          style: const TextStyle(
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
                        label: Text(
                          AppLocalizations.of(context).translate('expedite'),
                          style: const TextStyle(
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
                        label: Text(
                          AppLocalizations.of(context)
                              .translate('arrive_at_destination'),
                          style: const TextStyle(
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
                        label: Text(
                          AppLocalizations.of(context)
                              .translate('confirm_delivery'),
                          style: const TextStyle(
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
              Text(AppLocalizations.of(context).translate('confirmation')),
            ],
          ),
          content: Text(
            AppLocalizations.of(context).translate('confirm_delete_package'),
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context).translate('cancel'),
                style: const TextStyle(color: Colors.grey),
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
                              TranslationHelper.tWithParams(
                                  context,
                                  'expedition_deleted_success',
                                  {'ref': widget.packages.ref ?? ''}),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            showErrorTopSnackBar(
                              context,
                              AppLocalizations.of(context)
                                  .translate('delete_error'),
                            );
                            setState(() => _isLoading = false);
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          showErrorTopSnackBar(
                            context,
                            AppLocalizations.of(context)
                                .translate('delete_error'),
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
              child: Text(
                AppLocalizations.of(context).translate('delete'),
                style: const TextStyle(color: Colors.white),
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
                  Text(AppLocalizations.of(context).translate('confirmation')),
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
                  child: Text(
                    AppLocalizations.of(context).translate('cancel'),
                    style: const TextStyle(color: Colors.grey),
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
                                  AppLocalizations.of(context)
                                      .translate('expedition_started_success')
                                      .replaceAll(
                                          '{ref}', widget.packages.ref ?? ''),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                showErrorTopSnackBar(
                                  context,
                                  AppLocalizations.of(context)
                                      .translate('start_expedition_error'),
                                );
                                setState(() => _isLoading = false);
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showErrorTopSnackBar(
                                context,
                                AppLocalizations.of(context)
                                    .translate('start_expedition_error'),
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
                    _isLoading
                        ? AppLocalizations.of(context).translate('starting')
                        : AppLocalizations.of(context).translate('start'),
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
                  Text(AppLocalizations.of(context).translate('confirmation')),
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
                  child: Text(
                    AppLocalizations.of(context).translate('cancel'),
                    style: const TextStyle(color: Colors.grey),
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
                                  AppLocalizations.of(context)
                                      .translate('expedition_arrived_success')
                                      .replaceAll(
                                          '{ref}', widget.packages.ref ?? ''),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                showErrorTopSnackBar(
                                  context,
                                  AppLocalizations.of(context)
                                      .translate('confirm_delivery_error'),
                                );
                                setState(() => _isLoading = false);
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showErrorTopSnackBar(
                                context,
                                AppLocalizations.of(context)
                                    .translate('confirm_delivery_error'),
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
                    _isLoading
                        ? AppLocalizations.of(context).translate('confirming')
                        : AppLocalizations.of(context).translate('confirm'),
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
                  Text(AppLocalizations.of(context).translate('confirmation')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)
                        .translate('confirm_package_delivery'),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      tempSelectedDate != null
                          ? '${AppLocalizations.of(context).translate('delivery_date')}: ${DateFormat('dd/MM/yyyy').format(tempSelectedDate!)}'
                          : AppLocalizations.of(context)
                              .translate('select_delivery_date'),
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
                        '${AppLocalizations.of(context).translate('selected_date')}: ${DateFormat('dd/MM/yyyy').format(tempSelectedDate!)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (tempSelectedDate == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        AppLocalizations.of(context)
                            .translate('no_date_selected_info'),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    AppLocalizations.of(context).translate('cancel'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          try {
                            final deliveryDate =
                                tempSelectedDate ?? DateTime.now();
                            final expeditionServices = PackageServices();
                            print("Date==========" + deliveryDate.toString());
                            final user = await AuthService().getUserInfo();
                            final result =
                                await expeditionServices.receivedExpedition(
                                    widget.packages.id!,
                                    user!.id,
                                    deliveryDate);

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
                                  AppLocalizations.of(context)
                                      .translate('expedition_delivered_success')
                                      .replaceAll(
                                          '{ref}', widget.packages.ref ?? ''),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                showErrorTopSnackBar(
                                  context,
                                  AppLocalizations.of(context)
                                      .translate('confirm_delivery_error'),
                                );
                                setState(() => _isLoading = false);
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showErrorTopSnackBar(
                                context,
                                AppLocalizations.of(context)
                                    .translate('confirm_delivery_error'),
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
                    _isLoading
                        ? AppLocalizations.of(context).translate('confirming')
                        : AppLocalizations.of(context).translate('confirm'),
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
                    AppLocalizations.of(context)
                        .translate('expedition_updated_success')
                        .replaceAll('{ref}', updatedExpedition.ref ?? ''),
                  );
                }
              } else {
                if (context.mounted) {
                  showErrorTopSnackBar(
                    context,
                    AppLocalizations.of(context).translate('update_error'),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                showErrorTopSnackBar(context,
                    AppLocalizations.of(context).translate('update_error'));
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
        child: Center(
          child: Text(
            AppLocalizations.of(context).translate('no_items_in_package'),
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
                    item.description ??
                        AppLocalizations.of(context)
                            .translate('no_description'),
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
                    '${AppLocalizations.of(context).translate('item_quantity')}: ${item.quantity ?? 0}',
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
                    '${AppLocalizations.of(context).translate('unit_price')}: ${item.unitPrice!.toStringAsFixed(2)} ¥',
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
                  '${AppLocalizations.of(context).translate('total_price')}: ${item.totalPrice!.toStringAsFixed(2)} ¥',
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
                  '${AppLocalizations.of(context).translate('purchase_rate')}: ${item.salesRate} ¥',
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
