import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/create_partner_bottom_sheet.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/partner_edit_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/partner_list_items.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

class PartnerScreen extends StatefulWidget {
  const PartnerScreen({Key? key}) : super(key: key);

  @override
  _PartnerScreenState createState() => _PartnerScreenState();
}

class _PartnerScreenState extends State<PartnerScreen> {
  final TextEditingController searchController = TextEditingController();
  final PartnerServices _partnerServices = PartnerServices();
  final AuthService authService = AuthService();

  List<Partner> _allPartners = [];
  List<Partner> _filteredPartners = [];
  String? _currentFilter;

  bool _isLoading = false;
  bool _hasMoreData = true;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    loadPartners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadPartners({bool reset = false, String? searchQuery}) async {
    if (_isLoading || (!reset && !_hasMoreData)) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        currentPage = 0;
        _hasMoreData = true;
        _allPartners.clear();
      }
    });

    try {
      final result = await _partnerServices.findCustomers(
        page: currentPage,
        query: searchQuery,
      );

      setState(() {
        if (reset) {
          _allPartners.clear();
        }
        _allPartners.addAll(result);

        if (searchQuery == null || searchQuery.isEmpty) {
          _filteredPartners = List.from(_allPartners);
        } else {
          _filteredPartners =
              _allPartners
                  .where(
                    (partner) => partner.firstName.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();
        }

        if (result.isEmpty || result.length < 30) {
          _hasMoreData = false;
        } else {
          currentPage++;
        }
      });
    } catch (e) {
      showErrorTopSnackBar(context, "Erreur de chargement des partenaires.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void searchPartner(String query) async {
    if (query.isEmpty) {
      await loadPartners(reset: true);
      return;
    }

    // recherche locale
    final localResults =
        _allPartners.where((partner) {
          return partner.firstName.toLowerCase().contains(query.toLowerCase());
        }).toList();

    if (localResults.isNotEmpty) {
      setState(() => _filteredPartners = localResults);
    } else {
      // recherche dans la base de donnee
      try {
        await loadPartners(reset: true, searchQuery: query);
      } catch (e) {
        showErrorTopSnackBar(context, "Erreur lors de la recherche");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          "Gestion des comptes clients",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1E49),
        tooltip: 'Add New partner',
        heroTag: 'partner_fab',
        onPressed: () async {
          final shouldRefresh = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (context) => CreatePartnerBottomSheet(),
          );

          if (shouldRefresh == true) {
            loadPartners(reset: true);
          }
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 10,
              children: [
                Expanded(
                  child: TextField(
                    onChanged: searchPartner,
                    controller: searchController,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Recherche...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildPartnerList()),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerList() {
    if (_isLoading && _filteredPartners.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredPartners.isEmpty) {
      return const Center(child: Text("Aucun partenaire trouvé"));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await loadPartners(reset: true);
      },
      displacement: 40,
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: ListView.builder(
          physics:
              const AlwaysScrollableScrollPhysics(), // permet le pull même si la liste est courte
          itemCount: _filteredPartners.length + (_hasMoreData ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _filteredPartners.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text("Chargement en cours..."),
                    ],
                  ),
                ),
              );
            }

            final partner = _filteredPartners[index];
            return PartnerListItem(
              partner: partner,
              onEdit: _editPartner,
              onDelete: _deletePartner,
            );
          },
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification scrollInfo) {
    if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
        !_isLoading &&
        _hasMoreData) {
      loadPartners(searchQuery: searchController.text);
    }
    return false;
  }

  void _editPartner(Partner partner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => PartnerEditForm(
            partner: partner,
            onSubmit: (updatedPartner) async {
              try {
                setState(() => _isLoading = true);
                final success = await _partnerServices.updatePartner(
                  updatedPartner.id,
                  updatedPartner,
                );

                if (success) {
                  await loadPartners(reset: true);
                  Navigator.pop(context);
                  showSuccessTopSnackBar(
                    context,
                    "Partenaire modifié avec succès",
                  );
                }
              } catch (e) {
                showErrorTopSnackBar(context, "Erreur lors de la modification");
              } finally {
                setState(() => _isLoading = false);
              }
            },
          ),
    );
  }

  Future<void> _deletePartner(Partner partner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirmer la suppression"),
            backgroundColor: Colors.white,
            content: Text(
              "Supprimer le partenaire ${partner.firstName} ${partner.lastName}?",
            ),
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
        final user = await authService.getUserInfo();

        if (user == null) {
          showErrorTopSnackBar(context, "Veuillez vous connecter.");
          return;
        }
        setState(() => _isLoading = true);
        final result = await _partnerServices.deletePartner(
          partner.id,
          user.id,
        );

        if (result == "DELETED") {
          loadPartners(reset: true);
          _filteredPartners.removeWhere((element) => element.id == partner.id);
          showSuccessTopSnackBar(context, "Partenaire supprimé avec succès");
        } else {
          _handleDeleteError(result);
        }
      } catch (e) {
        showErrorTopSnackBar(context, "Erreur lors de la suppression");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleDeleteError(String? errorCode) {
    switch (errorCode) {
      case "PARTNER_NOT_FOUND":
        showErrorTopSnackBar(context, "Partenaire introuvable");
        break;
      case "PACKAGE_FOUND":
        showErrorTopSnackBar(
          context,
          "Impossible de supprimer - Il y'a des colis existants pour ce partenaire.",
        );
        break;
      default:
        showErrorTopSnackBar(context, "Erreur inconnue");
    }
  }
}
