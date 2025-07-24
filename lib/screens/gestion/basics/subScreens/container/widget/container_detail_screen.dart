import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/add_package_to_container_modal.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    container = widget.container;
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
        return 'En attente';
      case Status.INPROGRESS:
        return 'En livraison';
      case Status.RECEIVED:
        return 'Arrivé à destination';
      case Status.DELIVERED:
        return 'Livré';
      default:
        return 'Inconnu';
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
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
          fontSize: 18,
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
          title: const Text('Détails du conteneur',
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
                      label: const Text("Degrouper"),
                      icon: const Icon(Icons.person))
          ]),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bloc principal infos conteneur
              Container(
                padding: const EdgeInsets.all(18),
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
                    Row(
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
                                        container.status == Status.DELIVERED
                                    ? Icons.check_circle
                                    : container.status == Status.INPROGRESS
                                        ? Icons.local_shipping
                                        : Icons.hourglass_empty,
                                size: 16,
                                color: _getStatusColor(container.status),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getStatusText(container.status),
                                style: TextStyle(
                                  color: _getStatusColor(container.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _infoRow('Taille', "${container.size} pieds",
                        icon: Icons.straighten),
                    _infoRow(
                        'Disponibilité',
                        container.isAvailable == true
                            ? 'Disponible'
                            : 'Indisponible',
                        icon: Icons.inventory_2),
                    if (container.startDeliveryDate != null)
                      _infoRow(
                          'Date de debut de livraison',
                          container.startDeliveryDate != null
                              ? DateFormat.yMMMMEEEEd()
                                  .format(container.startDeliveryDate!)
                              : '',
                          icon: Icons.calendar_today),
                    if (container.confirmDeliveryDate != null)
                      _infoRow(
                          'Date de confirmation de livraison',
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
                    _sectionTitle('Fournisseur'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.business, color: Color(0xFF1A1E49)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${container.supplierName ?? ""}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
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
                                    style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Fournisseur'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.business, color: Color(0xFF1A1E49)),
                          SizedBox(width: 10),
                          Text('BBD Limited',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                ),
              // Bloc frais
              _sectionTitle('Frais & Charges'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _infoRow(
                        'Frais de location',
                        container.locationFee != null
                            ? '${container.locationFee} CNY'
                            : '0.0'),
                    _infoRow(
                        'Frais de chargement',
                        container.loadingFee != null
                            ? '${container.loadingFee} CNY'
                            : '0.0'),
                    _infoRow(
                        'Charge local',
                        container.localCharge != null
                            ? '${container.localCharge} CNY'
                            : '0.0'),
                    _infoRow(
                        'Frais de surpoids',
                        container.overweightFee != null
                            ? '${container.overweightFee} CNY'
                            : '0.0'),
                    _infoRow(
                        'Frais de checking',
                        container.checkingFee != null
                            ? '${container.checkingFee} CNY'
                            : '0.0'),
                    _infoRow(
                        'Frais de TELX',
                        container.telxFee != null
                            ? '${container.telxFee} CNY'
                            : '0.0'),
                    _infoRow(
                        'Autres charges',
                        container.otherFees != null
                            ? '${container.otherFees} CNY'
                            : '0.0'),
                    _infoRow(
                        'Marge ajoutée',
                        container.margin != null
                            ? '${container.margin} CNY'
                            : '0.0'),
                    const Divider(),
                    _infoRow(
                        'Total des frais',
                        container.amount != null
                            ? '${container.amount} CNY'
                            : '0.0',
                        icon: Icons.attach_money),
                  ],
                ),
              ),
              // Liste des colis
              _sectionTitle('Colis dans le conteneur'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'La liste des colis',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
                          final updatedContainer = await containerServices
                              .getContainerDetails(container.id!);
                          setState(() {
                            container = updatedContainer;
                          });
                        }
                      },
                      label: const Text("Ajouter des colis"),
                      icon: const Icon(Icons.add),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher un colis...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    fillColor: Colors.white,
                    filled: true,
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: container.packages == null ||
                          container.packages!.isEmpty
                      ? const Center(
                          child: Text("Pas de colis pour ce conteneur."),
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
                                        color:
                                            container.status != Status.RECEIVED
                                                ? Colors.red
                                                : Colors.grey,
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
                                                    title: const Text(
                                                        "Confirmation"),
                                                    content: const Text(
                                                        "Voulez-vous vraiment retirer ce colis du conteneur ?"),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false),
                                                        child: const Text(
                                                            "Annuler"),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                        child: Text(
                                                            isLoading
                                                                ? "Suppression..."
                                                                : "Confirmer",
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
                                                      "Colis retiré du conteneur");
                                                  return true;
                                                } else if (result ==
                                                    "PACKAGE_NOT_IN_CONTAINER") {
                                                  showErrorTopSnackBar(context,
                                                      "Le colis n'appartient pas à ce conteneur");
                                                } else if (result ==
                                                    "CONTAINER_INPROGRESS") {
                                                  showErrorTopSnackBar(context,
                                                      "Impossible de retirer un colis d'un conteneur en cours de livraison");
                                                }
                                              } catch (e) {
                                                showErrorTopSnackBar(context,
                                                    "Erreur lors de la suppression");
                                              } finally {
                                                setState(() {
                                                  isLoading = false;
                                                });
                                              }
                                              return false;
                                            }
                                          : null,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 5, horizontal: 2),
                                        padding: const EdgeInsets.all(12),
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
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(pkg.ref ?? '',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15)),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                      pkg.expeditionType ?? '',
                                                      style: const TextStyle(
                                                          color: Colors.blue,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.person,
                                                    size: 14,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                    child: Text(
                                                        '${pkg.clientName ?? ''} ${pkg.clientPhone != null ? '| ${pkg.clientPhone}' : ''}',
                                                        style: const TextStyle(
                                                            fontSize: 13))),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.inventory_2,
                                                    size: 14,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(
                                                    'Cartons: ${pkg.itemQuantity ?? 0}',
                                                    style: const TextStyle(
                                                        fontSize: 13)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on,
                                                    size: 14,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(
                                                    'Départ: ${pkg.startCountry ?? 'N/A'}',
                                                    style: const TextStyle(
                                                        fontSize: 13)),
                                                const SizedBox(width: 10),
                                                Text(
                                                    'Arrivée: ${pkg.destinationCountry ?? 'N/A'}',
                                                    style: const TextStyle(
                                                        fontSize: 13)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today,
                                                    size: 14,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(
                                                    'Départ: ${pkg.startDate != null ? DateFormat('dd/MM/yyyy').format(pkg.startDate!) : ''}',
                                                    style: const TextStyle(
                                                        fontSize: 13)),
                                                const SizedBox(width: 10),
                                                Text(
                                                    'Arrivée: ${pkg.arrivalDate != null ? DateFormat('dd/MM/yyyy').format(pkg.arrivalDate!) : ''}',
                                                    style: const TextStyle(
                                                        fontSize: 13)),
                                              ],
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
                  padding: const EdgeInsets.only(top: 24.0),
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
                          isLoading ? 'Démarrage...' : 'Démarrer la livraison',
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
                                  title: const Text("Confirmer le démarrage"),
                                  backgroundColor: Colors.white,
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                          "Voulez-vous vraiment démarrer la livraison de ce conteneur ?"),
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
                                            'Date sélectionnée : '
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
                                                fontSize: 12,
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
                                              ? "Démarrage..."
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
                                context, "Livraison démarrée avec succès !");
                          } else if (result == "NO_PACKAGE_FOR_DELIVERY") {
                            showErrorTopSnackBar(context,
                                "Impossible de démarrer la livraison, pas de colis dans le conteneur.");
                          }
                        } catch (e) {
                          print(e);
                          showErrorTopSnackBar(context,
                              "Erreur lors du démarrage de la livraison");
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
                  padding: const EdgeInsets.only(top: 24.0),
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
                              ? 'Changement de statut...'
                              : 'Arrivé à destination',
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
                                  title: const Text(
                                      "Confirmer l'arrivée du conteneur"),
                                  backgroundColor: Colors.white,
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                          "Voulez-vous vraiment confirmer que le conteneur est arrivé à destination ?"),
                                      const SizedBox(height: 16),
                                      TextButton.icon(
                                        icon: const Icon(Icons.date_range),
                                        label: Text(
                                          tempSelectedConfirmDate != null
                                              ? 'Date de confirmation : '
                                                  '${DateFormat('dd/MM/yyyy').format(tempSelectedConfirmDate!)}'
                                              : 'Choisir la date de confirmation (optionnel)',
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
                                                fontSize: 12,
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
                                context, "Conteneur confirmé à destination !");
                          } else if (result == "NO_PACKAGE_FOR_DELIVERY") {
                            showErrorTopSnackBar(context,
                                "Impossible de confirmer la réception, pas de colis dans le conteneur.");
                          } else if (result == "CONTAINER_NOT_IN_PROGRESS") {
                            showErrorTopSnackBar(context,
                                "Le conteneur n'est pas en status INPROGRESS.");
                          }
                        } catch (e) {
                          showErrorTopSnackBar(context,
                              "Erreur lors de la reception du conteneur");
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
