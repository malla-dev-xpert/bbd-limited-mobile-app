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

  bool _hasMoreData = true;

  Future<void> loadDevises({bool reset = false}) async {
    if (_isLoading || (!reset && !_hasMoreData)) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        currentPage = 0;
        _hasMoreData = true;
        _allDevises = null;
      }
    });

    try {
      final result = await deviseServices.findAllDevises(page: currentPage);

      setState(() {
        _allDevises ??= [];
        if (reset) _allDevises!.clear();
        _allDevises!.addAll(result);
        _filteredDevises = List.from(_allDevises!);

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
        // Clear fields first
        _nameController.clear();
        _codeController.clear();
        _rateController.clear();

        // Close the bottom sheet before any other operations
        Navigator.of(context).pop();

        // Show success message
        _showTopSnackBar(context, 'Devise créée avec succès!');

        // Refresh the list
        await loadDevises(reset: true);
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
            isScrollControlled: true,
            builder: (BuildContext context) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
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
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Rechercher une devise...',
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
                    loadDevises();
                  }
                  return false;
                },
                child: _buildDeviseList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviseList() {
    if (_allDevises == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_filteredDevises.isEmpty) {
      return Center(child: Text("Aucune devise trouvée"));
    }

    return ListView.builder(
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: _filteredDevises.length + (_hasMoreData && _isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _filteredDevises.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final devise = _filteredDevises[index];
        return _buildDeviseItem(devise);
      },
    );
  }

  Widget _buildDeviseItem(Devise devise) {
    return Dismissible(
      key: Key(devise.id.toString()),
      direction: DismissDirection.startToEnd,
      background: Container(
        padding: const EdgeInsets.only(left: 16),
        color: Colors.red,
        alignment: Alignment.centerLeft,
        child: Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        try {
          await deviseServices.deleteDevise(devise.id);
          setState(() {
            _allDevises!.removeWhere((d) => d.id == devise.id);
            _filteredDevises = List.from(_allDevises!);
          });
          _showTopSnackBar(context, "Devise supprimée");
          return true;
        } catch (e) {
          _showTopSnackBar(context, "Erreur lors de la suppression");
          return false;
        }
      },
      child: ListTile(
        title: Text(devise.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(devise.code),
        trailing: Text(
          devise.rate.toString(),
          style: TextStyle(color: const Color(0xFF7F78AF)),
        ),
      ),
    );
  }
}
