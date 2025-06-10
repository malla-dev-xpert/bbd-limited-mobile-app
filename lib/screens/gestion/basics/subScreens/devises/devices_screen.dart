import 'dart:async';

import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/devises_service.dart';
import 'package:bbd_limited/core/services/exchange_rate_service.dart';
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
  final ExchangeRateService exchangeRateService = ExchangeRateService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final KeyboardVisibilityController _keyboardVisibilityController;
  late final StreamSubscription<bool> _keyboardSubscription;
  final TextEditingController _searchController = TextEditingController();
  final AuthService authService = AuthService();

  // Stream controllers for error handling
  final StreamController<String> _errorStreamController =
      StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorStreamController.stream;

  List<Devise>? _allDevises;
  List<Devise> _filteredDevises = [];
  Map<String, double> _currentRates = {};
  int currentPage = 0;
  bool _isLoading = false;
  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  // Constants for validation
  static const int _maxNameLength = 50;
  static const int _maxCodeLength = 3;
  static const String _currencyCodePattern = r'^[A-Z]{3}$';

  @override
  void initState() {
    super.initState();
    loadDevises();
    _searchController.addListener(_onSearchChanged);
    _refreshController.stream.listen((_) {
      loadDevises(reset: true);
    });

    _keyboardVisibilityController = KeyboardVisibilityController();
    _keyboardSubscription =
        _keyboardVisibilityController.onChange.listen((visible) {
      if (!visible) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    _errorStreamController.add(message);
  }

  Future<void> _fetchExchangeRates() async {
    try {
      for (var devise in _allDevises ?? []) {
        final rate = await exchangeRateService.getExchangeRate(devise.code);
        setState(() {
          _currentRates[devise.code] = rate;
        });
      }
    } catch (e) {
      _showError('Erreur lors de la récupération des taux: $e');
    }
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

      await _fetchExchangeRates();
    } catch (e) {
      _showError("Erreur de chargement: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom est requis';
    }
    if (value.length > _maxNameLength) {
      return 'Le nom ne doit pas dépasser $_maxNameLength caractères';
    }
    return null;
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le code est requis';
    }
    if (!RegExp(_currencyCodePattern).hasMatch(value)) {
      return 'Le code doit être composé de 3 lettres majuscules';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await authService.getUserInfo();
      if (user == null) {
        _showError('Session utilisateur invalide');
        return;
      }

      final success = await deviseServices.create(
        _nameController.text.trim(),
        _codeController.text.trim().toUpperCase(),
        user.id,
      );

      switch (success) {
        case "NAME_EXIST":
          _showError("Le nom '${_nameController.text}' existe déjà");
          break;
        case "CODE_EXIST":
          _showError("Le code '${_codeController.text}' existe déjà");
          break;
        case "CREATED":
          _nameController.clear();
          _codeController.clear();
          Navigator.pop(context);
          showSuccessTopSnackBar(context, 'Devise créée avec succès!');
          _refreshController.add(null);
          break;
        default:
          _showError('Une erreur inattendue est survenue');
      }
    } catch (e) {
      _showError('Erreur serveur: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    final StreamController<String> _editErrorStreamController =
        StreamController<String>.broadcast();

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
                    onPressed: () {
                      _editErrorStreamController.close();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Nom de la devise",
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: "Code de la devise",
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: _validateCode,
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<String>(
                        stream: _editErrorStreamController.stream,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                snapshot.data!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _editErrorStreamController.close();
                    Navigator.pop(context);
                  },
                  child: const Text('Annuler'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    try {
                      setState(() => _isLoading = true);

                      final deviseDto = devise.copyWith(
                        name: nameController.text.trim(),
                        code: codeController.text.trim().toUpperCase(),
                      );

                      final updatedDevise = await deviseServices.updateDevise(
                        devise.id!,
                        deviseDto,
                      );

                      if (updatedDevise) {
                        _editErrorStreamController.close();
                        Navigator.pop(context, true);
                        showSuccessTopSnackBar(
                          context,
                          "Devise modifiée avec succès",
                        );
                        _refreshController.add(null);
                      } else {
                        _editErrorStreamController
                            .add("Erreur lors de la modification");
                      }
                    } catch (e) {
                      _editErrorStreamController.add("Erreur: ${e.toString()}");
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
                      : const Text(
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

  Future<void> _deleteDevise(Devise devise) async {
    try {
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
        await deviseServices.deleteDevise(devise.id!);
        setState(() {
          _allDevises!.removeWhere((d) => d.id == devise.id);
          _filteredDevises = List.from(_allDevises!);
        });
        showSuccessTopSnackBar(context, "Devise supprimée avec succès");
      }
    } catch (e) {
      _showError("Erreur lors de la suppression: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    // final bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Gestion des devises",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1E49),
        tooltip: 'Add New devise',
        heroTag: 'devices_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
                  return Container(
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
                                    'Ajouter une nouvelle devise',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                      color: Color(0xFF1A1E49),
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
                                  _nameController.clear();
                                },
                                icon: const Icon(Icons.close_rounded, size: 30),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _nameController,
                            autocorrect: false,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.attach_money,
                                color: Color(0xFF1A1E49),
                              ),
                              labelText: 'Nom de la devise',
                              hintText: 'Ex: Dollar US',
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1A1E49),
                                  width: 2,
                                ),
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                            validator: _validateName,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _codeController,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.abc,
                                color: Color(0xFF1A1E49),
                              ),
                              labelText: 'Code',
                              hintText: 'Ex: USD, EUR, GBP',
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1A1E49),
                                  width: 2,
                                ),
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                            validator: _validateCode,
                          ),
                          const SizedBox(height: 40),
                          StreamBuilder<String>(
                            stream: errorStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data!.isNotEmpty) {
                                return Text(
                                  snapshot.data!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: 16),
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Rechercher une devise...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF1A1E49)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredDevises.isEmpty) {
      return const Center(child: Text("Aucune devise trouvée"));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await loadDevises(reset: true);
      },
      displacement: 40,
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount:
            _filteredDevises.length + (_hasMoreData && _isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _filteredDevises.length) {
            return const Center(
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
    final currentRate = _currentRates[devise.code] ?? 0.0;
    const bool isRateIncreasing = true;
    const Color rateColor = isRateIncreasing ? Colors.green : Colors.red;
    const IconData rateIcon =
        isRateIncreasing ? Icons.arrow_upward : Icons.arrow_downward;

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
            onPressed: (_) => _deleteDevise(devise),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Supprimer',
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(16)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Ajouter une action au clic si nécessaire
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isRateIncreasing ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    rateIcon,
                    color: rateColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        devise.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        devise.code,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currentRate.toStringAsFixed(2),
                  style: const TextStyle(
                    color: rateColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  devise.code,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
