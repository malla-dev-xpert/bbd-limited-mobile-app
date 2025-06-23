import 'dart:async';
import 'dart:developer';

import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/harbor_services.dart';
import 'package:bbd_limited/models/harbor.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/harbor/detail_harbor.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/harbor/widgets/add_harbor.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

class HarborScreen extends StatefulWidget {
  @override
  State<HarborScreen> createState() => _HarborScreen();
}

class _HarborScreen extends State<HarborScreen> {
  final TextEditingController searchController = TextEditingController();
  final HarborServices _harborServices = HarborServices();

  List<Harbor> _allHarbor = [];
  List<Harbor> _filteredHarbor = [];

  bool _isLoading = false;
  bool _hasMoreData = true;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    fetchHarbor();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchHarbor({bool reset = false, String? searchQuery}) async {
    if (_isLoading || (!reset && !_hasMoreData)) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        currentPage = 0;
        _hasMoreData = true;
        _allHarbor.clear();
      }
    });

    try {
      final result = await _harborServices.findAll(
        page: currentPage,
        query: searchQuery,
      );

      setState(() {
        if (reset) {
          _allHarbor.clear();
        }
        _allHarbor.addAll(result);

        _filteredHarbor = _allHarbor
            .where(
              (port) => searchQuery == null ||
                      searchQuery.isEmpty ||
                      searchQuery == ""
                  ? true
                  : (port.name?.toLowerCase().contains(
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
      log("Erreur de récupération des ports : $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openAddHarborModal({Harbor? harbor}) async {
    final result = await showAddHarborModal(context, harbor: harbor);

    if (result == true) {
      await fetchHarbor(reset: true);
      setState(() {});
    }
  }

  Future<void> _deleteHarbor(Harbor harbor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer le port "${harbor.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // await _harborServices.delete(harbor.id!);
        showSuccessTopSnackBar(context, "Port supprimé avec succès");
        await fetchHarbor(reset: true);
      } catch (e) {
        showErrorTopSnackBar(context, "Erreur lors de la suppression du port");
        log("Erreur de suppression du port : $e");
      }
    }
  }

  void searchHarbor(String query) async {
    if (query.isEmpty) {
      await fetchHarbor(reset: true, searchQuery: null);
    } else {
      final localResults = _allHarbor.where((port) {
        return port.name?.toLowerCase().contains(query.toLowerCase()) ?? false;
      }).toList();

      if (localResults.isNotEmpty) {
        setState(() => _filteredHarbor = localResults);
      } else {
        try {
          await fetchHarbor(reset: true, searchQuery: query);
          final newResults = _allHarbor.where((port) {
            return port.name?.toLowerCase().contains(query.toLowerCase()) ??
                false;
          }).toList();
          setState(() => _filteredHarbor = newResults);
        } catch (e) {
          showErrorTopSnackBar(context, "Erreur lors de la recherche");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Gestion des ports',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddHarborModal(),
        backgroundColor: const Color(0xFF1A1E49),
        heroTag: 'harbor_fab',
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: searchHarbor,
                controller: searchController,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Rechercher un port...',
                  hintText: 'Entrez le nom du port',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF1A1E49)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading && _filteredHarbor.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : (_filteredHarbor.isNotEmpty
                      ? NotificationListener<ScrollNotification>(
                          onNotification: (scrollInfo) {
                            if (scrollInfo.metrics.pixels ==
                                    scrollInfo.metrics.maxScrollExtent &&
                                !_isLoading &&
                                _hasMoreData) {
                              fetchHarbor(searchQuery: searchController.text);
                            }
                            return false;
                          },
                          child: RefreshIndicator(
                            onRefresh: () async {
                              await fetchHarbor(reset: true);
                            },
                            displacement: 40,
                            color: const Color(0xFF1A1E49),
                            backgroundColor: Colors.white,
                            child: ListView.builder(
                              itemCount: _filteredHarbor.length +
                                  (_hasMoreData ? 1 : 0),
                              padding: EdgeInsets.zero,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                if (index < _filteredHarbor.length) {
                                  final port = _filteredHarbor[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => HarborDetailPage(
                                                harbor: port,
                                              ),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  image: const DecorationImage(
                                                    image: AssetImage(
                                                        "assets/images/ports.jpg"),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    color: Colors.black
                                                        .withOpacity(0.4),
                                                  ),
                                                  child: const Icon(
                                                    Icons.local_shipping,
                                                    size: 30,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      port.name!,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.location_on,
                                                          size: 14,
                                                          color: Colors.grey,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            port.location ??
                                                                'Non spécifiée',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .inventory_2_outlined,
                                                          size: 14,
                                                          color: Colors.grey,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          "${port.containers!.where((c) => c.status != Status.DELETE && c.status != Status.RETRIEVE).length} conteneurs",
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Color(0xFF1A1E49),
                                                      size: 20,
                                                    ),
                                                    onPressed: () =>
                                                        _openAddHarborModal(
                                                            harbor: port),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                    onPressed: () =>
                                                        _deleteHarbor(port),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Aucun port trouvé",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
