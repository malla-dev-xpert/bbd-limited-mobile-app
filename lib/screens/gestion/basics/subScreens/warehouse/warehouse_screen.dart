import 'dart:async';
import 'dart:ui';

import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/services/warehouse_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/models/warehouses.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/detail_warehouse_screen.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseState();
}

class _WarehouseState extends State<WarehouseScreen> {
  final _formKey = GlobalKey<FormState>();
  final WarehouseServices warehousServices = WarehouseServices();
  final AuthService authService = AuthService();

  String formattedDate = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _adressController = TextEditingController();
  final TextEditingController _storageTypeController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  late final KeyboardVisibilityController _keyboardVisibilityController;
  late final StreamSubscription<bool> _keyboardSubscription;

  final TextEditingController _searchController = TextEditingController();

  List<Warehouses> _allWarehouses = [];
  List<Warehouses> _filteredWarehouse = [];
  int currentPage = 0;

  bool _isLoading = false;
  String? _errorMessage;

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
    loadWarehouses();
    _searchController.addListener(_onSearchChanged);
    _refreshController.stream.listen((_) {
      loadWarehouses(reset: true);
    });

    _keyboardVisibilityController = KeyboardVisibilityController();
    _keyboardSubscription = _keyboardVisibilityController.onChange.listen((
      visible,
    ) {
      if (!visible) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _hasMoreData = true;

  Future<void> loadWarehouses({bool reset = false}) async {
    if (_isLoading || (!reset && !_hasMoreData)) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        currentPage = 0;
        _hasMoreData = true;
        _allWarehouses = [];
      }
    });

    try {
      final result = await warehousServices.findAllWarehouses(
        page: currentPage,
      );

      setState(() {
        _allWarehouses.addAll(result);
        _filteredWarehouse = List.from(_allWarehouses);

        if (result.isEmpty || result.length < 30) {
          _hasMoreData = false;
        } else {
          currentPage++;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur de chargement: ${e.toString()}";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();

    if (_allWarehouses == []) return;

    setState(() {
      _filteredWarehouse = _allWarehouses.where((warehouse) {
        final adresse = warehouse.adresse?.toLowerCase() ?? '';
        final name = warehouse.name?.toLowerCase() ?? '';
        final storageType = warehouse.storageType?.toLowerCase() ?? '';

        return name.contains(query) ||
            adresse.contains(query) ||
            storageType.contains(query);
      }).toList();
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = null;
    });

    final user = await authService.getUserInfo();
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Erreur: Utilisateur non connecté";
      });
      return;
    }

    try {
      final success = await warehousServices.create(
        _nameController.text,
        _adressController.text,
        _storageTypeController.text,
        user.id,
      );

      if (success == "NAME_EXIST") {
        setState(() {
          _errorMessage =
              "Le nom '${_nameController.text}' existe déjà. Veuillez en choisir un autre.";
          _isLoading = false;
        });
        return;
      }

      if (success == "ADRESS_EXIST") {
        setState(() {
          _errorMessage =
              "L'adresse '${_adressController.text}' existe déjà. Veuillez en choisir une autre.";
          _isLoading = false;
        });
        return;
      }

      if (success == "CREATED") {
        _nameController.clear();
        _adressController.clear();
        _storageTypeController.clear();

        setState(() {
          _isLoading = false;
        });

        Navigator.of(context).pop();

        showSuccessTopSnackBar(context, 'Entrepôt créé avec succès!');
        _refreshController.add(null);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur liée au serveur, veuillez réessayer plus tard.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateWarehouse(Warehouses warehouse) async {
    try {
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _buildEditWarehouseModal(context, warehouse),
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

  Future<void> _deleteWarehouse(Warehouses warehouse) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = await authService.getUserInfo();

        if (user == null) {
          showErrorTopSnackBar(context, "Veuillez vous connecter.");
          return;
        }
        setState(() => _isLoading = true);
        final result = await warehousServices.deleteWarehouse(
          warehouse.id,
          user.id,
        );

        if (result == "DELETED") {
          showSuccessTopSnackBar(context, "Entrepôt supprimé avec succès");
          _refreshController.add(null);
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

  Future<void> _handleWarehouseUpdate(Warehouses warehouse) async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await authService.getUserInfo();
      if (user == null) {
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
        id: warehouse.id,
        name: _nameController.text,
        adresse: _adressController.text,
        storageType: _storageTypeController.text,
      );

      final result = await warehousServices.updateWarehouse(
        warehouse.id,
        warehouseData,
        user.id,
      );

      if (result == true) {
        if (mounted) {
          Navigator.pop(context, true);
          showSuccessTopSnackBar(context, "Entrepôt modifié avec succès");
          _refreshController.add(null);
        }
      } else {
        if (mounted) {
          showErrorTopSnackBar(context, "Ce nom est déjà utilisé");
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
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

  Widget _buildEditWarehouseModal(BuildContext context, Warehouses warehouse) {
    // Initialiser les contrôleurs avec les valeurs actuelles
    _nameController.text = warehouse.name ?? '';
    _adressController.text = warehouse.adresse ?? '';
    _storageTypeController.text = warehouse.storageType ?? '';

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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez definir un nom';
                      }
                      return null;
                    },
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez definir une adresse';
                      }
                      return null;
                    },
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez definir un type de stockage';
                      }
                      return null;
                    },
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
                    onPressed: () => _handleWarehouseUpdate(warehouse),
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

  @override
  void dispose() {
    _refreshController.close();
    _keyboardSubscription.cancel();
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          "Gestion des entrepôts",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1E49),
        tooltip: 'Add New warehouse',
        heroTag: 'warehouse_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 30,
                      right: 30,
                      top: 30,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 30,
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
                                child: Padding(
                                  padding: EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    'Ajouter un nouveau entrepôt',
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -1,
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _storageTypeController.clear();
                                  _adressController.clear();
                                  _nameController.clear();
                                  _errorMessage = null;
                                },
                                icon: const Icon(Icons.close_rounded, size: 30),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          buildTextField(
                            controller: _nameController,
                            label: 'Nom de l\'entrepôt',
                            icon: Icons.warehouse,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez definir un nom';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          buildTextField(
                            controller: _adressController,
                            label: 'Adresse',
                            icon: Icons.map_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez definir une adresse';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          buildTextField(
                            controller: _storageTypeController,
                            label: 'Type de stockage',
                            icon: Icons.type_specimen,
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez definir un type de stockage';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 40),
                          if (_errorMessage != null)
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          const SizedBox(height: 10),
                          confirmationButton(
                            isLoading: _isLoading,
                            onPressed: _submitForm,
                            label: "Enregistrer",
                            icon: Icons.check_circle_outline_outlined,
                            subLabel: "Enregistrement...",
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            buildTextField(
              controller: _searchController,
              label: 'Rechercher un entrepôt...',
              icon: Icons.search,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent &&
                      !_isLoading &&
                      _hasMoreData) {
                    loadWarehouses();
                  }
                  return false;
                },
                child: _buildWarehouseList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseList() {
    if (_allWarehouses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredWarehouse.isEmpty) {
      return const Center(child: Text("Aucun entrepôt trouvé"));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await loadWarehouses(reset: true);
      },
      displacement: 40,
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 32),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width >= 768 ? 2 : 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio:
              MediaQuery.of(context).size.width >= 768 ? 1.2 : 1.5,
        ),
        itemCount:
            _filteredWarehouse.length + (_hasMoreData && _isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _filteredWarehouse.length) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }
          final warehouse = _filteredWarehouse[index];
          final formattedDate = DateFormat('dd/MM/yyyy').format(
            warehouse.createdAt!,
          );

          return Slidable(
            key: ValueKey(warehouse.id),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => _updateWarehouse(warehouse),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                  label: 'Modifier',
                ),
                SlidableAction(
                  onPressed: (context) => _deleteWarehouse(warehouse),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Supprimer',
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WarehouseDetailPage(
                          warehouseId: warehouse.id,
                          name: warehouse.name,
                          adresse: warehouse.adresse,
                          storageType: warehouse.storageType,
                          onWarehouseUpdated: () {
                            loadWarehouses(reset: true);
                          },
                        ),
                      ),
                    );
                    if (result == true) {
                      setState(() {
                        loadWarehouses(reset: true);
                      });
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width >= 768 ? 16 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête avec nom et badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1E49).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.warehouse_rounded,
                                color: Color(0xFF1A1E49),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    warehouse.name ?? 'Entrepôt sans nom',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1E49),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1E49)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      warehouse.storageType ??
                                          'Type non défini',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF1A1E49),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF1A1E49),
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Informations détaillées
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Adresse',
                          value: warehouse.adresse ?? 'Adresse non définie',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Créé le',
                          value: formattedDate,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.inventory_2_outlined,
                          label: 'Colis en attente',
                          value:
                              '0', // TODO: Récupérer le nombre réel de colis pending
                          valueColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
