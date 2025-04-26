import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/create_partner_bottom_sheet.dart';
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
        // _filteredHarbor.clear();
      }
    });

    try {
      final result = await _partnerServices.findAll(
        page: currentPage,
        query: searchQuery,
      );

      setState(() {
        if (reset) {
          _allPartners.clear();
        }
        _allPartners.addAll(result);

        _filteredPartners =
            _allPartners
                .where(
                  (partner) =>
                      searchQuery == null ||
                              searchQuery.isEmpty ||
                              searchQuery == ""
                          ? true
                          : (partner.firstName.toLowerCase().contains(
                                searchQuery.toLowerCase(),
                              ) ??
                              false),
                )
                .toList();

        if (result.isEmpty || result.length < 30) {
          _hasMoreData = false;
        } else {
          currentPage++;
        }
      });
    } catch (e) {
      showErrorTopSnackBar(context, "Erreur de chargement des ports.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void searchPartner(String query) async {
    if (query.isEmpty) {
      await loadPartners(reset: true, searchQuery: null);
    } else {
      // recherche locale
      final localResults =
          _allPartners.where((port) {
            return port.firstName.toLowerCase().contains(query.toLowerCase()) ??
                false;
          }).toList();

      if (localResults.isNotEmpty) {
        setState(() => _filteredPartners = localResults);
      } else {
        // recherche dans la base de donnee
        try {
          await loadPartners(reset: true, searchQuery: query);

          final newResults =
              _allPartners.where((port) {
                return port.firstName.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false;
              }).toList();

          setState(() => _filteredPartners = newResults);
        } catch (e) {
          showErrorTopSnackBar(context, "Erreur lors de la recherche");
        }
      }
    }
  }

  void filterPartners(String query) {
    setState(() {
      _filteredPartners =
          _allPartners.where((parter) {
            final searchPackage = parter.firstName.toLowerCase().contains(
              query.toLowerCase(),
            );

            bool allStatus = true;
            if (_currentFilter == 'clients') {
              allStatus = parter.accountType == 'CLIENT';
            } else if (_currentFilter == 'fournisseurs') {
              allStatus = parter.accountType == 'FOURNISSEUR';
            }

            return searchPackage && allStatus;
          }).toList();
    });
  }

  void handleStatusFilter(String value) {
    setState(() {
      _currentFilter = value;
    });

    filterPartners(searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          "Gestion des partenaires",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1E49),
        tooltip: 'Add New partner',
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
                FiltreDropdown(onSelected: handleStatusFilter),
              ],
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "La liste des ${_currentFilter == null
                      ? 'partenaires'
                      : _currentFilter == 'clients'
                      ? 'clients'
                      : _currentFilter == 'fournisseurs'
                      ? 'fournisseurs'
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
                        _filteredPartners = _allPartners;
                        if (searchController.text.isNotEmpty) {
                          filterPartners(searchController.text);
                        }
                      });
                    },
                    child: const Text("Voir tout"),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  _isLoading && _filteredPartners.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : (_filteredPartners.isNotEmpty
                          ? NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (scrollInfo.metrics.pixels ==
                                      scrollInfo.metrics.maxScrollExtent &&
                                  !_isLoading &&
                                  _hasMoreData) {
                                loadPartners(
                                  searchQuery: searchController.text,
                                );
                              }
                              return false;
                            },
                            child: ListView.builder(
                              physics: AlwaysScrollableScrollPhysics(),
                              itemCount:
                                  _filteredPartners.length +
                                  (_hasMoreData && _isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= _filteredPartners.length) {
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final partner = _filteredPartners[index];
                                return ListTile(
                                  title: Text(
                                    "${partner.firstName} ${partner.lastName}",
                                  ),
                                  subtitle: Text(
                                    partner.phoneNumber.toString(),
                                  ),
                                  trailing: Text(partner.accountType),
                                );
                              },
                            ),
                          )
                          : Center(child: Text("Aucun partenaire trouvé"))),
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
            Text('Filtrer', style: TextStyle(color: Colors.white)),
            SizedBox(width: 8),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onSelected: onSelected,
        itemBuilder:
            (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'clients',
                child: Text('Par clients'),
              ),
              const PopupMenuItem<String>(
                value: 'fournisseurs',
                child: Text('Par fournisseurs'),
              ),
            ],
      ),
    );
  }
}
