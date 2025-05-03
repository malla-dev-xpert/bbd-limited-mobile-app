import 'dart:async';

import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/package.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/container_list_item.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/create_container_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/edit_package_modal.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

class ContainerScreen extends StatefulWidget {
  @override
  State<ContainerScreen> createState() => _ContainerScreen();
}

class _ContainerScreen extends State<ContainerScreen> {
  final TextEditingController searchController = TextEditingController();
  final ContainerServices _containerServices = ContainerServices();
  final AuthService _authService = AuthService();

  List<Containers> _allContainers = [];
  List<Containers> _filteredContainers = [];
  String? _currentFilter;

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
      _filteredContainers =
          _allContainers!.where((devise) {
            final reference = devise.reference!.toLowerCase();
            return reference.contains(query);
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
      print("Erreur de récupération des colis : $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditPackageModal(BuildContext context, Packages pkg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return EditPackageModal(
          package: pkg,
          onPackageUpdated: () => fetchContainers(reset: true),
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
        return CreateContainerForm();
      },
    );

    if (result == true) {
      fetchContainers(reset: true);
    }
  }

  Future<void> _deletePackage(Packages pkg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirmer la suppression"),
            content: Text(
              "Voulez-vous vraiment supprimer le colis ${pkg.reference}?",
            ),
            backgroundColor: Colors.white,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Annuler"),
              ),
              _isLoading
                  ? CircularProgressIndicator()
                  : TextButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      "Supprimer",
                      style: TextStyle(color: Colors.red, fontSize: 16),
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

      // await _containerServices.deletePackage(pkg.id, user.id.toInt());

      // setState(() {
      //   _allPackages.removeWhere((d) => d.id == pkg.id);
      //   _filteredPackages = List.from(_allPackages);
      // });

      showSuccessTopSnackBar(context, "Colis supprimé avec succès");
    } catch (e) {
      showErrorTopSnackBar(context, "Erreur lors de la suppression");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Gestion des conteneurs',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateConatinerBottomSheet(context),
        backgroundColor: const Color(0xFF1A1E49),
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
                    // onChanged: _filteredContainers,
                    controller: searchController,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Rechercher un conteneur...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Liste des colis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "La liste des conteneurs",

                  style: const TextStyle(
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
                    child:
                        _filteredContainers.isEmpty
                            ? Center(child: Text("Aucun conteneur trouvé."))
                            : RefreshIndicator(
                              onRefresh: () async {
                                await fetchContainers(reset: true);
                              },
                              displacement: 40,
                              color: Theme.of(context).primaryColor,
                              backgroundColor: Colors.white,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount:
                                    _filteredContainers.length +
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
                                    onTap: () {},
                                    // () => showPackageDetailsBottomSheet(
                                    //   context,
                                    //   pkg,
                                    //   1,
                                    //   true,
                                    // ),
                                    onEdit: () {},
                                    // () =>
                                    //     _showEditPackageModal(context, pkg),
                                    onDelete: () {},
                                    // () => _deletePackage(pkg),
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
}
