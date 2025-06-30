import 'dart:async';

import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/create_package_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/package_details_bottom_sheet.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/package_list_item.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/package_details_screen.dart';
import 'package:bbd_limited/models/achats/achat.dart';

enum ExpeditionType { all, plane, boat }

enum ExpeditionStatus { all, received, inTransit, pending }

class PackageHomeScreen extends StatefulWidget {
  const PackageHomeScreen({Key? key}) : super(key: key);

  @override
  _PackageHomeScreenState createState() => _PackageHomeScreenState();
}

class _PackageHomeScreenState extends State<PackageHomeScreen> {
  final TextEditingController searchController = TextEditingController();
  final PackageServices packageServices = PackageServices();
  final AuthService authService = AuthService();

  List<Packages> allPackages = [];
  List<Packages> filteredPackages = [];
  String? currentFilter;
  ExpeditionType selectedType = ExpeditionType.all;
  ExpeditionStatus selectedStatus = ExpeditionStatus.all;

  bool isLoading = false;
  bool hasMoreData = true;
  int currentPage = 0;

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  final GlobalKey _filterIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    fetchPackages();
    _refreshController.stream.listen((_) {
      fetchPackages(reset: true);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _refreshController.close();
    super.dispose();
  }

  Future<void> fetchPackages({bool reset = false, String? searchQuery}) async {
    if (isLoading || (!reset && !hasMoreData)) return;

    setState(() {
      isLoading = true;
      if (reset) {
        currentPage = 0;
        hasMoreData = true;
        allPackages.clear();
      }
    });

    try {
      final result = await packageServices.findAll(
        page: currentPage,
        query: searchQuery,
      );

      setState(() {
        if (reset) {
          allPackages.clear();
        }
        allPackages.addAll(result);
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
    filteredPackages = allPackages.where((exp) {
      final matchesSearch = searchQuery == null ||
          searchQuery.isEmpty ||
          (exp.ref?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);

      final matchesType = selectedType == ExpeditionType.all ||
          (selectedType == ExpeditionType.plane &&
              exp.expeditionType?.toLowerCase() == 'avion') ||
          (selectedType == ExpeditionType.boat &&
              exp.expeditionType?.toLowerCase() == 'bateau');

      final matchesStatus = selectedStatus == ExpeditionStatus.all ||
          (selectedStatus == ExpeditionStatus.received &&
              exp.status == Status.RECEIVED) ||
          (selectedStatus == ExpeditionStatus.inTransit &&
              exp.status == Status.INPROGRESS) ||
          (selectedStatus == ExpeditionStatus.pending &&
              exp.status == Status.PENDING);

      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  void searchPackage(String query) async {
    if (query.isEmpty) {
      await fetchPackages(reset: true, searchQuery: null);
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

  void _onStatusSelected(ExpeditionStatus status) {
    setState(() {
      selectedStatus = status;
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
              boxShadow: isSelected
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

  Future<void> _openCreatePackageBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return const CreateExpeditionForm(isPackageScreen: true);
      },
    );

    if (result == true) {
      fetchPackages(reset: true);
    }
  }

  Future<void> _openPackageDetailsScreen(
    BuildContext context,
    Packages package,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PackageDetailsScreen(
          packages: package,
          onStart: (updatedExpedition) {
            fetchPackages(reset: true);
          },
          onEdit: (updatedExpedition) async {
            try {
              final packageServices = PackageServices();
              final user = await authService.getUserInfo();
              final result = await packageServices.updateExpedition(
                updatedExpedition.id!,
                updatedExpedition,
                user!.id,
              );
              if (result == "SUCCESS") {
                if (context.mounted) {
                  showSuccessTopSnackBar(
                    context,
                    "Colis ${updatedExpedition.ref} modifiée avec succès.",
                  );
                  fetchPackages(reset: true);
                }
              } else {
                if (context.mounted) {
                  showErrorTopSnackBar(
                    context,
                    "Erreur lors de la modification du colis",
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                showErrorTopSnackBar(
                  context,
                  "Erreur lors de la modification du colis",
                );
              }
            }
          },
          onDelete: (updatedExpedition) {
            fetchPackages(reset: true);
          },
        ),
      ),
    );

    if (result == true) {
      fetchPackages(reset: true);
    }
  }

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
                          'Gestion des colis',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1E49),
                            letterSpacing: -0.5,
                            wordSpacing: 0.2,
                          ),
                        ),
                        Text(
                          '${filteredPackages.length} colis trouvées',
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
                    ExpeditionType.boat,
                    Icons.directions_boat,
                    Colors.deepPurple,
                    "Bateau",
                  ),
                  _buildTypeFilter(
                    ExpeditionType.plane,
                    Icons.airplanemode_active,
                    Colors.amber,
                    "Avion",
                  )
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: searchPackage,
                      controller: searchController,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'Rechercher un colis...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.transparent,
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        key: _filterIconKey,
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final RenderBox button =
                              _filterIconKey.currentContext!.findRenderObject()
                                  as RenderBox;
                          final RenderBox overlay = Overlay.of(context)
                              .context
                              .findRenderObject() as RenderBox;
                          final Offset position = button
                              .localToGlobal(Offset.zero, ancestor: overlay);
                          final selected = await showMenu<ExpeditionStatus>(
                            context: context,
                            position: RelativeRect.fromLTRB(
                              position.dx,
                              position.dy + button.size.height,
                              position.dx + button.size.width,
                              overlay.size.height -
                                  (position.dy + button.size.height),
                            ),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            items: [
                              const PopupMenuItem<ExpeditionStatus>(
                                value: ExpeditionStatus.all,
                                child: Row(
                                  children: [
                                    Icon(Icons.filter_list, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text("Tous"),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<ExpeditionStatus>(
                                value: ExpeditionStatus.received,
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green),
                                    SizedBox(width: 8),
                                    Text("Livrée"),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<ExpeditionStatus>(
                                value: ExpeditionStatus.inTransit,
                                child: Row(
                                  children: [
                                    Icon(Icons.local_shipping,
                                        color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text("En transit"),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<ExpeditionStatus>(
                                value: ExpeditionStatus.pending,
                                child: Row(
                                  children: [
                                    Icon(Icons.hourglass_empty,
                                        color: Colors.red),
                                    SizedBox(width: 8),
                                    Text("En attente"),
                                  ],
                                ),
                              ),
                            ],
                          );
                          if (selected != null) {
                            _onStatusSelected(selected);
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(14.0),
                          child: Icon(
                            Icons.filter_list,
                            size: 26,
                            color: Color(0xFF1A1E49),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading && filteredPackages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredPackages.isNotEmpty
                        ? NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (scrollInfo.metrics.pixels ==
                                      scrollInfo.metrics.maxScrollExtent &&
                                  !isLoading &&
                                  hasMoreData) {
                                fetchPackages(
                                    searchQuery: searchController.text);
                              }
                              return false;
                            },
                            child: RefreshIndicator(
                              onRefresh: () async {
                                await fetchPackages(reset: true);
                              },
                              displacement: 40,
                              color: Theme.of(context).primaryColor,
                              backgroundColor: Colors.white,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: filteredPackages.length +
                                    (hasMoreData && isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= filteredPackages.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final package = filteredPackages[index];
                                  return Padding(
                                    padding: const EdgeInsets.all(
                                      0.0,
                                    ),
                                    child: PackageListItem(
                                      packages: package,
                                      onTap: () => _openPackageDetailsScreen(
                                        context,
                                        package,
                                      ),
                                    ),
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
        onPressed: () => _openCreatePackageBottomSheet(context),
        backgroundColor: const Color(0xFF1A1E49),
        heroTag: 'expedition_fab',
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final Items item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.description ?? 'Sans description',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Qté: ${item.quantity ?? 0}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (item.supplierName != null && item.supplierName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Fournisseur: ${item.supplierName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            if (item.unitPrice != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Prix unitaire: ${item.unitPrice!.toStringAsFixed(2)} €',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            if (item.totalPrice != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.receipt,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Prix total: ${item.totalPrice!.toStringAsFixed(2)} €',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  final bool isLoading;
  final List<Items> items;
  const _ItemsSection({required this.isLoading, required this.items});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text(
            'Aucun article dans ce colis',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: items.map((item) => _ItemRow(item: item)).toList(),
      ),
    );
  }
}
