import 'dart:async';

import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/models/package.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/create_package_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/edit_package_modal.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/packages_list.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/widgets/package_detail_modal.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

class PackageScreen extends StatefulWidget {
  @override
  State<PackageScreen> createState() => _PackageScreen();
}

class _PackageScreen extends State<PackageScreen> {
  final TextEditingController searchController = TextEditingController();
  final PackageServices _packageServices = PackageServices();
  final AuthService _authService = AuthService();

  List<Packages> _allPackages = [];
  List<Packages> _filteredPackages = [];
  String? _currentFilter;

  bool _isLoading = false;
  bool _hasMoreData = true;
  int currentPage = 0;

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
    fetchPackages();
    _refreshController.stream.listen((_) {
      fetchPackages(reset: true);
    });
  }

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  Future<void> fetchPackages({bool reset = false}) async {
    if (_isLoading || (!reset && !_hasMoreData)) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        currentPage = 0;
        _hasMoreData = true;
        _allPackages = [];
      }
    });
    try {
      final packages = await _packageServices.findAll(page: currentPage);

      setState(() {
        _allPackages.addAll(packages);
        _filteredPackages = List.from(_allPackages);

        if (packages.isEmpty || packages.length < 30) {
          _hasMoreData = false;
        } else {
          currentPage++;
        }
      });
    } catch (e) {
      showErrorTopSnackBar(context, "Erreur de récupération des colis.");
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
          onPackageUpdated: () => fetchPackages(reset: true),
        );
      },
    );
  }

  void filterPackages(String query) {
    setState(() {
      _filteredPackages =
          _allPackages.where((pkg) {
            final searchPackage = pkg.reference!.toLowerCase().contains(
              query.toLowerCase(),
            );

            bool allStatus = true;
            if (_currentFilter == 'receptionnes') {
              allStatus = pkg.status == Status.RECEIVED;
            } else if (_currentFilter == 'en_attente') {
              allStatus = pkg.status == Status.PENDING;
            } else if (_currentFilter == 'delivered') {
              allStatus = pkg.status == Status.DELIVERED;
            }

            return searchPackage && allStatus;
          }).toList();
    });
  }

  void handleStatusFilter(String value) {
    setState(() {
      _currentFilter = value;
    });

    filterPackages(searchController.text);
  }

  Future<void> _openCreatePackageBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return CreatePackageForm();
      },
    );

    if (result == true) {
      fetchPackages(reset: true);
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

      await _packageServices.deletePackage(pkg.id!, user.id.toInt());

      setState(() {
        _allPackages.removeWhere((d) => d.id == pkg.id);
        _filteredPackages = List.from(_allPackages);
      });

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
          'Gestion des colis',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreatePackageBottomSheet(context),
        backgroundColor: const Color(0xFF1A1E49),
        heroTag: 'package_fab',
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
                    onChanged: filterPackages,
                    controller: searchController,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Rechercher un colis...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                FiltreDropdown(onSelected: handleStatusFilter),
              ],
            ),
            const SizedBox(height: 20),

            // Liste des colis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "La liste des colis${_currentFilter == null
                      ? ''
                      : _currentFilter == 'receptionnes'
                      ? ' réceptionnés'
                      : _currentFilter == 'delivered'
                      ? 'livrés'
                      : ' en attente'}",

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentFilter != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentFilter = null;
                        _filteredPackages = _allPackages;
                        if (searchController.text.isNotEmpty) {
                          filterPackages(searchController.text);
                        }
                      });
                    },
                    child: const Text("Voir tout"),
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
                        fetchPackages();
                      }
                      return false;
                    },
                    child:
                        _filteredPackages.isEmpty
                            ? Center(child: Text("Aucun colis trouvé."))
                            : RefreshIndicator(
                              onRefresh: () async {
                                await fetchPackages(reset: true);
                              },
                              displacement: 40,
                              color: Theme.of(context).primaryColor,
                              backgroundColor: Colors.white,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount:
                                    _filteredPackages.length +
                                    (_hasMoreData && _isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _filteredPackages.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final pkg = _filteredPackages[index];

                                  return PackageListItem(
                                    packages: pkg,
                                    onTap:
                                        () => showPackageDetailsBottomSheet(
                                          context,
                                          pkg,
                                          1,
                                          true,
                                        ),
                                    onEdit:
                                        () =>
                                            _showEditPackageModal(context, pkg),
                                    onDelete: () => _deletePackage(pkg),
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

class FiltreDropdown extends StatelessWidget {
  final Function(String) onSelected;

  const FiltreDropdown({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF7F78AF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<String>(
        icon: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, color: Colors.white),
            SizedBox(width: 8),
            Text('Filtrer', style: TextStyle(color: Colors.white)),
            SizedBox(width: 8),
          ],
        ),
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onSelected: onSelected,
        itemBuilder:
            (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'receptionnes',
                child: Text('Colis réceptionnés'),
              ),
              const PopupMenuItem<String>(
                value: 'en_attente',
                child: Text('Colis en attente'),
              ),
              const PopupMenuItem<String>(
                value: 'delivered',
                child: Text('Colis livrés'),
              ),
            ],
      ),
    );
  }
}
