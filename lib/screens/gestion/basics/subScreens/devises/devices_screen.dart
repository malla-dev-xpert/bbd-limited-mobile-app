import 'dart:async';

import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/devises_service.dart';
import 'package:bbd_limited/core/services/exchange_rate_service.dart';
import 'package:bbd_limited/models/devises.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbd_limited/providers/devise_provider.dart';
import 'package:bbd_limited/widgets/devise/devise_form.dart';
import 'package:bbd_limited/widgets/devise/devise_list_item.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DeviseState();
}

class _DeviseState extends ConsumerState<DevicesScreen> {
  final DeviseServices deviseServices = DeviseServices();
  final ExchangeRateService exchangeRateService = ExchangeRateService();
  final ScrollController _scrollController = ScrollController();
  late final KeyboardVisibilityController _keyboardVisibilityController;
  late final StreamSubscription<bool> _keyboardSubscription;
  final TextEditingController _searchController = TextEditingController();
  final AuthService authService = AuthService();
  bool _isLoading = false;

  // Stream controllers for error handling
  final StreamController<String> _errorStreamController =
      StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorStreamController.stream;

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  // Constants for validation
  static const int _maxNameLength = 50;
  static const String _currencyCodePattern = r'^[A-Z]{3}$';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _refreshController.stream.listen((_) {
      ref.read(deviseListProvider.notifier).loadDevises(reset: true);
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

    // Schedule the initial load after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialLoad();
    });
  }

  void _initialLoad() {
    ref.read(deviseListProvider.notifier).loadDevises();
  }

  void _showError(String message) {
    _errorStreamController.add(message);
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

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    ref.read(deviseListProvider.notifier).filterDevises(query);
  }

  Future<void> _showAddDeviseModal() async {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      'Ajouter une nouvelle devise',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1E49),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DeviseForm(
                isLoading: _isLoading,
                isEditing: false,
                onSubmit: (name, code, rate) async {
                  setState(() => _isLoading = true);
                  try {
                    final user = await authService.getUserInfo();
                    if (user == null) {
                      showErrorTopSnackBar(
                          context, 'Session utilisateur invalide');
                      return;
                    }

                    final success = await ref
                        .read(deviseListProvider.notifier)
                        .createDevise(
                          name: name,
                          code: code,
                          rate: rate,
                          userId: user.id,
                        );

                    if (success) {
                      Navigator.pop(context);
                      showSuccessTopSnackBar(
                          context, 'Devise créée avec succès!');
                    } else {
                      showErrorTopSnackBar(
                          context, 'Erreur lors de la création de la devise');
                    }
                  } catch (e) {
                    showErrorTopSnackBar(
                        context, 'Erreur serveur: ${e.toString()}');
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditDeviseModal(Devise devise) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            child: DeviseForm(
              devise: devise,
              isLoading: _isLoading,
              isEditing: true,
              onSubmit: (name, code, rate) async {
                setState(() => _isLoading = true);
                try {
                  final updatedDevise = devise.copyWith(
                    name: name,
                    code: code,
                    rate: rate,
                  );

                  final success =
                      await ref.read(deviseListProvider.notifier).updateDevise(
                            devise.id!,
                            updatedDevise,
                          );

                  if (success) {
                    Navigator.pop(context);
                    showSuccessTopSnackBar(
                        context, 'Devise modifiée avec succès');
                  } else {
                    showErrorTopSnackBar(
                        context, 'Erreur lors de la modification');
                  }
                } catch (e) {
                  showErrorTopSnackBar(context, 'Erreur: ${e.toString()}');
                } finally {
                  setState(() => _isLoading = false);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteDevise(Devise devise) async {
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
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await ref
            .read(deviseListProvider.notifier)
            .deleteDevise(devise.id!);
        if (success) {
          showSuccessTopSnackBar(context, "Devise supprimée avec succès");
        } else {
          showErrorTopSnackBar(context, "Erreur lors de la suppression");
        }
      } catch (e) {
        showErrorTopSnackBar(context, "Erreur: ${e.toString()}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviseState = ref.watch(deviseListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
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
        onPressed: _showAddDeviseModal,
        child: const Icon(Icons.add, color: Colors.white),
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
                decoration: InputDecoration(
                  labelText: 'Rechercher une devise...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF1A1E49)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: deviseState.when(
                data: (devises) {
                  if (devises.isEmpty) {
                    return const Center(
                      child: Text("Aucune devise trouvée"),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(deviseListProvider.notifier)
                        .loadDevises(reset: true),
                    child: ListView.builder(
                      itemCount: devises.length,
                      itemBuilder: (context, index) {
                        final devise = devises[index];
                        return DeviseListItem(
                          devise: devise,
                          onEdit: () => _showEditDeviseModal(devise),
                          onDelete: () => _deleteDevise(devise),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    "Erreur: ${error.toString()}",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
