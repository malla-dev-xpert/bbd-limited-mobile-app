import 'dart:async';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/new_versement.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/edit_paiement_modal.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManageUsersScreen extends StatefulWidget {
  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
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
        return NewVersementModal();
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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Gestion des utilisateurs",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search and Filter Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Rechercher un utilisateur...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: filterPackages,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        title: "Total des clients",
                        value: _allPaiements.length.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        title: "Clients actifs",
                        value:
                            _allPaiements
                                .where((p) => p.status == "active")
                                .length
                                .toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Users List
                  if (_isLoading && _allPaiements.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (_filteredPaiements.isEmpty)
                    _buildEmptyState()
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                          _filteredPaiements.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredPaiements.length) {
                          if (_isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        return _buildUserCard(_filteredPaiements[index]);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewPaiementBottomSheet(context),
        backgroundColor: Theme.of(context).primaryColor,
        heroTag: 'users_fab',
        icon: const Icon(Icons.add),
        label: const Text("Nouvel utilisateur"),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildUserCard(Versement user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            user.reference?.substring(0, 1).toUpperCase() ?? "U",
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.reference ?? "Sans référence",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          user.partnerAccountType ?? "Type inconnu",
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: PopupMenuButton(
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text("Modifier"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Supprimer", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditPaiementModal(context, user);
            } else if (value == 'delete') {
              _delete(user);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height:
          MediaQuery.of(context).size.height *
          0.4, // Constrain height to 40% of screen
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Aucun utilisateur trouvé",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Commencez par ajouter un nouvel utilisateur",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
