import 'dart:async';

import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/services/devises_service.dart';
import 'package:bbd_limited/models/devises.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
  String _errorMessage = '';

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
    loadDevises();
    _searchController.addListener(_onSearchChanged);
    _refreshController.stream.listen((_) {
      loadDevises(reset: true);
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
      _filteredDevises = _allDevises!.where((devise) {
        final code = devise.code.toLowerCase();
        final name = devise.name.toLowerCase();
        return code.contains(query) || name.contains(query);
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final success = await deviseServices.create(
        _nameController.text,
        _codeController.text,
      );

      if (success == "NAME_EXIST") {
        setState(() {
          _errorMessage =
              "Le nom '${_nameController.text}' existe déjà. Veuillez en choisir un autre.";
          _isLoading = false;
        });
        return;
      }

      if (success == "CODE_EXIST") {
        setState(() {
          _errorMessage =
              "Le code '${_codeController.text}' existe déjà. Veuillez en choisir un autre.";
          _isLoading = false;
        });
        return;
      }

      if (success == "CREATED") {
        _nameController.clear();
        _codeController.clear();
        _rateController.clear();
        Navigator.pop(context);
        showSuccessTopSnackBar(context, 'Devise créée avec succès!');
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

  Future<bool?> _showEditDeviseModal(
    BuildContext context,
    Devise devise,
  ) async {
    final TextEditingController nameController = TextEditingController(
      text: devise.name,
    );
    final TextEditingController codeController = TextEditingController(
      text: devise.code,
    );
    bool _isLoading = false;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 50,
                children: [
                  const Text(
                    'Modifier un devise',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildTextField(
                      controller: nameController,
                      label: "Nom de la devise",
                      icon: Icons.description,
                    ),
                    const SizedBox(height: 16),
                    buildTextField(
                      controller: codeController,
                      label: "Code de la devise",
                      icon: Icons.numbers,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    try {
                      setState(() => _isLoading = true);

                      final deviseDto = devise.copyWith(
                        name: nameController.text,
                        code: codeController.text,
                      );

                      final updatedDevise = await deviseServices.updateDevise(
                        devise.id!,
                        deviseDto,
                      );

                      if (updatedDevise) {
                        setState(() {
                          _isLoading = false;
                          loadDevises(reset: true);
                        });

                        Navigator.pop(context, true);

                        showSuccessTopSnackBar(
                          context,
                          "Devise modifiée avec succès",
                        );
                      }
                    } catch (e) {
                      setState(() => _isLoading = false);
                      showErrorTopSnackBar(context, "Erreur: ${e.toString()}");
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  icon: const Icon(
                    Icons.check_circle_outline_outlined,
                    color: Colors.green,
                  ),
                  label: _isLoading
                      ? const Text('Modification...')
                      : Text(
                          'Modifier',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
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
        heroTag: 'devices_fab',
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
                                  setModalState(() => _errorMessage = '');
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
                          if (_errorMessage != '')
                            Text(
                              _errorMessage,
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

  // la liste des devises
  Widget _buildDeviseList() {
    if (_allDevises == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_filteredDevises.isEmpty) {
      return Center(child: Text("Aucune devise trouvée"));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await loadDevises(reset: true);
      },
      displacement: 40,
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        itemCount:
            _filteredDevises.length + (_hasMoreData && _isLoading ? 1 : 0),
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
      ),
    );
  }

  // Les donnees de la liste
  Widget _buildDeviseItem(Devise devise) {
    return Slidable(
      key: Key(devise.id.toString()),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) async {
              final result = await _showEditDeviseModal(context, devise);
              if (result == true) {
                setState(() {
                  loadDevises(reset: true);
                });
              }
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Modifier',
          ),
          SlidableAction(
            onPressed: (context) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirmer la suppression"),
                  content: Text(
                    "Voulez-vous vraiment supprimer la devise ${devise.name} (${devise.code})?",
                  ),
                  backgroundColor: Colors.white,
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
                  await deviseServices.deleteDevise(devise.id!);
                  setState(() {
                    _allDevises!.removeWhere((d) => d.id == devise.id);
                    _filteredDevises = List.from(_allDevises!);
                  });
                  showSuccessTopSnackBar(context, "Devise supprimée");
                } catch (e) {
                  showErrorTopSnackBar(
                    context,
                    "Erreur lors de la suppression",
                  );
                }
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Supprimer',
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          devise.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          devise.code,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF7F78AF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            'XOF 0.00',
            style: const TextStyle(
              color: Color(0xFF7F78AF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
