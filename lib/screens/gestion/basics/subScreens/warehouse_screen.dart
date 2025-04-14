import 'dart:async';

import 'package:bbd_limited/core/services/warehouse_services.dart';
import 'package:bbd_limited/models/warehouses.dart';
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

  void _showTopSnackBar(BuildContext context, String message) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(10),
              color: Colors.green,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text(message, style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
    );

    // Insert overlay
    Overlay.of(context).insert(overlayEntry);

    Future.delayed(Duration(seconds: 2), () {
      overlayEntry?.remove();
    });
  }

  @override
  void initState() {
    super.initState();
    loadWarehouses();
    _searchController.addListener(_onSearchChanged);

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

    // écouteur de scroll pour charger plus de données
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        loadWarehouses();
      }
    });
  }

  bool _hasMoreData = true;

  Future<void> loadWarehouses() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await warehousServices.findAllWarehouses(
        page: currentPage,
      );

      setState(() {
        if (_allWarehouses == null) {
          _allWarehouses = result;
        } else {
          _allWarehouses!.addAll(result);
        }
        _filteredWarehouse = _allWarehouses!;
      });

      // Gérer la fin de la liste
      if (result.length < 20) {
        _hasMoreData = false;
        print('Fin de la liste atteinte');
      } else {
        currentPage++;
      }
    } catch (e) {
      print('Erreur lors du chargement : $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    _keyboardSubscription.cancel();
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _create(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String success = await warehousServices.create(
        _nameController.text,
        _adressController.text,
        _storageTypeController.text,
      );

      if (success == "CREATED") {
        final result = await warehousServices.findAllWarehouses(
          page: currentPage,
        );
        setState(() {
          _allWarehouses = result;
          _filteredWarehouse = result;
        });

        _nameController.clear();
        _adressController.clear();
        _storageTypeController.clear();
      } else if (success == "NAME_EXIST") {
        setState(() {
          _errorMessage = "Cet entrepôt existe déjà.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la création';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        tooltip: 'Add New devise',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            isScrollControlled: true, // Ajouté pour gérer le clavier
            builder: (BuildContext context) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.of(
                        context,
                      ).viewInsets.bottom, // Gère le clavier
                  left: 30,
                  right: 30,
                  top: 30,
                ),
                child: SizedBox(
                  height: 500,
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
                          controller: _storageTypeController,
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
                          controller: _adressController,
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
                        // Afficher les erreur de connexion
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
                                  : () {
                                    if (_formKey.currentState!.validate()) {
                                      _create(context);
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
                ),
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
              decoration: InputDecoration(
                labelText: 'Rechercher un entrepôt...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount:
                    _filteredWarehouse.length + 1, // Ajouter 1 pour le loader
                itemBuilder: (context, index) {
                  if (index < _filteredWarehouse.length) {
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
                          spacing: 5,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildTag(warehouse.storageType ?? ''),
                                Icon(
                                  Icons.info,
                                  size: 30,
                                  color: Colors.grey[500],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              warehouse.name!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.map_rounded,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 5),
                                Text(warehouse.adresse!),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 5),
                                Text(formattedDate),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return _isLoading
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                        : SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@override
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
