import 'dart:async';
import 'dart:developer';

import 'package:bbd_limited/core/services/harbor_services.dart';
import 'package:bbd_limited/models/harbor.dart';
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

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
    fetchHarbor();
    _refreshController.stream.listen((_) {
      fetchHarbor(reset: true);
    });
  }

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  Future<void> fetchHarbor({bool reset = false, String? searchQuery}) async {
    if (_isLoading || (!reset && !_hasMoreData)) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        currentPage = 0;
        _hasMoreData = true;
        _allHarbor = [];
      }
    });
    try {
      final result = await _harborServices.findAll(
        page: currentPage,
        query: searchQuery,
      );

      setState(() {
        _allHarbor.addAll(result);

        _filteredHarbor =
            _allHarbor
                .where(
                  (port) =>
                      searchQuery == null || searchQuery.isEmpty
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

  void searchHarbor(String query) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
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

            // Barre de recherche
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
                  onPressed: () {},

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
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent &&
                      !_isLoading &&
                      _hasMoreData) {
                    fetchHarbor();
                  }
                  return false;
                },
                child: ListView.builder(
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount:
                      _filteredHarbor.length +
                      (_hasMoreData && _isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    return GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: List.generate(_filteredHarbor.length, (index) {
                        final port = _filteredHarbor[index];
                        if (_allHarbor == []) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (_filteredHarbor.isEmpty) {
                          return Center(child: Text("Aucun port trouvé"));
                        }

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: Colors.grey[50],
                          elevation: 2,
                          child: Column(
                            children: [
                              // Image de fond avec overlay sombre
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
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
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      color: Colors.black.withOpacity(0.4),
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

                              // Informations du port
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        port.name!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: -1,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Adresse : ${port.location ?? 'Non spécifiée'}",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Conteneurs : ${port.containers?.length ?? 0}",
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
