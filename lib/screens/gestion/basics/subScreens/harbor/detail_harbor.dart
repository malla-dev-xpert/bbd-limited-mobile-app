import 'dart:developer';

import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/harbor_services.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/harbor.dart';
import 'package:bbd_limited/models/package.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/harbor/widgets/add_container_to_harbor.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/carbon.dart';

class HarborDetailPage extends StatefulWidget {
  final Harbor harbor;

  const HarborDetailPage({required this.harbor, Key? key}) : super(key: key);

  @override
  State<HarborDetailPage> createState() => _HarborDetailPageState();
}

class _HarborDetailPageState extends State<HarborDetailPage> {
  final AuthService _authService = AuthService();
  final HarborServices _harborServices = HarborServices();
  final ContainerServices _containerServices = ContainerServices();
  bool _isLoading = false;

  Future<void> _handleAddContainers() async {
    if (_isLoading || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final selectedContainers = await showAddContainerToHarborDialog(
        context,
        widget.harbor.id,
        _containerServices,
      );

      if (selectedContainers != null &&
          selectedContainers.isNotEmpty &&
          mounted) {
        final updatedHarbor = await _harborServices.getHarborDetails(
          widget.harbor.id,
        );
        setState(() => widget.harbor.containers = updatedHarbor.containers);
        showSuccessTopSnackBar(context, "Conteneurs ajoutés avec succès");
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          "Erreur lors de la mise à jour: ${e.toString()}",
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _handleContainerDismiss(Containers container) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          backgroundColor: Colors.white,
          content: Text(
            "Êtes-vous sûr de vouloir retirer le conteneur ${container.reference ?? 'sans référence'} du port ?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                "Annuler",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                "Confirmer",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return false;

    try {
      final user = await _authService.getUserInfo();
      if (user == null) {
        if (mounted)
          showErrorTopSnackBar(context, "Erreur: Utilisateur non connecté");
        return false;
      }

      if (container.id == null) {
        showErrorTopSnackBar(context, "Erreur: Le Conteneur n'existe pas");
        return false;
      }

      if (mounted) setState(() => _isLoading = true);

      // Appel au service
      final result = await _harborServices.retrieveContainerToHarbor(
        container.id!.toInt(),
        user.id.toInt(),
        widget.harbor.id,
      );

      if (result == "SUCCESS" && mounted) {
        // Rafraîchir les données du port
        final updatedHarbor = await _harborServices.getHarborDetails(
          widget.harbor.id,
        );
        setState(() {
          widget.harbor.containers = updatedHarbor.containers;
        });
        showSuccessTopSnackBar(context, "Conteneur retiré avec succès");
        return true;
      } else if (result == "IMPOSSIBLE" && mounted) {
        showErrorTopSnackBar(
          context,
          "Impossible de retirer le conteneur: il contient encore des colis actifs",
        );
      } else if (result == "CONTAINER_ALREADY_RETRIEVED" && mounted) {
        showErrorTopSnackBar(context, "Le conteneur a déjà été retiré");
      }
      return false;
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          "Erreur lors de la suppression: ${e.toString()}",
        );
        log(e.toString());
      }
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showContainerDetails(Containers item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ContainerDetailsModal(item: item),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        widget.harbor.createdAt != null
            ? DateFormat.yMMMMEEEEd().format(widget.harbor.createdAt!)
            : 'Date non disponible';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150.0,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  widget.harbor.name ?? 'Port sans nom',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  maxLines: 2,
                ),
              ),
              centerTitle: true,
              background: Hero(
                tag: 'portImage-${widget.harbor.id}',
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.asset(
                        "assets/images/ports.jpg",
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        color: Colors.black.withOpacity(0.6),
                      ),
                      alignment: Alignment.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildHarborInfoSection(formattedDate),
          _buildContainersListSection(),
        ],
      ),
    );
  }

  SliverList _buildHarborInfoSection(String formattedDate) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Informations générales du port",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 5),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF7F78AF),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      icon: Icons.local_shipping,
                      text:
                          "Nom du port : ${widget.harbor.name ?? 'Non spécifié'}",
                    ),
                    _buildInfoRow(
                      icon: Icons.maps_home_work,
                      text:
                          "Adresse : ${widget.harbor.location ?? 'Non spécifiée'}",
                    ),
                    _buildInfoRow(
                      icon: Icons.calendar_month,
                      text: "Date de création : $formattedDate",
                    ),
                    _buildInfoRow(
                      icon: Icons.numbers,
                      text:
                          "Nombre de conteneur : ${widget.harbor.containers?.where((c) => c.status != Status.DELETE && c.status != Status.RETRIEVE).length ?? 0}",
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {},
                          label: const Text("Modifier"),
                          icon: const Icon(Icons.edit),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          label: const Text(
                            "Supprimer",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF7F78AF)),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  SliverList _buildContainersListSection() {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.harbor.containers?.isNotEmpty ?? false)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const TextButton(
                      onPressed: null,
                      child: Text(
                        "La liste des conteneurs",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _handleAddContainers,
                      label: const Text("Embarquer"),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              if (widget.harbor.containers == null ||
                  widget.harbor.containers!.isEmpty)
                _buildEmptyContainersState()
              else
                Column(
                  children:
                      widget.harbor.containers!
                          .where(
                            (element) =>
                                element.status != Status.DELETE &&
                                element.status != Status.RETRIEVE,
                          )
                          .map((item) => _buildContainerItem(item))
                          .toList(),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildEmptyContainersState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Pas de conteneurs pour ce port."),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleAddContainers,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              "Embarquer un conteneur",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7F78AF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerItem(Containers item) {
    return Dismissible(
      key: Key(item.id?.toString() ?? DateTime.now().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (_) => _handleContainerDismiss(item),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showContainerDetails(item),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.green[50]!,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Iconify(
                      Carbon.container_registry,
                      color:
                          item.isAvailable == true ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.reference ?? 'Sans référence',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Nombre de colis: ${item.packages?.where((c) => c.status != Status.DELETE && c.status != Status.DELETE_ON_CONTAINER).length ?? 0}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          "Dimensions: ${item.size} pieds",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _ContainerDetailsModal extends StatelessWidget {
  final Containers item;

  const _ContainerDetailsModal({required this.item, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            _buildHeader(context),
            _buildInfoSection(),
            _buildPackagesSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.green[50]!,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Iconify(
                  Carbon.container_registry,
                  color: item.isAvailable == true ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.reference ?? 'Détails du conteneur',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Dimensions', '${item.size} pieds'),
          _buildInfoRow(
            'Statut',
            item.isAvailable! ? 'Disponible' : 'Indisponible',
          ),
          _buildInfoRow('Date création', _formatDate(item.createdAt)),
        ],
      ),
    );
  }

  Widget _buildPackagesSection() {
    final packages =
        item.packages
            ?.where(
              (p) =>
                  p.status != Status.DELETE &&
                  p.status != Status.DELETE_ON_CONTAINER,
            )
            .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Colis (${packages?.length ?? 0})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (packages?.isEmpty ?? true)
            const Text('Aucun colis dans ce conteneur')
          else
            ...packages!.map((p) => _buildPackageItem(p)).toList(),
        ],
      ),
    );
  }

  Widget _buildPackageItem(Packages p) {
    return ListTile(
      leading: const Icon(Icons.inventory, color: Colors.grey),
      title: Text(p.reference ?? 'Colis sans référence'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Client: ${p.partnerName}'),
          Text('Téléphone: ${p.partnerPhoneNumber}'),
          Text('Nombre d\'article: ${p.items!.length}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    return date != null
        ? DateFormat.yMMMMd().add_Hm().format(date)
        : 'Non disponible';
  }
}
