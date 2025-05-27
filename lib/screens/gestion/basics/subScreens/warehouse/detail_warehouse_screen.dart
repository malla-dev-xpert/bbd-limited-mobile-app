import 'dart:async';
import 'dart:developer';

import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/core/services/warehouse_services.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/models/warehouses.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/package_details_bottom_sheet.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/package_list_item.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/widgets/add_package_to_warehouse.dart';
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

class _WarehouseDetailPageState extends State<WarehouseDetailPage>
    with SingleTickerProviderStateMixin {
  // Contrôleurs et services
  final TextEditingController searchController = TextEditingController();
  final PackageServices packageServices = PackageServices();
  final AuthService _authService = AuthService();
  final WarehouseServices _warehouseServices = WarehouseServices();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _adressController = TextEditingController();
  final TextEditingController _storageTypeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Animation controllers
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  // State variables
  List<Packages> _allPackages = [];
  List<Packages> _filteredPackages = [];
  String? _currentFilter;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRefreshing = false;
  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name ?? '';
    _adressController.text = widget.adresse ?? '';
    _storageTypeController.text = widget.storageType ?? '';

    _initializeAnimation();
    fetchPackages();
    _refreshController.stream.listen((_) => fetchPackages());
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeIn),
    );

    _animationController!.forward();
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

  Future<void> fetchPackages({bool reset = false, String? searchQuery}) async {
    try {
      final packages = await packageServices.findByWarehouse(
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
            final searchPackage = pkg.ref!.toLowerCase().contains(
              query.toLowerCase(),
            );

            bool allStatus = true;
            if (_currentFilter == 'livres') {
              allStatus = pkg.status == Status.DELIVERED;
            } else if (_currentFilter == 'en_transit') {
              allStatus = pkg.status == Status.INPROGRESS;
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
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A1E49),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1E49),
                const Color(0xFF1A1E49).withOpacity(0.8),
              ],
            ),
          ),
        ),
        title: Text(
          'Détail : ${widget.name}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon:
                _isRefreshing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Icon(Icons.refresh),
            onPressed:
                _isRefreshing
                    ? null
                    : () async {
                      setState(() => _isRefreshing = true);
                      await fetchPackages();
                      if (mounted) {
                        setState(() => _isRefreshing = false);
                      }
                    },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPackageModal,
        backgroundColor: const Color(0xFF1A1E49),
        heroTag: 'warehouse_detail_fab',
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Ajouter un colis',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body:
          _fadeAnimation != null
              ? FadeTransition(
                opacity: _fadeAnimation!,
                child: SafeArea(
                  child: CustomScrollView(
                    slivers: [
                      // Section des informations de l'entrepôt
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.white, Colors.grey[50]!],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Informations de l'entrepôt",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              onPressed:
                                                  () => _updateWarehouse(),
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Color(0xFF7F78AF),
                                              ),
                                              tooltip: 'Modifier',
                                            ),
                                            IconButton(
                                              onPressed:
                                                  () => _deleteWarehouse(
                                                    Warehouses(
                                                      id: widget.warehouseId,
                                                      name: widget.name,
                                                    ),
                                                  ),
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              tooltip: 'Supprimer',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow(
                                      Icons.warehouse,
                                      widget.name!,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.map_rounded,
                                      widget.adresse!,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.type_specimen_rounded,
                                      widget.storageType!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Barre de recherche fixe
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SearchBarDelegate(
                          child: Container(
                            color: Colors.grey[50],
                            padding: const EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 20,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        onChanged: filterPackages,
                                        controller: searchController,
                                        decoration: InputDecoration(
                                          hintText: 'Rechercher un colis...',
                                          prefixIcon: const Icon(
                                            Icons.search,
                                            color: Color(0xFF7F78AF),
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FiltreDropdown(
                                      onSelected: handleStatusFilter,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Liste des colis
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // En-tête de la liste
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Liste des colis${_currentFilter == null
                                        ? ''
                                        : _currentFilter == 'livres'
                                        ? ' livrés'
                                        : _currentFilter == 'en_transit'
                                        ? ' en transit'
                                        : ' en attente'}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1E49),
                                    ),
                                  ),
                                  if (_currentFilter != null)
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _currentFilter = null;
                                          _filteredPackages = _allPackages;
                                          if (searchController
                                              .text
                                              .isNotEmpty) {
                                            filterPackages(
                                              searchController.text,
                                            );
                                          }
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.clear_all,
                                        size: 18,
                                      ),
                                      label: const Text("Voir tout"),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF7F78AF,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      // Liste des colis
                      _filteredPackages.isEmpty
                          ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Aucun colis trouvé",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final pkg = _filteredPackages[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: PackageListItem(
                                  packages: pkg,
                                  onTap:
                                      () => _openPackageDetailsBottomSheet(
                                        context,
                                        pkg,
                                      ),
                                ),
                              );
                            }, childCount: _filteredPackages.length),
                          ),
                    ],
                  ),
                ),
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _openPackageDetailsBottomSheet(
    BuildContext context,
    Packages package,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return PackageDetailsBottomSheet(
          packages: package,
          onStart: (updatedExpedition) {
            fetchPackages(reset: true);
          },
          onEdit: (updatedExpedition) async {
            try {
              final packageServices = PackageServices();
              final authServices = AuthService();
              final user = await authServices.getUserInfo();
              final result = await packageServices.updateExpedition(
                updatedExpedition.id!,
                updatedExpedition,
                user!.id,
              );
              if (result == "SUCCESS") {
                if (context.mounted) {
                  showSuccessTopSnackBar(
                    context,
                    "Colis ${updatedExpedition.ref} modifiée avec succès.",
                  );
                  fetchPackages(reset: true);
                }
              } else {
                if (context.mounted) {
                  showErrorTopSnackBar(
                    context,
                    "Erreur lors de la modification du colis",
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                showErrorTopSnackBar(
                  context,
                  "Erreur lors de la modification du colis",
                );
              }
            }
          },
          onDelete: (updatedExpedition) {
            fetchPackages(reset: true);
          },
        );
      },
    );

    if (result == true) {
      fetchPackages(reset: true);
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF7F78AF)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, color: Color(0xFF1A1E49)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _adressController.dispose();
    _storageTypeController.dispose();
    searchController.dispose();
    _refreshController.close();
    _animationController?.dispose();
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7F78AF).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        icon: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Filtrer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onSelected: onSelected,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder:
            (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'livres',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Colis livrés'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'en_transit',
                child: Row(
                  children: [
                    Icon(Icons.local_shipping, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('Colis en transit'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'en_attente',
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Colis en attente'),
                  ],
                ),
              ),
            ],
      ),
    );
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SearchBarDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 80.0;

  @override
  double get minExtent => 80.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
