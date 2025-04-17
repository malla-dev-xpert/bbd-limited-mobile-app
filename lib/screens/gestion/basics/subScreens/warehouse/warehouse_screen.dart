import 'dart:async';

import 'package:bbd_limited/core/services/warehouse_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/models/warehouses.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/detail_warehouse_screen.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:intl/intl.dart';

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

  List<Warehouses>? _allWarehouses;
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
        _allWarehouses = null;
      }
    });

    try {
      final result = await warehousServices.findAllWarehouses(
        page: currentPage,
      );

      setState(() {
        _allWarehouses ??= [];
        if (reset) _allWarehouses!.clear();
        _allWarehouses!.addAll(result);
        _filteredWarehouse = List.from(_allWarehouses!);

        if (result.isEmpty || result.length < 10) {
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

    if (_allWarehouses == null) return; // ✅ sécurité ajoutée

    setState(() {
      _filteredWarehouse =
          _allWarehouses!.where((warehouse) {
            final adresse = warehouse.adresse?.toLowerCase() ?? '';
            final name = warehouse.name?.toLowerCase() ?? '';
            final storageType = warehouse.storageType?.toLowerCase() ?? '';

            return name.contains(query) ||
                adresse.contains(query) ||
                storageType.contains(query);
          }).toList();
    });
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

  Future<void> _deleteWarehouse(BuildContext context, int id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await authService.getUserInfo();
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        showErrorTopSnackBar(context, "Erreur: Utilisateur non connecté");
        return;
      }

      await warehousServices.deleteWarehouse(id, user.id);
      setState(() {
        _allWarehouses!.removeWhere((d) => d.id == id);
        _filteredWarehouse = List.from(_allWarehouses!);
        _isLoading = false;
      });
      Navigator.of(context).pop();
      showSuccessTopSnackBar(context, "Entrepot supprimée");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showErrorTopSnackBar(context, "Erreur lors de la suppression");
    }
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
        iconTheme: IconThemeData(color: Colors.white),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1E49),
        tooltip: 'Add New warehouse',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
                  return Container(
                    padding: EdgeInsets.all(30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: const Text(
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
                          TextFormField(
                            controller: _nameController,
                            autocorrect: false,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.warehouse,
                                color: Colors.black,
                              ),
                              labelText: 'Nom de l\'entrepôt',
                              hintText: 'Ex: Entrepôt de la maison',
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez definir un nom';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _adressController,
                            autocorrect: false,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.map_outlined,
                                color: Colors.black,
                              ),
                              labelText: 'Adresse',
                              hintText: 'Ex: Faladie SEMA',
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez definir une adresse';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _storageTypeController,
                            autocorrect: false,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.type_specimen,
                                color: Colors.black,
                              ),
                              labelText: 'Type de stockage',
                              hintText: 'Ex: Stockage de PC',
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
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
                          ElevatedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () async {
                                      if (!_formKey.currentState!.validate()) {
                                        return;
                                      }

                                      setModalState(() {
                                        _isLoading = true;
                                        _errorMessage = null;
                                      });

                                      final user =
                                          await authService.getUserInfo();
                                      if (user == null) {
                                        setModalState(() {
                                          _isLoading = false;
                                          _errorMessage =
                                              "Erreur: Utilisateur non connecté";
                                        });
                                        return;
                                      }

                                      try {
                                        final success = await warehousServices
                                            .create(
                                              _nameController.text,
                                              _adressController.text,
                                              _storageTypeController.text,
                                              user.id,
                                            );

                                        if (success == "NAME_EXIST") {
                                          setModalState(() {
                                            _errorMessage =
                                                "Le nom '${_nameController.text}' existe déjà. Veuillez en choisir un autre.";
                                            _isLoading = false;
                                          });
                                          return;
                                        }

                                        if (success == "ADRESS_EXIST") {
                                          setModalState(() {
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

                                          setModalState(() {
                                            _isLoading = false;
                                          });

                                          Navigator.of(context).pop();

                                          showSuccessTopSnackBar(
                                            context,
                                            'Entrepôt créé avec succès!',
                                          );
                                          _refreshController.add(null);
                                        }
                                      } catch (e) {
                                        setModalState(() {
                                          _isLoading = false;
                                          _errorMessage =
                                              'Erreur liée au serveur, veuillez réessayer plus tard.';
                                        });
                                      } finally {
                                        setModalState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: const Color(0xFF1A1E49),
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      'Enregistrer',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
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
            TextField(
              controller: _searchController,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Rechercher un entrepôt...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
    if (_allWarehouses == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_filteredWarehouse.isEmpty) {
      return Center(child: Text("Aucun entrepôt trouvé"));
    }

    return ListView.builder(
      physics: AlwaysScrollableScrollPhysics(),
      itemCount:
          _filteredWarehouse.length + (_hasMoreData && _isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _filteredWarehouse.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final warehouse = _filteredWarehouse[index];
        final formattedDate = DateFormat.yMMMMEEEEd().format(
          warehouse.createdAt,
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 228, 229, 247),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTag(warehouse.storageType ?? ''),
                    // warehous detail
                    IconButton(
                      icon: Icon(Icons.info, size: 30, color: Colors.grey[500]),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => WarehouseDetailPage(
                                  warehouseId: warehouse.id,
                                  name: warehouse.name!,
                                  storageType: warehouse.storageType!,
                                  adresse: warehouse.adresse!,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  warehouse.name!,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(Icons.map_rounded, size: 18, color: Colors.grey),
                    SizedBox(width: 5),
                    Text(warehouse.adresse!),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                    SizedBox(width: 5),
                    Text(formattedDate),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF7F78AF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
