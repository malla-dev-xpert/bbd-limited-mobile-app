import 'dart:async';
import 'dart:developer';

import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/core/services/warehouse_services.dart';
import 'package:bbd_limited/models/package.dart';
import 'package:bbd_limited/models/warehouses.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/widgets/add_package_to_warehouse.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/widgets/package_detail_modal.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

class WarehouseDetailPage extends StatefulWidget {
  final int warehouseId;
  final String? name;
  final String? adresse;
  final String? storageType;
  final Function()? onWarehouseUpdated;

  const WarehouseDetailPage({
    super.key,
    required this.warehouseId,
    this.name,
    this.adresse,
    this.storageType,
    this.onWarehouseUpdated,
  });

  @override
  State<WarehouseDetailPage> createState() => _WarehouseDetailPageState();
}

class _WarehouseDetailPageState extends State<WarehouseDetailPage> {
  // Contrôleurs et services
  final TextEditingController searchController = TextEditingController();
  final PackageServices _packageServices = PackageServices();
  final AuthService _authService = AuthService();
  final WarehouseServices _warehouseServices = WarehouseServices();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _adressController = TextEditingController();
  final TextEditingController _storageTypeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  // final ScrollController _scrollController = ScrollController();

  // State variables
  List<Packages> _allPackages = [];
  List<Packages> _filteredPackages = [];
  String? _currentFilter;
  bool _isLoading = false;
  String? _errorMessage;
  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name ?? '';
    _adressController.text = widget.adresse ?? '';
    _storageTypeController.text = widget.storageType ?? '';
    fetchPackages();
    _refreshController.stream.listen((_) => fetchPackages());
  }

  Future<void> _updateWarehouse() async {
    try {
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _buildEditWarehouseModal(context),
      );
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          "Erreur lors de la modification: ${e.toString()}",
        );
      }
    }
  }

  Future<void> _handleWarehouseUpdate() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.getUserInfo();
      if (user == null || user.id == null) {
        setState(() {
          _errorMessage = "Erreur: Utilisateur non connecté ou ID manquant";
          _isLoading = false;
        });
        return;
      }

      if (_nameController.text.isEmpty ||
          _adressController.text.isEmpty ||
          _storageTypeController.text.isEmpty) {
        setState(() {
          _errorMessage = "Tous les champs doivent être remplis";
          _isLoading = false;
        });
        return;
      }

      final warehouseData = Warehouses(
        id: widget.warehouseId,
        name: _nameController.text,
        adresse: _adressController.text,
        storageType: _storageTypeController.text,
      );

      final result = await _warehouseServices.updateWarehouse(
        widget.warehouseId,
        warehouseData,
        user.id,
      );
      log(result.toString());

      if (result == true) {
        if (mounted) {
          Navigator.pop(context, true);
          showSuccessTopSnackBar(context, "Entrepôt modifié avec succès");
          _refreshController.add(null);
          final updatedWarehouse = await _warehouseServices.getWarehouseById(
            widget.warehouseId,
          );

          if (updatedWarehouse != null && mounted) {
            // Notifier le screen parent
            if (widget.onWarehouseUpdated != null) {
              widget.onWarehouseUpdated!();
            }
            Navigator.pop(context);
          }
        }
      } else {
        if (mounted) {
          showErrorTopSnackBar(context, "Ce nom est déjà utilisé");
          setState(() => _isLoading = false);
        }
      }
    } catch (e, stackTrace) {
      log(
        "Erreur lors de la modification de l'entrepôt",
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        showErrorTopSnackBar(context, "Erreur technique: ${e.toString()}");
        setState(() => _isLoading = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildEditWarehouseModal(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Modifier l\'entrepôt',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close_rounded, size: 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Nom
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.warehouse),
                      labelText: 'Nom de l\'entrepôt',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Adresse
                  TextFormField(
                    controller: _adressController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.maps_home_work),
                      labelText: 'Adresse de l\'entrepôt',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Type de stockage
                  TextFormField(
                    controller: _storageTypeController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.storage),
                      labelText: 'Type de stockage',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Erreur éventuelle
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 10),

                  // Bouton de confirmation
                  confirmationButton(
                    isLoading: _isLoading,
                    onPressed: _handleWarehouseUpdate,
                    label: "Modifier",
                    icon: Icons.edit_document,
                    subLabel: "Modification...",
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
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

  Future<Warehouses?> _deleteWarehouse(Warehouses warehouse) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirmer la suppression"),
            backgroundColor: Colors.white,
            content: Text("Supprimer le magasin ${warehouse.name}?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Annuler"),
              ),
              TextButton.icon(
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

    if (confirmed == true) {
      try {
        final user = await _authService.getUserInfo();

        if (user == null) {
          showErrorTopSnackBar(context, "Veuillez vous connecter.");
          return null;
        }
        setState(() => _isLoading = true);
        final result = await _warehouseServices.deleteWarehouse(
          warehouse.id,
          user.id,
        );

        if (result == "DELETED") {
          Navigator.pop(context, true);
          showSuccessTopSnackBar(context, "Warehouse supprimé avec succès");
        } else if (result == "PACKAGE_FOUND") {
          showErrorTopSnackBar(
            context,
            "Impossible de supprimer - Il y'a des colis existants pour ce magasin.",
          );
        }
      } catch (e) {
        showErrorTopSnackBar(context, "Erreur lors de la suppression");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
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
              color: Colors.white,
              elevation: 3,
              shadowColor: Colors.grey[50],
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
                    Row(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => _updateWarehouse(),
                          label: Text(
                            "Modifier",
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                          icon: const Icon(
                            Icons.edit_document,
                            color: Colors.blueGrey,
                          ),
                        ),
                        TextButton.icon(
                          onPressed:
                              () => _deleteWarehouse(
                                Warehouses(
                                  id: widget.warehouseId,
                                  name: widget.name,
                                ),
                              ),
                          label: Text(
                            "Supprimer cet entrepôt",
                            style: TextStyle(color: Colors.red),
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
                      : RefreshIndicator(
                        onRefresh: () async {
                          await fetchPackages();
                        },
                        displacement: 40,
                        color: Theme.of(context).primaryColor,
                        backgroundColor: Colors.white,
                        child: ListView.builder(
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
                                    false,
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _adressController.dispose();
    _storageTypeController.dispose();
    searchController.dispose();
    _refreshController.close();
    super.dispose();
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
        color: Colors.white,
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
