import 'dart:async';

import 'package:bbd_limited/core/services/devises_service.dart';
import 'package:bbd_limited/models/devises.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DeviseState();
}

class _DeviseState extends State<DevicesScreen> {
  final _formKey = GlobalKey<FormState>();
  final DeviseServices deviseServices = DeviseServices();
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  late final KeyboardVisibilityController _keyboardVisibilityController;
  late final StreamSubscription<bool> _keyboardSubscription;

  final TextEditingController _searchController = TextEditingController();

  List<Devise>? _allDevises; // liste complète récupérée une seule fois
  List<Devise> _filteredDevises = [];
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
    loadDevises();
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
  }

  Future<void> loadDevises() async {
    try {
      final result = await deviseServices.findAllDevises(page: currentPage);
      setState(() {
        _allDevises = result;
        _filteredDevises = result; // initialiser avec la liste complète
      });
    } catch (e) {
      print('Erreur lors du chargement : $e');
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredDevises =
          _allDevises!.where((devise) {
            final code = devise.code.toLowerCase();
            final name = devise.name.toLowerCase();
            return code.contains(query) || name.contains(query);
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
      String success = await deviseServices.create(
        _nameController.text,
        _codeController.text,
        double.tryParse(_rateController.text) ?? 0.0,
      );

      if (success == "CREATED") {
        setState(() {
          deviseServices.findAllDevises(page: currentPage);
        });

        // Fermer la BottomSheet après le traitement
        Navigator.pop(context);

        // Effacer les champs
        _nameController.clear();
        _codeController.clear();
        _rateController.clear();

        // Afficher une notification
        _showTopSnackBar(context, 'Devise créée avec succès!');
      } else if (success == "CODE_EXIST") {
        setState(() {
          _errorMessage = "Le code existe déjà. Veuillez en choisir un autre.";
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
    final bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          "Gestion des devises",
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
                                  'Ajouter une nouvelle devise',
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
                                _codeController.clear();
                                _rateController.clear();
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
                              Icons.attach_money,
                              color: Colors.black,
                            ),
                            labelText: 'Nom de la devise',
                            hintText: 'Ex: Dollar US',
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
                          controller: _codeController,
                          autocorrect: false,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.abc,
                              color: Colors.black,
                            ),
                            labelText: 'Code',
                            hintText: 'Ex: USD, EUR, GBP',
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez definir le code';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _rateController,
                          autocorrect: false,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.percent,
                              color: Colors.black,
                            ),
                            labelText: 'Taux de change',
                            hintText: 'Ex: 545.0',
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
                              return 'Veuillez definir le taux de change actuel.';
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
      body: SingleChildScrollView(
        controller: _scrollController,
        physics:
            keyboardVisible
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Rechercher une devise...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),

                  const SizedBox(height: 40),

                  FutureBuilder<List<Devise>>(
                    future:
                        _allDevises != null ? Future.value(_allDevises!) : null,
                    builder: (context, deviseData) {
                      if (deviseData.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (deviseData.hasError) {
                        return Center(
                          child: Text(
                            "Erreur: ${deviseData.error}",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      } else if (!deviseData.hasData ||
                          deviseData.data!.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.hourglass_empty,
                                  size: 50,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Aucune devise trouvée.",
                                style: TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        );
                      } else {
                        List<Devise> list = _filteredDevises;
                        return Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child:
                                  _isLoading
                                      ? Center(
                                        child: CircularProgressIndicator(),
                                      )
                                      : _filteredDevises.isEmpty
                                      ? Center(
                                        child: Text("Aucune devise trouvée"),
                                      )
                                      : ListView.builder(
                                        itemCount: _filteredDevises.length,
                                        itemBuilder: (context, index) {
                                          final devise =
                                              _filteredDevises[index];
                                          return Dismissible(
                                            key: Key(devise.id.toString()),
                                            direction:
                                                DismissDirection.startToEnd,
                                            background: Container(
                                              color: Colors.red,
                                              alignment: Alignment.centerLeft,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                  ),
                                              child: const Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                              ),
                                            ),
                                            onDismissed: (direction) async {
                                              setState(() {
                                                list.removeAt(index);
                                              });

                                              try {
                                                await deviseServices
                                                    .deleteDevise(devise.id);

                                                final updatedList =
                                                    await deviseServices
                                                        .findAllDevises(
                                                          page: currentPage,
                                                        );
                                                setState(() {
                                                  list = updatedList;
                                                });
                                              } catch (e) {
                                                setState(() {
                                                  list.insert(index, devise);
                                                });
                                                _showTopSnackBar(
                                                  context,
                                                  "Erreur lors de la suppression.",
                                                );
                                              }
                                            },
                                            child: ListTile(
                                              title: Text(devise.name),
                                              subtitle: Text(devise.code),
                                              trailing: Text(
                                                devise.rate.toString(),
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF7F78AF,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
