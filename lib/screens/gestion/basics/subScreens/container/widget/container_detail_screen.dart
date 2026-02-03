import 'package:bbd_limited/components/item_detail_chip.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/pages/embark_items_page.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/utils/amount_format.dart';

class ContainerDetailPage extends StatefulWidget {
  final Containers container;
  final Function(Containers)? onContainerUpdated;

  const ContainerDetailPage(
      {Key? key, required this.container, this.onContainerUpdated})
      : super(key: key);

  @override
  State<ContainerDetailPage> createState() => _ContainerDetailPageState();
}

class _ContainerDetailPageState extends State<ContainerDetailPage> {
  late Containers container;
  bool isLoading = false;
  String searchQuery = '';
  DateTime? selectedDeliveryDate; // Ajout pour la date de livraison
  final ContainerServices containerServices = ContainerServices();
  final AuthService authService = AuthService();
  final PackageServices packageServices = PackageServices();
  final ItemServices itemServices = ItemServices();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    container = widget.container;
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text;
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(Status? status) {
    switch (status) {
      case Status.PENDING:
        return Colors.orange;
      case Status.INPROGRESS:
        return Colors.purple;
      case Status.RECEIVED:
        return Colors.green;
      case Status.DELIVERED:
        return Colors.lightGreen;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(Status? status) {
    switch (status) {
      case Status.PENDING:
        return AppLocalizations.of(context).translate('container_pending');
      case Status.INPROGRESS:
        return AppLocalizations.of(context).translate('container_in_progress');
      case Status.RECEIVED:
        return AppLocalizations.of(context).translate('container_arrived');
      case Status.DELIVERED:
        return AppLocalizations.of(context).translate('container_arrived');
      default:
        return AppLocalizations.of(context).translate('status_unknown');
    }
  }

  Widget _infoRow(String label, String? value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 17),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowWithFormattedValue(String label, Widget valueWidget,
      {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 17),
            ),
          ),
          Expanded(
            child: valueWidget,
          ),
        ],
      ),
    );
  }

  /// Total des frais en CNY : somme des montants convertis en CNY fournis par le backend.
  static double _totalFeesCNY(Containers c) {
    return (c.locationFeeCNY ?? 0) +
        (c.localChargeCNY ?? 0) +
        (c.loadingFeeCNY ?? 0) +
        (c.overweightFeeCNY ?? 0) +
        (c.checkingFeeCNY ?? 0) +
        (c.telxFeeCNY ?? 0) +
        (c.otherFeesCNY ?? 0) +
        (c.marginCNY ?? 0);
  }

  /// Affiche un montant. amountCNY uniquement si renvoyé par l'API (jamais de calcul côté Flutter).
  Widget _formatFeeWidget({
    required double? amount,
    required String? currencyCode,
    double? amountCNY,
  }) {
    if (amount == null) {
      return Text(
        '-',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        textAlign: TextAlign.right,
      );
    }

    final displayCurrency =
        currencyCode?.isNotEmpty == true ? currencyCode! : 'CNY';

    // Si l'API fournit amountCNY et devise != CNY, afficher les deux
    if (amountCNY != null &&
        amountCNY > 0 &&
        displayCurrency != 'CNY' &&
        displayCurrency.isNotEmpty) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${formatAmount(amount)} $displayCurrency',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: '(${formatAmount(amountCNY)} CNY)',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.right,
      );
    }

    // Sinon afficher uniquement montant + devise
    return Text(
      '${formatAmount(amount)} $displayCurrency',
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      textAlign: TextAlign.right,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Color(0xFF1A1E49),
        ),
      ),
    );
  }

  bool _allItemsSameClient() {
    final items = container.items;
    if (items != null && items.isNotEmpty) {
      final keys = <String>{};
      for (final i in items) {
        if (i.clientId != null) {
          keys.add('id_${i.clientId}');
        } else if (i.clientName != null && i.clientName!.trim().isNotEmpty) {
          keys.add('name_${i.clientName!.trim()}');
        }
      }
      if (keys.length >= 2) return false;
      return true;
    }
    if (container.packages == null || container.packages!.isEmpty) return true;
    final firstClientId = container.packages!.first.clientId;
    return container.packages!.every((p) => p.clientId == firstClientId);
  }

  String _formatItemAmount(double? amount) {
    if (amount == null) return '0,00';
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }

  Widget _buildModernItemCard(Items item) {
    final loc = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête (même design historique, sans icône delivery)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1E49).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: Color(0xFF1A1E49),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.description ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              children: [
                                TextSpan(
                                  text: '${loc.translate('invoice_number')}: ',
                                ),
                                TextSpan(
                                  text: item.invoiceNumber ?? 'N/A',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey[200], height: 1),
                const SizedBox(height: 12),
                // Carton, quantité/carton
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ItemDetailChip(
                      text: '${loc.translate('carton')}: ${item.carton ?? 0}',
                      icon: Icons.inventory,
                    ),
                    const SizedBox(width: 16),
                    ItemDetailChip(
                      text:
                          '${loc.translate('quantity_per_carton_2')}: ${item.quantityPerCarton ?? 0}',
                      icon: Icons.format_list_numbered,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quantité totale, prix unitaire (icône yen)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ItemDetailChip(
                      text:
                          '${loc.translate('total_quantity')}: ${item.quantity ?? 0}',
                      icon: Icons.numbers,
                    ),
                    const SizedBox(width: 8),
                    ItemDetailChip(
                      text: '${_formatItemAmount(item.unitPrice)} ¥',
                      icon: Icons.currency_yen,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Poids et CBN (0 si null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ItemDetailChip(
                      text: '${loc.translate('weight')}: ${item.weight ?? 0}',
                      icon: Icons.scale,
                    ),
                    const SizedBox(width: 16),
                    ItemDetailChip(
                      text: '${loc.translate('cbn')}: ${item.cbn ?? 0}',
                      icon: Icons.straighten,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Taux de vente et total (icône yen)
                Column(
                  children: [
                    ItemDetailChip(
                      text:
                          '${loc.translate('sales_rate')}: ${item.salesRate ?? 0}',
                      icon: Icons.trending_up,
                      fullWidth: true,
                    ),
                    const SizedBox(height: 8),
                    ItemDetailChip(
                      text:
                          '${loc.translate('total')}: ${_formatItemAmount((item.quantity ?? 0) * (item.unitPrice ?? 0))} ¥',
                      icon: Icons.currency_yen,
                      fullWidth: true,
                    ),
                  ],
                ),
                if (item.clientName != null &&
                        item.clientName!.trim().isNotEmpty ||
                    item.clientPhone != null &&
                        item.clientPhone!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.clientName != null &&
                            item.clientName!.trim().isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 16, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.clientName!.trim(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (item.clientPhone != null &&
                            item.clientPhone!.trim().isNotEmpty) ...[
                          if (item.clientName != null &&
                              item.clientName!.trim().isNotEmpty)
                            const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined,
                                  size: 16, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.clientPhone!.trim(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Items> get _filteredItems {
    final list = container.items ?? [];
    if (searchQuery.isEmpty) return list;
    final query = searchQuery.toLowerCase();
    return list.where((item) {
      return item.description?.toLowerCase().contains(query) == true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasContent =
        (container.items != null && container.items!.isNotEmpty) ||
            (container.packages != null && container.packages!.isNotEmpty);
    return Scaffold(
      appBar: AppBar(
          title: Text(
              AppLocalizations.of(context).translate('container_details'),
              style: TextStyle(
                  color: Color(0xFF1A1E49), fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1A1E49)),
          actions: [
            if (!_allItemsSameClient() && container.isTeam == false)
              isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Color(0xFF1A1E49),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () async {
                        try {
                          setState(() {
                            isLoading = true;
                          });
                          final user = await AuthService().getUserInfo();
                          if (user == null) {
                            showErrorTopSnackBar(
                                context, "Erreur: Utilisateur non connecté");
                            return;
                          }
                          final dto = Containers.fromJson(container.toJson());
                          dto.isTeam = true;
                          final result = await containerServices.update(
                              container.id!, user.id, dto);

                          if (result == "UPDATED") {
                            // Récupérer les nouvelles données
                            final updatedContainer = await containerServices
                                .getContainerDetails(container.id!);

                            // Mettre à jour l'état local
                            setState(() {
                              container = updatedContainer;
                            });

                            // Notifier le parent
                            if (widget.onContainerUpdated != null) {
                              widget.onContainerUpdated!(updatedContainer);
                            }

                            Navigator.of(context).pop(updatedContainer);

                            showSuccessTopSnackBar(
                                context, "Conteneur dégroupé avec succès");
                          }
                        } catch (e) {
                          print(e);
                          showErrorTopSnackBar(
                              context, "Erreur lors du dégroupage");
                        } finally {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      },
                      label: Text(AppLocalizations.of(context)
                          .translate('container_ungroup')),
                      icon: const Icon(Icons.person))
          ]),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
              MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bloc principal infos conteneur
              Container(
                padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width < 600 ? 16.0 : 18.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Utiliser un layout vertical sur mobile (largeur < 600px)
                        if (constraints.maxWidth < 600) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                container.reference ?? 'N/A',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(container.status)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      container.status == Status.RECEIVED ||
                                              container.status ==
                                                  Status.DELIVERED
                                          ? Icons.check_circle
                                          : container.status ==
                                                  Status.INPROGRESS
                                              ? Icons.local_shipping
                                              : Icons.hourglass_empty,
                                      size: 16,
                                      color: _getStatusColor(container.status),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getStatusText(container.status),
                                      style: TextStyle(
                                        color:
                                            _getStatusColor(container.status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Garder le layout horizontal pour les tablettes et plus
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                container.reference ?? 'N/A',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(container.status)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      container.status == Status.RECEIVED ||
                                              container.status ==
                                                  Status.DELIVERED
                                          ? Icons.check_circle
                                          : container.status ==
                                                  Status.INPROGRESS
                                              ? Icons.local_shipping
                                              : Icons.hourglass_empty,
                                      size: 16,
                                      color: _getStatusColor(container.status),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getStatusText(container.status),
                                      style: TextStyle(
                                        color:
                                            _getStatusColor(container.status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                        AppLocalizations.of(context)
                            .translate('container_form_size'),
                        "${container.size}",
                        icon: Icons.straighten),
                    _infoRow(
                        AppLocalizations.of(context)
                            .translate('container_form_availability'),
                        container.isAvailable == true
                            ? AppLocalizations.of(context)
                                .translate('container_available')
                            : AppLocalizations.of(context)
                                .translate('container_unavailable'),
                        icon: Icons.inventory_2),
                    if (container.departureHarborName != null ||
                        container.departureHarborId != null)
                      _infoRow(
                          AppLocalizations.of(context)
                              .translate('departure_port'),
                          container.departureHarborName,
                          icon: Icons.sailing),
                    if (container.arrivalHarborName != null ||
                        container.arrivalHarborId != null)
                      _infoRow(
                          AppLocalizations.of(context)
                              .translate('arrival_port'),
                          container.arrivalHarborName,
                          icon: Icons.pin_drop),
                    if (container.startDeliveryDate != null)
                      _infoRow(
                          AppLocalizations.of(context)
                              .translate('container_delivery_start_date'),
                          container.startDeliveryDate != null
                              ? DateFormat.yMMMMEEEEd()
                                  .format(container.startDeliveryDate!)
                              : '',
                          icon: Icons.calendar_today),
                    if (container.confirmDeliveryDate != null)
                      _infoRow(
                          AppLocalizations.of(context).translate(
                              'container_delivery_confirmation_date'),
                          container.confirmDeliveryDate != null
                              ? DateFormat.yMMMMEEEEd()
                                  .format(container.confirmDeliveryDate!)
                              : '',
                          icon: Icons.calendar_today),
                  ],
                ),
              ),
              // Bloc fournisseur
              if (container.supplier_id != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(AppLocalizations.of(context)
                        .translate('container_supplier')),
                    Container(
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width < 600
                              ? 12.0
                              : 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 600) {
                            // Layout vertical sur mobile
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.business,
                                        color: Color(0xFF1A1E49)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${container.supplierName ?? ""}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                if (container.supplierPhone != null &&
                                    container.supplierPhone!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone,
                                          color: Colors.green, size: 18),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(container.supplierPhone!,
                                            style:
                                                const TextStyle(fontSize: 16)),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            );
                          } else {
                            // Layout horizontal pour tablettes
                            return Row(
                              children: [
                                const Icon(Icons.business,
                                    color: Color(0xFF1A1E49)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${container.supplierName ?? ""}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ),
                                if (container.supplierPhone != null &&
                                    container.supplierPhone!.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.phone,
                                          color: Colors.green, size: 18),
                                      const SizedBox(width: 4),
                                      Text(container.supplierPhone!,
                                          style: const TextStyle(fontSize: 16)),
                                    ],
                                  ),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(AppLocalizations.of(context)
                        .translate('container_supplier')),
                    Container(
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width < 600
                              ? 12.0
                              : 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.business, color: Color(0xFF1A1E49)),
                          const SizedBox(width: 10),
                          Text(
                              AppLocalizations.of(context)
                                  .translate('container_bbd_limited'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17)),
                        ],
                      ),
                    ),
                  ],
                ),
              // Bloc frais
              _sectionTitle(AppLocalizations.of(context)
                  .translate('container_fees_charges')),
              Container(
                padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width < 600 ? 12.0 : 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _infoRowWithFormattedValue(
                        AppLocalizations.of(context)
                            .translate('container_form_location_fee'),
                        _formatFeeWidget(
                          amount: container.locationFee,
                          currencyCode: container.locationFeeCurrencyCode,
                          amountCNY: container.locationFeeCNY,
                        )),
                    _infoRowWithFormattedValue(
                        AppLocalizations.of(context)
                            .translate('container_form_loading_fee'),
                        _formatFeeWidget(
                          amount: container.loadingFee,
                          currencyCode: container.loadingFeeCurrencyCode,
                          amountCNY: container.loadingFeeCNY,
                        )),
                    _infoRowWithFormattedValue(
                        AppLocalizations.of(context)
                            .translate('container_form_local_charge'),
                        _formatFeeWidget(
                          amount: container.localCharge,
                          currencyCode: container.localChargeCurrencyCode,
                          amountCNY: container.localChargeCNY,
                        )),
                    _infoRowWithFormattedValue(
                        AppLocalizations.of(context)
                            .translate('container_form_overweight_fee'),
                        _formatFeeWidget(
                          amount: container.overweightFee,
                          currencyCode: container.overweightFeeCurrencyCode,
                          amountCNY: container.overweightFeeCNY,
                        )),
                    _infoRowWithFormattedValue(
                        AppLocalizations.of(context)
                            .translate('container_form_checking_fee'),
                        _formatFeeWidget(
                          amount: container.checkingFee,
                          currencyCode: container.checkingFeeCurrencyCode,
                          amountCNY: container.checkingFeeCNY,
                        )),
                    _infoRowWithFormattedValue(
                        AppLocalizations.of(context)
                            .translate('container_form_telx_fee'),
                        _formatFeeWidget(
                          amount: container.telxFee,
                          currencyCode: container.telxFeeCurrencyCode,
                          amountCNY: container.telxFeeCNY,
                        )),
                    _infoRowWithFormattedValue(
                        AppLocalizations.of(context)
                            .translate('container_form_other_fees'),
                        _formatFeeWidget(
                          amount: container.otherFees,
                          currencyCode: container.otherFeesCurrencyCode,
                          amountCNY: container.otherFeesCNY,
                        )),
                    _infoRowWithFormattedValue(
                        AppLocalizations.of(context)
                            .translate('container_form_margin'),
                        _formatFeeWidget(
                          amount: container.margin,
                          currencyCode: container.marginCurrencyCode,
                          amountCNY: container.marginCNY,
                        )),
                    const Divider(),
                    _infoRow(
                        AppLocalizations.of(context)
                            .translate('container_total_fees'),
                        '${formatAmount(_totalFeesCNY(container))} CNY',
                        icon: Icons.attach_money),
                  ],
                ),
              ),
              // Liste des items dans le conteneur (Embarquer des items)
              _sectionTitle(
                  AppLocalizations.of(context).translate('container_items')),
              const SizedBox(height: 16),
              if (container.items != null && container.items!.isNotEmpty) ...[
                Row(
                  children: [
                    if (container.status == Status.PENDING) ...[
                      Expanded(
                        child: buildTextField(
                          controller: searchController,
                          label: AppLocalizations.of(context)
                              .translate('container_search_items'),
                          icon: Icons.search,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1E49),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () async {
                            final embarked = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute<bool>(
                                builder: (context) => EmbarkItemsPage(
                                  containerId: container.id!,
                                ),
                              ),
                            );
                            if (embarked == true && mounted) {
                              final updatedContainer = await containerServices
                                  .getContainerDetails(container.id!);
                              setState(() {
                                container = updatedContainer;
                              });
                            }
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          tooltip: AppLocalizations.of(context)
                              .translate('container_add_items'),
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width < 600 ? 6.0 : 8.0),
                margin: const EdgeInsets.only(top: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.width < 600
                      ? MediaQuery.of(context).size.height * 0.4
                      : MediaQuery.of(context).size.height * 0.5,
                  child: (container.items == null || container.items!.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(AppLocalizations.of(context)
                                  .translate('container_no_items')),
                              if (container.status == Status.PENDING) ...[
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: () async {
                                    final embarked = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute<bool>(
                                        builder: (context) => EmbarkItemsPage(
                                          containerId: container.id!,
                                        ),
                                      ),
                                    );
                                    if (embarked == true && mounted) {
                                      final updatedContainer =
                                          await containerServices
                                              .getContainerDetails(
                                                  container.id!);
                                      setState(() {
                                        container = updatedContainer;
                                      });
                                    }
                                  },
                                  label: Text(AppLocalizations.of(context)
                                      .translate('container_add_items')),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            final updatedContainer = await containerServices
                                .getContainerDetails(container.id!);
                            setState(() {
                              container = updatedContainer;
                            });
                          },
                          displacement: 40,
                          color: Theme.of(context).primaryColor,
                          backgroundColor: Colors.white,
                          child: _filteredItems.isEmpty
                              ? Center(
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .translate('container_no_items_search'),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: _filteredItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _filteredItems[index];
                                    return Dismissible(
                                      key: Key('item_${item.id}'),
                                      direction:
                                          container.status != Status.INPROGRESS
                                              ? DismissDirection.endToStart
                                              : DismissDirection.none,
                                      background: Container(
                                        padding:
                                            const EdgeInsets.only(right: 16),
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        child: const Icon(Icons.delete,
                                            color: Colors.white, size: 30),
                                      ),
                                      confirmDismiss: container.status !=
                                              Status.INPROGRESS
                                          ? (direction) async {
                                              final bool confirm =
                                                  await showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    backgroundColor:
                                                        Colors.white,
                                                    title: Text(AppLocalizations
                                                            .of(context)
                                                        .translate(
                                                            'confirmation')),
                                                    content: Text(AppLocalizations
                                                            .of(context)
                                                        .translate(
                                                            'container_remove_item_confirm')),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false),
                                                        child: Text(
                                                            AppLocalizations.of(
                                                                    context)
                                                                .translate(
                                                                    'cancel')),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                        child: Text(
                                                            isLoading
                                                                ? AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'container_removing')
                                                                : AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'confirm'),
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .red)),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                              if (confirm != true) return false;
                                              try {
                                                final user = await authService
                                                    .getUserInfo();
                                                setState(() {
                                                  isLoading = true;
                                                });
                                                final result = await itemServices
                                                    .removeItemFromContainer(
                                                  itemId: item.id!,
                                                  containerId: container.id!,
                                                  userId: user?.id.toInt(),
                                                );
                                                if (result == "REMOVED") {
                                                  setState(() {
                                                    container.items!
                                                        .removeWhere((i) =>
                                                            i.id == item.id);
                                                  });
                                                  showSuccessTopSnackBar(
                                                      context,
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'container_item_removed'));
                                                  return true;
                                                } else if (result ==
                                                    "ITEM_NOT_IN_CONTAINER") {
                                                  showErrorTopSnackBar(
                                                      context,
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'container_item_not_in_container'));
                                                } else if (result ==
                                                    "CONTAINER_INPROGRESS") {
                                                  showErrorTopSnackBar(
                                                      context,
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'container_in_progress_remove_error'));
                                                }
                                              } catch (e) {
                                                showErrorTopSnackBar(
                                                    context,
                                                    AppLocalizations.of(context)
                                                        .translate(
                                                            'container_remove_error'));
                                              } finally {
                                                setState(() {
                                                  isLoading = false;
                                                });
                                              }
                                              return false;
                                            }
                                          : null,
                                      child: _buildModernItemCard(item),
                                    );
                                  },
                                ),
                        ),
                ),
              ),
              // Actions principales (démarrer livraison si conteneur a des items ou des colis)
              if (hasContent && container.status == Status.PENDING)
                Padding(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.width < 600
                          ? 16.0
                          : 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: Text(
                          isLoading
                              ? AppLocalizations.of(context)
                                  .translate('container_starting')
                              : AppLocalizations.of(context)
                                  .translate('container_start_delivery'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        DateTime? tempSelectedDate = selectedDeliveryDate;
                        final bool confirm = await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, setStateDialog) {
                                return AlertDialog(
                                  title: Text(AppLocalizations.of(context)
                                      .translate('container_confirm_start')),
                                  backgroundColor: Colors.white,
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(AppLocalizations.of(context).translate(
                                          'container_confirm_start_message')),
                                      const SizedBox(height: 16),
                                      TextButton.icon(
                                        icon: const Icon(Icons.date_range),
                                        label: Text(
                                          tempSelectedDate != null
                                              ? '${AppLocalizations.of(context).translate('container_delivery_date')} : '
                                                  '${DateFormat('dd/MM/yyyy').format(tempSelectedDate!)}'
                                              : AppLocalizations.of(context)
                                                  .translate(
                                                      'container_choose_delivery_date'),
                                        ),
                                        onPressed: () async {
                                          final now = DateTime.now();
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                tempSelectedDate ?? now,
                                            firstDate: DateTime(now.year - 1),
                                            lastDate: DateTime(now.year + 2),
                                          );
                                          if (picked != null) {
                                            setStateDialog(() {
                                              tempSelectedDate = picked;
                                            });
                                          }
                                        },
                                      ),
                                      if (tempSelectedDate != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            '${AppLocalizations.of(context).translate('container_selected_date')} : '
                                            '${DateFormat('dd/MM/yyyy').format(tempSelectedDate!)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      if (tempSelectedDate == null)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            'Si aucune date n\'est choisie, la date du jour sera utilisée.',
                                            style: TextStyle(
                                                fontSize: 17,
                                                color: Colors.grey),
                                          ),
                                        ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text("Annuler"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text(
                                          isLoading
                                              ? AppLocalizations.of(context)
                                                  .translate(
                                                      'container_starting')
                                              : AppLocalizations.of(context)
                                                  .translate('confirm'),
                                          style: const TextStyle(
                                              color: Colors.green)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                        if (confirm != true) return;
                        setState(() {
                          isLoading = true;
                          selectedDeliveryDate = tempSelectedDate;
                        });
                        final user = await authService.getUserInfo();
                        if (user == null) {
                          showErrorTopSnackBar(
                              context, "Erreur: Utilisateur non connecté");
                          setState(() => isLoading = false);
                          return;
                        }
                        try {
                          // On passe la date sélectionnée ou la date du jour
                          final deliveryDate =
                              selectedDeliveryDate ?? DateTime.now();
                          final result = await containerServices.startDelivery(
                              container.id!, user.id.toInt(), deliveryDate);
                          if (result == "SUCCESS") {
                            final updatedContainer = await containerServices
                                .getContainerDetails(container.id!);
                            Navigator.of(context).pop(updatedContainer);
                            if (widget.onContainerUpdated != null) {
                              widget.onContainerUpdated!(updatedContainer);
                            }
                            showSuccessTopSnackBar(
                                context,
                                AppLocalizations.of(context)
                                    .translate('container_delivery_started'));
                          } else if (result == "NO_PACKAGE_FOR_DELIVERY") {
                            showErrorTopSnackBar(
                                context,
                                AppLocalizations.of(context).translate(
                                    'container_no_packages_for_delivery'));
                          }
                        } catch (e) {
                          print(e);
                          showErrorTopSnackBar(
                              context,
                              AppLocalizations.of(context)
                                  .translate('container_delivery_start_error'));
                        } finally {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      },
                    ),
                  ),
                )
              else if (container.status == Status.INPROGRESS)
                Padding(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.width < 600
                          ? 16.0
                          : 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.flag, color: Colors.white),
                      label: Text(
                          isLoading
                              ? AppLocalizations.of(context)
                                  .translate('container_changing_status')
                              : AppLocalizations.of(context)
                                  .translate('container_arrived_destination'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        DateTime? tempSelectedConfirmDate;
                        final bool confirm = await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, setStateDialog) {
                                return AlertDialog(
                                  title: Text(AppLocalizations.of(context)
                                      .translate('container_confirm_arrival')),
                                  backgroundColor: Colors.white,
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(AppLocalizations.of(context).translate(
                                          'container_confirm_arrival_message')),
                                      const SizedBox(height: 16),
                                      TextButton.icon(
                                        icon: const Icon(Icons.date_range),
                                        label: Text(
                                          tempSelectedConfirmDate != null
                                              ? '${AppLocalizations.of(context).translate('container_confirmation_date')} : '
                                                  '${DateFormat('dd/MM/yyyy').format(tempSelectedConfirmDate!)}'
                                              : AppLocalizations.of(context)
                                                  .translate(
                                                      'container_choose_confirmation_date'),
                                        ),
                                        onPressed: () async {
                                          final now = DateTime.now();
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                tempSelectedConfirmDate ?? now,
                                            firstDate: DateTime(now.year - 1),
                                            lastDate: DateTime(now.year + 2),
                                          );
                                          if (picked != null) {
                                            setStateDialog(() {
                                              tempSelectedConfirmDate = picked;
                                            });
                                          }
                                        },
                                      ),
                                      if (tempSelectedConfirmDate != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            'Date sélectionnée : '
                                            '${DateFormat('dd/MM/yyyy').format(tempSelectedConfirmDate!)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      if (tempSelectedConfirmDate == null)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            'Si aucune date n\'est choisie, la date du jour sera utilisée.',
                                            style: TextStyle(
                                                fontSize: 17,
                                                color: Colors.grey),
                                          ),
                                        ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text("Annuler"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text(
                                          isLoading
                                              ? "Changement de statut..."
                                              : "Confirmer",
                                          style: const TextStyle(
                                              color: Colors.green)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                        if (confirm != true) return;
                        setState(() {
                          isLoading = true;
                        });
                        final user = await authService.getUserInfo();
                        if (user == null) {
                          showErrorTopSnackBar(
                              context, "Erreur: Utilisateur non connecté");
                          setState(() => isLoading = false);
                          return;
                        }
                        try {
                          final confirmDate =
                              tempSelectedConfirmDate ?? DateTime.now();
                          final result =
                              await containerServices.confirmReceiving(
                                  container.id!, user.id.toInt(), confirmDate);
                          if (result == "SUCCESS") {
                            final updatedContainer = await containerServices
                                .getContainerDetails(container.id!);
                            Navigator.of(context).pop(updatedContainer);
                            if (widget.onContainerUpdated != null) {
                              widget.onContainerUpdated!(updatedContainer);
                            }
                            showSuccessTopSnackBar(
                                context,
                                AppLocalizations.of(context)
                                    .translate('container_arrival_confirmed'));
                          } else if (result == "NO_PACKAGE_FOR_DELIVERY") {
                            showErrorTopSnackBar(
                                context,
                                AppLocalizations.of(context).translate(
                                    'container_no_packages_for_reception'));
                          } else if (result == "CONTAINER_NOT_IN_PROGRESS") {
                            showErrorTopSnackBar(
                                context,
                                AppLocalizations.of(context)
                                    .translate('container_not_in_progress'));
                          }
                        } catch (e) {
                          showErrorTopSnackBar(
                              context,
                              AppLocalizations.of(context)
                                  .translate('container_reception_error'));
                        } finally {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
