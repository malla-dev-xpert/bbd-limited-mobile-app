import 'dart:developer';

import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/harbor_services.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/harbor.dart';
import 'package:bbd_limited/models/packages.dart';
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
  bool _isRefreshing = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Containers> get _filteredContainers {
    if (_searchQuery.isEmpty) {
      return widget.harbor.containers
              ?.where((c) =>
                  c.status != Status.DELETE && c.status != Status.RETRIEVE)
              .toList() ??
          [];
    }
    return widget.harbor.containers
            ?.where((c) =>
                c.status != Status.DELETE &&
                c.status != Status.RETRIEVE &&
                (c.reference
                        ?.toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ??
                    false))
            .toList() ??
        [];
  }

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

  Future<void> fetchPackages() async {
    try {
      final updatedHarbor = await _harborServices.getHarborDetails(
        widget.harbor.id,
      );
      if (mounted) {
        setState(() {
          widget.harbor.containers = updatedHarbor.containers;
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          "Erreur lors de l'actualisation: ${e.toString()}",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = widget.harbor.createdAt != null
        ? DateFormat.yMMMMEEEEd().format(widget.harbor.createdAt!)
        : 'Date non disponible';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            actions: [
              IconButton(
                onPressed: _isRefreshing
                    ? null
                    : () async {
                        setState(() => _isRefreshing = true);
                        await fetchPackages();
                        if (mounted) {
                          setState(() => _isRefreshing = false);
                        }
                      },
                tooltip: 'Rafraîchir',
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(200),
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Color(0xFF1A1E49),
                        ),
                      ),
              ),
            ],
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Padding(
                padding: const EdgeInsets.all(0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.harbor.name ?? 'Port sans nom',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.harbor.location ?? 'Adresse non spécifiée',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory,
                                size: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "${widget.harbor.containers?.where((c) => c.status != Status.DELETE && c.status != Status.RETRIEVE).length ?? 0} conteneurs",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
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
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildContainersListSection(),
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
              if (widget.harbor.containers?.isNotEmpty ?? false) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Liste des conteneurs",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _handleAddContainers,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF7F78AF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      label: const Text("Embarquer"),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher un conteneur...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (widget.harbor.containers == null ||
                  widget.harbor.containers!.isEmpty)
                _buildEmptyContainersState()
              else if (_searchQuery.isNotEmpty && _filteredContainers.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Aucun conteneur trouvé",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Aucun conteneur ne correspond à votre recherche",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _filteredContainers
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
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height * 0.2),
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
      ),
    );
  }

  Widget _buildContainerItem(Containers item) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(item.id?.toString() ?? DateTime.now().toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          child: const Icon(Icons.delete, color: Colors.white, size: 30),
        ),
        confirmDismiss: (_) => _handleContainerDismiss(item),
        child: InkWell(
          onTap: () => _showContainerDetails(item),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.green[50]!,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Iconify(
                    Carbon.container_registry,
                    size: 24,
                    color:
                        item.isAvailable == true ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.reference ?? 'Sans référence',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${item.packages?.where((c) => c.status != Status.DELETE && c.status != Status.DELETE_ON_CONTAINER).length ?? 0} colis",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.straighten,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${item.size} pieds",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_3,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.supplier_id != null
                                ? '${item.supplierName ?? ""} | ${item.supplierPhone ?? ""}'
                                : 'BBD Limited',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
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
    final packages = item.packages
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
      title: Text(p.ref ?? 'Colis sans référence'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Client: ${p.clientName}'),
          Text('Téléphone: ${p.clientPhone}'),
          Text('Nombre d\'article: ${p.itemQuantity}'),
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
