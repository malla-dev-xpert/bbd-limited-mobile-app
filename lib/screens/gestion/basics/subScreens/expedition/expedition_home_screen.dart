import 'dart:async';

import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/expedition_services.dart';
import 'package:bbd_limited/models/expedition.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/expedition/widgets/expedition_list_item.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

enum ExpeditionType { all, plane, boat }

class ExpeditionHomeScreen extends StatefulWidget {
  const ExpeditionHomeScreen({Key? key}) : super(key: key);

  @override
  _ExpeditionHomeScreenState createState() => _ExpeditionHomeScreenState();
}

class _ExpeditionHomeScreenState extends State<ExpeditionHomeScreen> {
  final TextEditingController searchController = TextEditingController();
  final ExpeditionServices expeditionServices = ExpeditionServices();
  final AuthService authService = AuthService();

  List<Expedition> allExpeditions = [];
  List<Expedition> filteredExpeditions = [];
  String? currentFilter;
  ExpeditionType selectedType = ExpeditionType.all;

  bool isLoading = false;
  bool hasMoreData = true;
  int currentPage = 0;

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
    fetchExpeditions();
    _refreshController.stream.listen((_) {
      fetchExpeditions(reset: true);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _refreshController.close();
    super.dispose();
  }

  Future<void> fetchExpeditions({
    bool reset = false,
    String? searchQuery,
  }) async {
    if (isLoading || (!reset && !hasMoreData)) return;

    setState(() {
      isLoading = true;
      if (reset) {
        currentPage = 0;
        hasMoreData = true;
        allExpeditions.clear();
      }
    });

    try {
      final result = await expeditionServices.findAll(
        page: currentPage,
        query: searchQuery,
      );

      setState(() {
        if (reset) {
          allExpeditions.clear();
        }
        allExpeditions.addAll(result);
        _applyFilters(searchQuery);

        if (result.isEmpty || result.length < 30) {
          hasMoreData = false;
        } else {
          currentPage++;
        }
      });
    } catch (e) {
      showErrorTopSnackBar(context, "Erreur de chargement des expeditions.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters(String? searchQuery) {
    filteredExpeditions =
        allExpeditions.where((exp) {
          final matchesSearch =
              searchQuery == null ||
              searchQuery.isEmpty ||
              (exp.ref?.toLowerCase().contains(searchQuery.toLowerCase()) ??
                  false);

          final matchesType =
              selectedType == ExpeditionType.all ||
              (selectedType == ExpeditionType.plane &&
                  exp.expeditionType?.toLowerCase() == 'avion') ||
              (selectedType == ExpeditionType.boat &&
                  exp.expeditionType?.toLowerCase() == 'bateau');

          return matchesSearch && matchesType;
        }).toList();
  }

  void searchExpedition(String query) async {
    if (query.isEmpty) {
      await fetchExpeditions(reset: true, searchQuery: null);
    } else {
      _applyFilters(query);
    }
  }

  void _onTypeSelected(ExpeditionType type) {
    setState(() {
      selectedType = type;
      _applyFilters(searchController.text);
    });
  }

  Widget _buildTypeFilter(
    ExpeditionType type,
    IconData icon,
    Color color,
    String label,
  ) {
    final isSelected = selectedType == type;
    return GestureDetector(
      onTap: () => _onTypeSelected(type),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: isSelected ? Border.all(color: color, width: 2) : null,
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : null,
            ),
          ),
        ],
      ),
    );
  }

  // Future<void> _openCreateExpeditionBottomSheet(BuildContext context) async {
  //   final result = await showModalBottomSheet<bool>(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.white,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //     ),
  //     builder: (context) {
  //       return CreateExpeditionForm();
  //     },
  //   );

  //   if (result == true) {
  //     fetchExpeditions(reset: true);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF1A1E49),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gestion des expéditions',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1E49),
                            letterSpacing: -0.5,
                            wordSpacing: 0.2,
                          ),
                        ),
                        Text(
                          '${filteredExpeditions.length} expéditions trouvées',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 25,
                children: [
                  _buildTypeFilter(
                    ExpeditionType.all,
                    Icons.all_inbox,
                    Colors.blue,
                    "Tous",
                  ),
                  _buildTypeFilter(
                    ExpeditionType.plane,
                    Icons.airplanemode_active,
                    Colors.amber,
                    "Avion",
                  ),
                  _buildTypeFilter(
                    ExpeditionType.boat,
                    Icons.directions_boat,
                    Colors.deepPurple,
                    "Bateau",
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: searchExpedition,
                      controller: searchController,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'Rechercher une expédition...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child:
                    isLoading && filteredExpeditions.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : filteredExpeditions.isNotEmpty
                        ? NotificationListener<ScrollNotification>(
                          onNotification: (scrollInfo) {
                            if (scrollInfo.metrics.pixels ==
                                    scrollInfo.metrics.maxScrollExtent &&
                                !isLoading &&
                                hasMoreData) {
                              fetchExpeditions(
                                searchQuery: searchController.text,
                              );
                            }
                            return false;
                          },
                          child: RefreshIndicator(
                            onRefresh: () async {
                              await fetchExpeditions(reset: true);
                            },
                            displacement: 40,
                            color: Theme.of(context).primaryColor,
                            backgroundColor: Colors.white,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount:
                                  filteredExpeditions.length +
                                  (hasMoreData && isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= filteredExpeditions.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final expedition = filteredExpeditions[index];
                                return ExpeditionListItem(
                                  expedition: expedition,
                                  onTap: () {},
                                  onEdit: () {},
                                  onDelete: () {},
                                );
                              },
                            ),
                          ),
                        )
                        : const Center(
                          child: Text("Aucune expédition trouvée"),
                        ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {},
        backgroundColor: const Color(0xFF1A1E49),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
