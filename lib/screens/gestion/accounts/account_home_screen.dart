import 'dart:async';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/paiement_list.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/paiment_detail_modal.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/create_package_form.dart';
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

  Future<void> _openCreatePackageBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return CreatePackageForm();
      },
    );

    if (result == true) {
      fetchPaiements(reset: true);
    }
  }

  Future<void> _deletePackage(Versement item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirmer la suppression"),
            content: Text(
              "Voulez-vous vraiment supprimer le colis ${item.reference}?",
            ),
            backgroundColor: Colors.white,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Annuler"),
              ),
              _isLoading
                  ? CircularProgressIndicator()
                  : TextButton.icon(
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

      setState(() {
        _allPaiements.removeWhere((d) => d.id == item.id);
        _filteredPaiements = List.from(_allPaiements);
      });

      showSuccessTopSnackBar(context, "Colis supprimé avec succès");
    } catch (e) {
      showErrorTopSnackBar(context, "Erreur lors de la suppression");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
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
            Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total des versements',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_allPaiements.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1E49),
                            ),
                          ),
                        ],
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
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Montant total',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(
                              _allPaiements.fold<double>(
                                0,
                                (sum, item) => sum + (item.montantRestant ?? 0),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1E49),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Barre de recherche
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
            // Liste des colis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "La liste des paimemts${_currentFilter == null
                      ? ''
                      : _currentFilter == 'client'
                      ? ' clients'
                      : _currentFilter == 'delivered'
                      ? 'supplier'
                      : ' fournisseurs'}",
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
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1A1E49),
                    strokeWidth: 3,
                  ),
                )
                : Expanded(
                  child: NotificationListener<ScrollNotification>(
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
                            ? Center(child: Text("Aucun paiment trouvé."))
                            : RefreshIndicator(
                              onRefresh: () async {
                                await fetchPaiements(reset: true);
                              },
                              displacement: 20,
                              color: Theme.of(context).primaryColor,
                              backgroundColor: Colors.white,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
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
                                  final paiement = _filteredPaiements[index];

                                  return PaiementListItem(
                                    versement: paiement,
                                    onTap:
                                        () => showPaiementDetailsBottomSheet(
                                          context,
                                          paiement,
                                        ),
                                    onEdit: () {},
                                    onDelete: () {},
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
