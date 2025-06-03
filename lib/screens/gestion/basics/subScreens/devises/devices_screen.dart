import 'dart:async';

import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
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
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final KeyboardVisibilityController _keyboardVisibilityController;
  late final StreamSubscription<bool> _keyboardSubscription;
  final TextEditingController _searchController = TextEditingController();

  List<Devise>? _allDevises;
  List<Devise> _filteredDevises = [];
  Map<String, double> _currentRates = {};
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

  Future<void> _fetchExchangeRates() async {
    try {
      for (var devise in _allDevises ?? []) {
        final rate = await exchangeRateService.getExchangeRate(devise.code);
        setState(() {
          _currentRates[devise.code] = rate;
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération des taux: $e');
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

      // Récupérer les taux de change après avoir chargé les devises
      await _fetchExchangeRates();
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
                                color: Color(0xFF1A1E49),
                              ),
                              labelText: 'Taux de change',
                              hintText: 'Ex: 545.0',
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
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
            borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(16)), // Adjusted radius
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
            padding:
                const EdgeInsets.symmetric(vertical: 12), // Adjusted padding
            child: Row(
              children: [
                // Icon and Code
                Container(
                  padding: const EdgeInsets.all(10), // Increased padding
                  decoration: BoxDecoration(
                    color: isRateIncreasing
                        ? Colors.green[50]
                        : Colors.red[50], // Adjusted opacity
                    borderRadius: BorderRadius.circular(12), // Adjusted radius
                    // Removed border for a cleaner look
                  ),
                  child: const Icon(
                    rateIcon, // Using the trend icon here
                    color: rateColor, // Color based on trend
                    size: 24, // Increased size
                  ),
                ),
                const SizedBox(width: 16), // Increased spacing
                // Name and Placeholder Date (or other info)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        devise.name, // Displaying currency name
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(
                          height: 4), // Spacing between name and date
                      Text(
                        devise
                            .code, // Displaying currency code as secondary info
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors
                              .grey[600], // Muted color for secondary info
                        ),
                      ),
                    ],
                  ),
                ),
                // Rate
                Text(
                  currentRate.toStringAsFixed(2), // Displaying the rate
                  style: const TextStyle(
                    color: rateColor, // Color based on trend
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  devise.code, // Displaying the target currency code
                  style: TextStyle(
                    color: Colors.grey[600], // Muted color for currency code
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
