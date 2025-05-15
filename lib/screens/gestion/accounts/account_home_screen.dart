import 'dart:async';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/create_paiement.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/edit_paiement_modal.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/paiement_list.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/paiment_detail_modal.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccountHomeScreen extends StatefulWidget {
  @override
  State<AccountHomeScreen> createState() => _AccountHomeScreenState();
}

class _AccountHomeScreenState extends State<AccountHomeScreen> {
  final TextEditingController searchController = TextEditingController();
  final VersementServices _versementServices = VersementServices();
  final AuthService _authService = AuthService();

  List<Versement> _allPaiements = [];
  List<Versement> _filteredPaiements = [];
  String? _currentFilter;

  bool _isLoading = false;
  bool _hasMoreData = true;
  int currentPage = 0;

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');

  @override
  void initState() {
    super.initState();
    fetchPaiements();
    _refreshController.stream.listen((_) {
      fetchPaiements(reset: true);
    });
  }

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  Future<void> fetchPaiements({bool reset = false}) async {
    if (_isLoading || (!reset && !_hasMoreData)) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        currentPage = 0;
        _hasMoreData = true;
        _allPaiements = [];
      }
    });
    try {
      final paiement = await _versementServices.getAll(page: currentPage);

      setState(() {
        _allPaiements.addAll(paiement);
        _filteredPaiements = List.from(_allPaiements);

        if (paiement.isEmpty || paiement.length < 30) {
          _hasMoreData = false;
        } else {
          currentPage++;
        }
      });
    } catch (e) {
      showErrorTopSnackBar(context, "Erreur de récupération des paiements.");
      print("Erreur de récupération des paiements : $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void filterPackages(String query) {
    setState(() {
      _filteredPaiements =
          _allPaiements.where((pmt) {
            final searchPackage = pmt.reference!.toLowerCase().contains(
              query.toLowerCase(),
            );

            bool allStatus = true;
            if (_currentFilter == 'client') {
              allStatus = pmt.partnerAccountType?.toLowerCase() == 'client';
            } else if (_currentFilter == 'supplier') {
              allStatus =
                  pmt.partnerAccountType?.toLowerCase() == 'fournisseur';
            }

            return searchPackage && allStatus;
          }).toList();
    });
  }

  void handleStatusFilter(String value) {
    setState(() {
      _currentFilter = value;
    });

    filterPackages(searchController.text);
  }

  Future<void> _openNewPaiementBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return CreatePaiementModal();
      },
    );

    if (result == true) {
      fetchPaiements(reset: true);
    }
  }

  void _showEditPaiementModal(BuildContext context, Versement versement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return EditPaiementModal(
          versement: versement,
          onPaiementUpdated: () => fetchPaiements(reset: true),
        );
      },
    );
  }

  Future<void> _delete(Versement versement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirmer la suppression"),
            content: Text(
              "Voulez-vous vraiment supprimer le paiement ${versement.reference}?",
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

    if (confirmed != true) return;

    try {
      final user = await _authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context, "Erreur: Utilisateur non connecté");
        return;
      }

      if (versement.id == null) {
        showErrorTopSnackBar(context, "Erreur: Le paiement n'existe pas");
        return;
      }

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _versementServices.delete(versement.id!, user.id);

      Navigator.of(context).pop();

      if (result == "ACHATS_NOT_DELETED") {
        showErrorTopSnackBar(
          context,
          "Impossible de supprimer le paiement, il y a des achats associés à ce paiement",
        );
      } else if (result == "DELETED") {
        setState(() {
          _allPaiements.removeWhere((d) => d.id == versement.id);
          _filteredPaiements.removeWhere((d) => d.id == versement.id);
        });

        showSuccessTopSnackBar(context, "Paiement supprimé avec succès");
      } else {
        showErrorTopSnackBar(context, "Erreur inconnue lors de la suppression");
      }
    } catch (e) {
      // Fermer l'indicateur de chargement en cas d'erreur
      Navigator.of(context).pop();
      showErrorTopSnackBar(
        context,
        "Erreur lors de la suppression: ${e.toString()}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1E49),
        onPressed: () {
          _openNewPaiementBottomSheet(context);
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text(
              "Gestion des paiements",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 10),
            // Reporting Cards
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.blue[50],
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: _StatItem(
                          title: 'Total des versements',
                          value: _allPaiements.length.toString(),
                          valueStyle: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1E49),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.amber[50],
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: _StatItem(
                          title: 'Montant total',
                          value: currencyFormat.format(
                            _allPaiements.fold<double>(
                              0,
                              (sum, item) =>
                                  sum +
                                  (item.status != Status.DELETE
                                      ? (item.montantRestant ?? 0)
                                      : 0),
                            ),
                          ),
                          valueStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1E49),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search and Filter Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    onChanged: filterPackages,
                    controller: searchController,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Rechercher un paiement...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FiltreDropdown(onSelected: handleStatusFilter),
              ],
            ),
            const SizedBox(height: 12),
            // List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "La liste des paiements${_currentFilter == null
                      ? ''
                      : _currentFilter == 'client'
                      ? ' clients'
                      : _currentFilter == 'supplier'
                      ? ' fournisseurs'
                      : ''}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentFilter != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentFilter = null;
                        _filteredPaiements = _allPaiements;
                        if (searchController.text.isNotEmpty) {
                          filterPackages(searchController.text);
                        }
                      });
                    },
                    child: const Text("Voir tout"),
                  ),
              ],
            ),
            // List of Payments
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1A1E49),
                          strokeWidth: 3,
                        ),
                      )
                      : NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          if (scrollInfo.metrics.pixels ==
                                  scrollInfo.metrics.maxScrollExtent &&
                              !_isLoading &&
                              _hasMoreData) {
                            fetchPaiements();
                          }
                          return false;
                        },
                        child:
                            _filteredPaiements.isEmpty
                                ? Center(child: Text("Aucun paiement trouvé."))
                                : RefreshIndicator(
                                  onRefresh: () async {
                                    await fetchPaiements(reset: true);
                                  },
                                  displacement: 20,
                                  color: Theme.of(context).primaryColor,
                                  backgroundColor: Colors.white,
                                  child: ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount:
                                        _filteredPaiements.length +
                                        (_hasMoreData && _isLoading ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index >= _filteredPaiements.length) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      final paiement =
                                          _filteredPaiements[index];
                                      return PaiementListItem(
                                        versement: paiement,
                                        onTap:
                                            () =>
                                                showPaiementDetailsBottomSheet(
                                                  context,
                                                  paiement,
                                                ),
                                        onEdit:
                                            () => _showEditPaiementModal(
                                              context,
                                              paiement,
                                            ),
                                        onDelete: () => _delete(paiement),
                                      );
                                    },
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

class FiltreDropdown extends StatelessWidget {
  final Function(String) onSelected;

  const FiltreDropdown({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF7F78AF),
        borderRadius: BorderRadius.circular(8),
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
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        onSelected: onSelected,
        itemBuilder:
            (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'client',
                child: Text('Clients'),
              ),
              const PopupMenuItem<String>(
                value: 'supplier',
                child: Text('Fournisseurs'),
              ),
            ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final TextStyle valueStyle;

  const _StatItem({
    required this.title,
    required this.value,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(value, style: valueStyle),
      ],
    );
  }
}
