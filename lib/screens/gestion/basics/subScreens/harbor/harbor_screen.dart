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
        // _filteredHarbor.clear();
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

        _filteredHarbor =
            _allHarbor
                .where(
                  (port) =>
                      searchQuery == null ||
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

  void _openAddHarborModal() async {
    final result = await showAddHarborModal(context);

    if (result == true) {
      await fetchHarbor(reset: true);
      setState(() {});
    }
  }

  void searchHarbor(String query) async {
    if (query.isEmpty) {
      await fetchHarbor(reset: true, searchQuery: null);
    } else {
      // recherche locale
      final localResults =
          _allHarbor.where((port) {
            return port.name?.toLowerCase().contains(query.toLowerCase()) ??
                false;
          }).toList();

      if (localResults.isNotEmpty) {
        setState(() => _filteredHarbor = localResults);
      } else {
        // recherche dans la base de donnee
        try {
          await fetchHarbor(reset: true, searchQuery: query);

          final newResults =
              _allHarbor.where((port) {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'Gestion des ports',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    onChanged: searchHarbor,
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
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _openAddHarborModal,
                  label: Text("Ajouter", style: TextStyle(color: Colors.white)),
                  icon: Icon(Icons.add, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    backgroundColor: const Color(0xFF1A1E49),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  _isLoading && _filteredHarbor.isEmpty
                      ? Center(child: CircularProgressIndicator())
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
                              color: Theme.of(context).primaryColor,
                              backgroundColor: Colors.white,
                              child: GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 4,
                                      crossAxisSpacing: 4,
                                    ),
                                itemCount:
                                    _filteredHarbor.length +
                                    (_hasMoreData ? 1 : 0),
                                padding: EdgeInsets.zero,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  if (index < _filteredHarbor.length) {
                                    final port = _filteredHarbor[index];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => HarborDetailPage(
                                                  harbor: port,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        color: Colors.grey[50],
                                        elevation: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // image du port
                                            Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      const BorderRadius.vertical(
                                                        top: Radius.circular(
                                                          20,
                                                        ),
                                                      ),
                                                  child: Image.asset(
                                                    "assets/images/ports.jpg",
                                                    height: 70,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                Container(
                                                  height: 70,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            20,
                                                          ),
                                                        ),
                                                    color: Colors.black
                                                        .withOpacity(0.4),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: const Icon(
                                                    Icons.local_shipping,
                                                    size: 30,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // donnees du port
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      port.name!,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        letterSpacing: -1,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "Adresse : ${port.location ?? 'Non spécifiée'}",
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        letterSpacing: -1,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "Conteneurs : ${port.containers!.where((c) => c.status != Status.DELETE && c.status != Status.RETRIEVE).length}",
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        letterSpacing: -1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                },
                              ),
                            ),
                          )
                          : Center(child: Text("Aucun port trouvé"))),
            ),
          ],
        ),
      ),
    );
  }
}
