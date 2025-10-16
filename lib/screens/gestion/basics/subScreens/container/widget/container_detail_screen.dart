import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/add_package_to_container_modal.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

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

  // Fonction helper pour créer du texte avec valeurs en gras
  Widget _buildInfoText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
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
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
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

// Vérifie si tous les colis sont pour le même client
  bool _allPackagesSameClient() {
    if (container.packages == null || container.packages!.isEmpty) return true;
    final firstClientId = container.packages!.first.clientId;
    return container.packages!.every((p) => p.clientId == firstClientId);
  }

  @override
  Widget build(BuildContext context) {
    final filteredPackages = container.packages?.where((pkg) {
      if (searchQuery.isEmpty) return true;
      final query = searchQuery.toLowerCase();
      return pkg.ref?.toLowerCase().contains(query) == true ||
          pkg.clientName?.toLowerCase().contains(query) == true ||
          pkg.clientPhone?.toLowerCase().contains(query) == true;
    }).toList();

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
            if (!_allPackagesSameClient() && container.isTeam == false)
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
                                  fontWeight: FontWeight.bold, fontSize: 16)),
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
                    _infoRow(
                        AppLocalizations.of(context)
                            .translate('container_form_location_fee'),
                        container.locationFee != null
                            ? '${container.locationFee} CNY'
                            : '0.0'),
                    _infoRow(
                        AppLocalizations.of(context)
                            .translate('container_form_loading_fee'),
                        container.loadingFee != null
                            ? '${container.loadingFee} CNY'
                            : '0.0'),
                    _infoRow(
                        AppLocalizations.of(context)
                            .translate('container_form_local_charge'),
                        container.localCharge != null
                            ? '${container.localCharge} CNY'
                            : '0.0'),
                    _infoRow(
                        AppLocalizations.of(context)
                            .translate('container_form_overweight_fee'),
                        container.overweightFee != null
                            ? '${container.overweightFee} CNY'
                            : '0.0'),
                    _infoRow(
                        AppLocalizations.of(context)
                            .translate('container_form_checking_fee'),
                        container.checkingFee != null
                            ? '${container.checkingFee} CNY'
                            : '0.0'),
                    _infoRow(
                        AppLocalizations.of(context)
                            .translate('container_form_telx_fee'),
                        container.telxFee != null
                            ? '${container.telxFee} CNY'
                            : '0.0'),
                    _infoRow(
                        AppLocalizations.of(context)
                            .translate('container_form_other_fees'),
                        container.otherFees != null
                            ? '${container.otherFees} CNY'
                            : '0.0'),
                    _infoRow(
                        AppLocalizations.of(context)
                            .translate('container_form_margin'),
                        container.margin != null
                            ? '${container.margin} CNY'
                            : '0.0'),
                    const Divider(),
                    _infoRow(
                        AppLocalizations.of(context)
                            .translate('container_total_fees'),
                        container.amount != null
                            ? '${container.amount} CNY'
                            : '0.0',
                        icon: Icons.attach_money),
                  ],
                ),
              ),
              // Liste des colis
              if (container.packages != null &&
                  container.packages!.isNotEmpty) ...[
                _sectionTitle(AppLocalizations.of(context)
                    .translate('container_packages')),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      // Layout vertical sur mobile
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate('container_packages_list'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                          if (container.status == Status.PENDING) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: () async {
                                  final selectedPackages =
                                      await showAddPackagesToContainerDialog(
                                    context,
                                    container.id!,
                                    packageServices,
                                  );
                                  if (selectedPackages != null &&
                                      selectedPackages.isNotEmpty) {
                                    final updatedContainer =
                                        await containerServices
                                            .getContainerDetails(container.id!);
                                    setState(() {
                                      container = updatedContainer;
                                    });
                                  }
                                },
                                label: Text(AppLocalizations.of(context)
                                    .translate('container_add_packages')),
                                icon: const Icon(Icons.add),
                              ),
                            ),
                          ],
                        ],
                      );
                    } else {
                      // Layout horizontal pour tablettes
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate('container_packages_list'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                          if (container.status == Status.PENDING)
                            TextButton.icon(
                              onPressed: () async {
                                final selectedPackages =
                                    await showAddPackagesToContainerDialog(
                                  context,
                                  container.id!,
                                  packageServices,
                                );
                                if (selectedPackages != null &&
                                    selectedPackages.isNotEmpty) {
                                  final updatedContainer =
                                      await containerServices
                                          .getContainerDetails(container.id!);
                                  setState(() {
                                    container = updatedContainer;
                                  });
                                }
                              },
                              label: Text(AppLocalizations.of(context)
                                  .translate('container_add_packages')),
                              icon: const Icon(Icons.add),
                            ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                buildTextField(
                  controller: searchController,
                  label: AppLocalizations.of(context)
                      .translate('container_search_packages'),
                  icon: Icons.search,
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
                  child: container.packages == null ||
                          container.packages!.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(AppLocalizations.of(context)
                                  .translate('container_no_packages')),
                              if (container.status == Status.PENDING) ...[
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: () async {
                                    final selectedPackages =
                                        await showAddPackagesToContainerDialog(
                                      context,
                                      container.id!,
                                      packageServices,
                                    );
                                    if (selectedPackages != null &&
                                        selectedPackages.isNotEmpty) {
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
                                      .translate('container_add_packages')),
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
                          child: filteredPackages?.isEmpty == true
                              ? const Center(
                                  child: Text(
                                    "Aucun colis ne correspond à votre recherche",
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: filteredPackages?.length ?? 0,
                                  itemBuilder: (context, index) {
                                    final pkg = filteredPackages![index];
                                    return Dismissible(
                                      key: Key('${pkg.id}'),
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
                                                            'container_remove_package_confirm')),
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
                                                final result = await packageServices
                                                    .removePackageFromContainer(
                                                  packageId: pkg.id!,
                                                  containerId: container.id!,
                                                  userId: user!.id.toInt(),
                                                );
                                                if (result == "REMOVED") {
                                                  setState(() {
                                                    container.packages!
                                                        .removeWhere((p) =>
                                                            p.id == pkg.id);
                                                  });
                                                  showSuccessTopSnackBar(
                                                      context,
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'container_package_removed'));
                                                  return true;
                                                } else if (result ==
                                                    "PACKAGE_NOT_IN_CONTAINER") {
                                                  showErrorTopSnackBar(
                                                      context,
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'container_package_not_in_container'));
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
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                            vertical: 5,
                                            horizontal: MediaQuery.of(context)
                                                        .size
                                                        .width <
                                                    600
                                                ? 1
                                                : 2),
                                        padding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width <
                                                    600
                                                ? 10.0
                                                : 12.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.04),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            LayoutBuilder(
                                              builder: (context, constraints) {
                                                if (constraints.maxWidth <
                                                    600) {
                                                  // Layout vertical sur mobile
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(pkg.ref ?? '',
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      15)),
                                                      const SizedBox(height: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.blue[50],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                            pkg.expeditionType ??
                                                                '',
                                                            style: const TextStyle(
                                                                color:
                                                                    Colors.blue,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16)),
                                                      ),
                                                    ],
                                                  );
                                                } else {
                                                  // Layout horizontal pour tablettes
                                                  return Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(pkg.ref ?? '',
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      15)),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.blue[50],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                            pkg.expeditionType ??
                                                                '',
                                                            style: const TextStyle(
                                                                color:
                                                                    Colors.blue,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16)),
                                                      ),
                                                    ],
                                                  );
                                                }
                                              },
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.person,
                                                    size: 14,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                    child: RichText(
                                                  text: TextSpan(
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.black87),
                                                    children: [
                                                      TextSpan(
                                                          text:
                                                              '${pkg.clientName ?? ''}'),
                                                      if (pkg.clientPhone !=
                                                              null &&
                                                          pkg.clientPhone!
                                                              .isNotEmpty) ...[
                                                        TextSpan(text: ' | '),
                                                        TextSpan(
                                                          text:
                                                              pkg.clientPhone!,
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                )),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.inventory_2,
                                                    size: 14,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: _buildInfoText(
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'container_cartons'),
                                                      '${pkg.itemQuantity ?? 0}'),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            LayoutBuilder(
                                              builder: (context, constraints) {
                                                if (constraints.maxWidth <
                                                    600) {
                                                  // Layout vertical sur mobile
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                              Icons.location_on,
                                                              size: 14,
                                                              color:
                                                                  Colors.grey),
                                                          const SizedBox(
                                                              width: 4),
                                                          Expanded(
                                                            child: _buildInfoText(
                                                                AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'container_departure'),
                                                                '${pkg.startCountry ?? 'N/A'}'),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                              Icons.location_on,
                                                              size: 14,
                                                              color:
                                                                  Colors.grey),
                                                          const SizedBox(
                                                              width: 4),
                                                          Expanded(
                                                            child: _buildInfoText(
                                                                AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'container_arrival'),
                                                                '${pkg.destinationCountry ?? 'N/A'}'),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  );
                                                } else {
                                                  // Layout horizontal pour tablettes
                                                  return Row(
                                                    children: [
                                                      const Icon(
                                                          Icons.location_on,
                                                          size: 14,
                                                          color: Colors.grey),
                                                      const SizedBox(width: 4),
                                                      _buildInfoText(
                                                          AppLocalizations.of(
                                                                  context)
                                                              .translate(
                                                                  'container_departure'),
                                                          '${pkg.startCountry ?? 'N/A'}'),
                                                      const SizedBox(width: 10),
                                                      _buildInfoText(
                                                          AppLocalizations.of(
                                                                  context)
                                                              .translate(
                                                                  'container_arrival'),
                                                          '${pkg.destinationCountry ?? 'N/A'}'),
                                                    ],
                                                  );
                                                }
                                              },
                                            ),
                                            const SizedBox(height: 4),
                                            LayoutBuilder(
                                              builder: (context, constraints) {
                                                if (constraints.maxWidth <
                                                    600) {
                                                  // Layout vertical sur mobile
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .calendar_today,
                                                              size: 14,
                                                              color:
                                                                  Colors.grey),
                                                          const SizedBox(
                                                              width: 4),
                                                          Expanded(
                                                            child: _buildInfoText(
                                                                AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'container_departure'),
                                                                pkg.startDate !=
                                                                        null
                                                                    ? DateFormat(
                                                                            'dd/MM/yyyy')
                                                                        .format(
                                                                            pkg.startDate!)
                                                                    : ''),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .calendar_today,
                                                              size: 14,
                                                              color:
                                                                  Colors.grey),
                                                          const SizedBox(
                                                              width: 4),
                                                          Expanded(
                                                            child: _buildInfoText(
                                                                AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'container_arrival'),
                                                                pkg.arrivalDate !=
                                                                        null
                                                                    ? DateFormat(
                                                                            'dd/MM/yyyy')
                                                                        .format(
                                                                            pkg.arrivalDate!)
                                                                    : ''),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  );
                                                } else {
                                                  // Layout horizontal pour tablettes
                                                  return Row(
                                                    children: [
                                                      const Icon(
                                                          Icons.calendar_today,
                                                          size: 14,
                                                          color: Colors.grey),
                                                      const SizedBox(width: 4),
                                                      _buildInfoText(
                                                          AppLocalizations.of(
                                                                  context)
                                                              .translate(
                                                                  'container_departure'),
                                                          pkg.startDate != null
                                                              ? DateFormat(
                                                                      'dd/MM/yyyy')
                                                                  .format(pkg
                                                                      .startDate!)
                                                              : ''),
                                                      const SizedBox(width: 10),
                                                      _buildInfoText(
                                                          AppLocalizations.of(
                                                                  context)
                                                              .translate(
                                                                  'container_arrival'),
                                                          pkg.arrivalDate !=
                                                                  null
                                                              ? DateFormat(
                                                                      'dd/MM/yyyy')
                                                                  .format(pkg
                                                                      .arrivalDate!)
                                                              : ''),
                                                    ],
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ),
              // Actions principales
              if (container.packages != null &&
                  container.packages!.isNotEmpty &&
                  container.status == Status.PENDING)
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
                                                fontSize: 16,
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
                                                fontSize: 16,
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
