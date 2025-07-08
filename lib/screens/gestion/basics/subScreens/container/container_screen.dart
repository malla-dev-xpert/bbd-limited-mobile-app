import 'dart:async';

import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/container_detail_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/container_list_item.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/create_container_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/edit_container_modal.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/enums/status.dart';

class ContainerScreen extends StatefulWidget {
  const ContainerScreen({super.key});

  @override
  State<ContainerScreen> createState() => _ContainerScreen();
}

class _ContainerScreen extends State<ContainerScreen> {
  final TextEditingController searchController = TextEditingController();
  final ContainerServices _containerServices = ContainerServices();
  final AuthService _authService = AuthService();

  List<Containers> _allContainers = [];
  List<Containers> _filteredContainers = [];
  Status? _selectedStatus;

  bool _isLoading = false;
  bool _hasMoreData = true;
  int currentPage = 0;

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
    fetchContainers();
    searchController.addListener(_onSearchChanged);
    _refreshController.stream.listen((_) {
      fetchContainers(reset: true);
    });
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();

    setState(() {
      _filteredContainers = _allContainers.where((container) {
        final reference = container.reference!.toLowerCase();
        final matchesSearch = reference.contains(query);
        final matchesStatus = _selectedStatus == null ||
            (container.status != null && container.status == _selectedStatus);
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  @override
  void dispose() {
    _refreshController.close();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchContainers({bool reset = false}) async {
    if (_isLoading || (!reset && !_hasMoreData)) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        currentPage = 0;
        _hasMoreData = true;
        _allContainers = [];
      }
    });
    try {
      final containers = await _containerServices.findAll(page: currentPage);

      setState(() {
        _allContainers.addAll(containers);
        _filteredContainers = List.from(_allContainers);

        if (containers.isEmpty || containers.length < 30) {
          _hasMoreData = false;
        } else {
          currentPage++;
        }
      });
    } catch (e) {
      showErrorTopSnackBar(context, "Erreur de chargement des colis.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditContainerModal(BuildContext context, Containers container) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return EditContainerModal(
          container: container,
          onContainerUpdated: () => fetchContainers(reset: true),
        );
      },
    );
  }

  Future<void> _openCreateConatinerBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return const CreateContainerForm();
      },
    );

    if (result == true) {
      fetchContainers(reset: true);
    }
  }

  Future<void> _delete(Containers container) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text(
          "Voulez-vous vraiment supprimer le conteneur ${container.reference}?",
        ),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete, color: Colors.red),
            label: Text(
              _isLoading ? 'Suppression...' : 'Supprimer',
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = await _authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context, "Erreur: Utilisateur non connecté");
        return;
      }

      final result = await _containerServices.delete(
        container.id!,
        user.id.toInt(),
      );

      if (result == "DELETED") {
        setState(() {
          _allContainers.removeWhere((d) => d.id == container.id);
          _filteredContainers = List.from(_allContainers);
        });

        showSuccessTopSnackBar(context, "Conteneur supprimé avec succès");
      } else if (result == "CONTAINER_NOT_FOUND") {
        showErrorTopSnackBar(context, "Conteneur introuvable");
      } else if (result == "PACKAGE_EXIST") {
        showErrorTopSnackBar(
          context,
          "Impossible de supprimer : Des colis existent dans ce conteneur.",
        );
      }
    } catch (e) {
      showErrorTopSnackBar(context, "Erreur lors de la suppression");
    }
  }

  String _getStatusLabel(Status? status) {
    if (status == null) return 'Tous';
    switch (status) {
      case Status.PENDING:
        return 'En attente';
      case Status.INPROGRESS:
        return 'En transit';
      case Status.RECEIVED:
        return 'Arrivé à destination';
      default:
        return status.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Gestion des conteneurs',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateConatinerBottomSheet(context),
        backgroundColor: const Color(0xFF1A1E49),
        heroTag: 'container_fab',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Barre de recherche
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Rechercher un conteneur...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filtre de statut
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip(null, 'Tous'),
                  _buildStatusChip(
                      Status.PENDING, _getStatusLabel(Status.PENDING)),
                  _buildStatusChip(
                      Status.INPROGRESS, _getStatusLabel(Status.INPROGRESS)),
                  _buildStatusChip(
                      Status.RECEIVED, _getStatusLabel(Status.RECEIVED)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Liste des colis
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "La liste des conteneurs",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo.metrics.pixels ==
                                scrollInfo.metrics.maxScrollExtent &&
                            !_isLoading &&
                            _hasMoreData) {
                          fetchContainers();
                        }
                        return false;
                      },
                      child: _filteredContainers.isEmpty
                          ? const Center(child: Text("Aucun conteneur trouvé."))
                          : RefreshIndicator(
                              onRefresh: () async {
                                await fetchContainers(reset: true);
                              },
                              displacement: 40,
                              color: Theme.of(context).primaryColor,
                              backgroundColor: Colors.white,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _filteredContainers.length +
                                    (_hasMoreData && _isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _filteredContainers.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final container = _filteredContainers[index];

                                  return ContainerListItem(
                                    container: container,
                                    onTap: () async {
                                      final updatedContainer =
                                          await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ContainerDetailPage(
                                            container: container,
                                            onContainerUpdated: (updated) {
                                              setState(() {
                                                final idx = _filteredContainers
                                                    .indexWhere((c) =>
                                                        c.id == updated.id);
                                                if (idx != -1) {
                                                  _filteredContainers[idx] =
                                                      updated;
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      );
                                      if (updatedContainer != null) {
                                        setState(() {
                                          final idx = _filteredContainers
                                              .indexWhere((c) =>
                                                  c.id == updatedContainer.id);
                                          if (idx != -1) {
                                            _filteredContainers[idx] =
                                                updatedContainer;
                                          }
                                        });
                                      }
                                    },
                                    onEdit: () => _showEditContainerModal(
                                        context, container),
                                    onDelete: () => _delete(container),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(Status? status, String label) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1A1E49),
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF1A1E49),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF1A1E49) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        onSelected: (bool selected) {
          setState(() {
            _selectedStatus = selected ? status : null;
            _onSearchChanged();
          });
        },
      ),
    );
  }
}
