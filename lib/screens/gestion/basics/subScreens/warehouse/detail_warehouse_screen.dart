import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/models/package.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/widgets/add_package_to_warehouse.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/widgets/package_detail_modal.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

class WarehouseDetailPage extends StatefulWidget {
  final int warehouseId;
  final String? name;
  final String? adresse;
  final String? storageType;

  const WarehouseDetailPage({
    super.key,
    required this.warehouseId,
    this.name,
    this.adresse,
    this.storageType,
  });

  @override
  State<WarehouseDetailPage> createState() => _WarehouseDetailPageState();
}

class _WarehouseDetailPageState extends State<WarehouseDetailPage> {
  final TextEditingController searchController = TextEditingController();
  final PackageServices _packageServices = PackageServices();
  final AuthService _authService = AuthService();

  List<Packages> _allPackages = [];
  List<Packages> _filteredPackages = [];
  String? _currentFilter;

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  Future<void> fetchPackages() async {
    try {
      final packages = await _packageServices.findByWarehouse(
        widget.warehouseId.toInt(),
      );

      setState(() {
        _allPackages = packages;
        _filteredPackages = packages;
      });
    } catch (e) {
      print("Erreur de récupération des colis : $e");
    }
  }

  void _openAddPackageModal() async {
    final result = await showAddPackageModal(context, widget.warehouseId);

    if (result == true) {
      await fetchPackages();
      setState(() {});
    }
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
            }

            return searchPackage && allStatus;
          }).toList();
    });
  }

  Color getStatusColor(Status? status) {
    switch (status) {
      case Status.PENDING:
        return Colors.orange;
      case Status.RECEIVED:
        return Colors.green;
      case Status.DELIVERED:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void handleStatusFilter(String value) {
    setState(() {
      _currentFilter = value;
    });

    filterPackages(searchController.text);
  }

  void onAddPackagePressed() {
    // Tu peux ici ouvrir une modal ou naviguer vers une page d'ajout
    print("Ajouter un colis à l'entrepôt ${widget.warehouseId}");
  }

  @override
  Widget build(BuildContext context) {
    // final bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Détail : ${widget.name}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte d'info entrepôt
            Text("Informations de l'entrepot", textAlign: TextAlign.left),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: const Color(0xFFF3F4F6),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  spacing: 10,
                  children: [
                    Row(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warehouse,
                          size: 20,
                          color: const Color(0xFF7F78AF),
                        ),
                        Expanded(
                          child: Text(
                            widget.name!,
                            style: TextStyle(fontWeight: FontWeight.w600),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.map_rounded,
                          size: 20,
                          color: const Color(0xFF7F78AF),
                        ),
                        Expanded(
                          child: Text(
                            widget.adresse!,
                            style: TextStyle(fontWeight: FontWeight.w600),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.type_specimen_rounded,
                          size: 20,
                          color: const Color(0xFF7F78AF),
                        ),
                        Expanded(
                          child: Text(
                            widget.storageType!,
                            style: TextStyle(fontWeight: FontWeight.w600),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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

                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1E49),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: _openAddPackageModal,
                    icon: const Icon(Icons.add, color: Colors.white, size: 24),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 50,
                      minHeight: 50,
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
                  "La liste des colis${_currentFilter == null
                      ? ''
                      : _currentFilter == 'receptionnes'
                      ? ' réceptionnés'
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
            Expanded(
              child:
                  _filteredPackages.isEmpty
                      ? Center(child: Text("Aucun colis trouvé."))
                      : ListView.builder(
                        itemCount: _filteredPackages.length,
                        itemBuilder: (context, index) {
                          final pkg = _filteredPackages[index];
                          return Dismissible(
                            key: Key(pkg.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              padding: const EdgeInsets.only(right: 16),
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              try {
                                final user = await _authService.getUserInfo();
                                if (user == null) {
                                  showErrorTopSnackBar(
                                    context,
                                    "Erreur: Utilisateur non connecté",
                                  );
                                  return;
                                }

                                await _packageServices.deletePackage(
                                  pkg.id,
                                  user.id.toInt(),
                                );

                                setState(() {
                                  _allPackages.removeWhere(
                                    (d) => d.id == pkg.id,
                                  );
                                  _filteredPackages = List.from(_allPackages);
                                });

                                showSuccessTopSnackBar(
                                  context,
                                  "Colis supprimé avec succès",
                                );
                              } catch (e) {
                                showErrorTopSnackBar(
                                  context,
                                  "Erreur lors de la suppression",
                                );
                              }
                            },
                            child: ListTile(
                              onTap: () async {
                                showPackageDetailsBottomSheet(
                                  context,
                                  pkg,
                                  widget.warehouseId.toInt(),
                                );
                              },
                              leading: Icon(
                                Icons.inventory,
                                color: getStatusColor(pkg.status),
                              ),
                              title: Text(pkg.reference!),
                              subtitle: Text("Dimensions: ${pkg.dimensions}"),
                              trailing: Text(
                                "Poids: ${pkg.weight!} kg",
                                style: TextStyle(
                                  color: const Color(0xFF7F78AF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
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
            ],
      ),
    );
  }
}
