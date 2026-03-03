import 'dart:async';

import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/package_list_item.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/widgets/add_package_to_warehouse.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/package_details_screen.dart';
import 'package:bbd_limited/core/localization/translation_helper.dart';
import 'package:bbd_limited/components/text_input.dart';

class WarehouseDetailPage extends StatefulWidget {
  final int warehouseId;
  final String? name;
  final String? adresse;
  final String? storageType;
  final Function()? onWarehouseUpdated;

  const WarehouseDetailPage({
    super.key,
    required this.warehouseId,
    this.name,
    this.adresse,
    this.storageType,
    this.onWarehouseUpdated,
  });

  @override
  State<WarehouseDetailPage> createState() => _WarehouseDetailPageState();
}

class _WarehouseDetailPageState extends State<WarehouseDetailPage>
    with SingleTickerProviderStateMixin {
  // Contrôleurs et services
  final TextEditingController searchController = TextEditingController();
  final PackageServices packageServices = PackageServices();

  // Animation controllers
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  // State variables
  List<Packages> _allPackages = [];
  List<Packages> _filteredPackages = [];
  String? _currentFilter;
  bool _isRefreshing = false;
  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    fetchPackages();
    _refreshController.stream.listen((_) => fetchPackages());
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeIn),
    );

    _animationController!.forward();
  }

  Future<void> fetchPackages({bool reset = false, String? searchQuery}) async {
    try {
      final packages = await packageServices.findByWarehouse(
        widget.warehouseId.toInt(),
      );

      setState(() {
        _allPackages = packages;
        _filteredPackages = packages;
      });
    } catch (e) {
      print(TranslationHelper.tWithParams(
          context, 'error_fetching_packages', {'error': e.toString()}));
    }
  }

  void _openAddPackageModal() async {
    final result = await showAddPackageModal(context, widget.warehouseId);

    if (result == true) {
      await fetchPackages();
      setState(() {});
    }
  }

  void filterPackages(String query) {
    setState(() {
      _filteredPackages = _allPackages.where((pkg) {
        final searchPackage = pkg.ref!.toLowerCase().contains(
              query.toLowerCase(),
            );

        bool allStatus = true;
        if (_currentFilter == 'livres') {
          allStatus = pkg.status == Status.RECEIVED;
        } else if (_currentFilter == 'en_transit') {
          allStatus = pkg.status == Status.INPROGRESS;
        } else if (_currentFilter == 'en_attente') {
          allStatus = pkg.status == Status.PENDING;
        }

        return searchPackage && allStatus;
      }).toList();
    });
  }

  Color getStatusColor(Status? status) {
    switch (status) {
      case Status.PENDING:
        return Colors.orange;
      case Status.RECEIVED:
        return Colors.green;
      case Status.DELIVERED:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void handleStatusFilter(String value) {
    setState(() {
      _currentFilter = value;
    });

    filterPackages(searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A1E49),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1E49),
                const Color(0xFF1A1E49).withOpacity(0.8),
              ],
            ),
          ),
        ),
        title: Text(
          TranslationHelper.tWithParams(
              context, 'warehouse_detail_title', {'name': widget.name ?? ''}),
          style: AppTextSize.headlineStyle(context, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing
                ? null
                : () async {
                    setState(() => _isRefreshing = true);
                    await fetchPackages();
                    if (mounted) {
                      setState(() => _isRefreshing = false);
                    }
                  },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPackageModal,
        backgroundColor: const Color(0xFF1A1E49),
        heroTag: 'warehouse_detail_fab',
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          TranslationHelper.t(context, 'add_package_button'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _fadeAnimation != null
          ? FadeTransition(
              opacity: _fadeAnimation!,
              child: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    // Section des informations de l'entrepôt

                    // Section de recherche et filtre
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Champ de recherche
                            Expanded(
                              child: buildTextField(
                                controller: searchController,
                                label: TranslationHelper.t(
                                    context, 'search_package'),
                                icon: Icons.search,
                                onChanged: filterPackages,
                              ),
                            ),
                            const SizedBox(width: 10),
                            FiltreDropdown(onSelected: handleStatusFilter),
                          ],
                        ),
                      ),
                    ),

                    // Liste des colis
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // En-tête de la liste (affiché seulement si la liste n'est pas vide)
                            if (_filteredPackages.isNotEmpty)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    TranslationHelper.t(
                                        context, 'packages_list_title'),
                                    style: AppTextSize.subtitleStyle(context, fontWeight: FontWeight.bold, color: const Color(0xFF1A1E49)),
                                  ),
                                  if (_currentFilter != null)
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _currentFilter = null;
                                          _filteredPackages = _allPackages;
                                          if (searchController
                                              .text.isNotEmpty) {
                                            filterPackages(
                                              searchController.text,
                                            );
                                          }
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.clear_all,
                                        size: 18,
                                      ),
                                      label: Text(TranslationHelper.t(
                                          context, 'view_all_button')),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF7F78AF,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // Liste des colis
                    _filteredPackages.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    TranslationHelper.t(
                                        context, 'no_packages_found'),
                                    style: AppTextSize.titleStyle(context, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final pkg = _filteredPackages[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: PackageListItem(
                                  packages: pkg,
                                  onTap: () => _openPackageDetailsScreen(
                                    context,
                                    pkg,
                                  ),
                                ),
                              );
                            }, childCount: _filteredPackages.length),
                          ),
                  ],
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
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
              final authServices = AuthService();
              final user = await authServices.getUserInfo();
              final result = await packageServices.updateExpedition(
                updatedExpedition.id!,
                updatedExpedition,
                user!.id,
              );
              if (result == "SUCCESS") {
                if (context.mounted) {
                  showSuccessTopSnackBar(
                    context,
                    TranslationHelper.tWithParams(
                        context,
                        'package_modified_success',
                        {'ref': updatedExpedition.ref ?? ''}),
                  );
                  fetchPackages(reset: true);
                }
              } else {
                if (context.mounted) {
                  showErrorTopSnackBar(
                    context,
                    TranslationHelper.t(context, 'error_modifying_package'),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                showErrorTopSnackBar(
                  context,
                  TranslationHelper.t(context, 'error_modifying_package'),
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
  void dispose() {
    searchController.dispose();
    _refreshController.close();
    _animationController?.dispose();
    super.dispose();
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
        borderRadius: BorderRadius.circular(4),
      ),
      child: PopupMenuButton<String>(
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              TranslationHelper.t(context, 'filter_button'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onSelected: onSelected,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            value: 'livres',
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(TranslationHelper.t(context, 'packages_delivered')),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'en_transit',
            child: Row(
              children: [
                const Icon(Icons.local_shipping, color: Colors.purple),
                const SizedBox(width: 8),
                Text(TranslationHelper.t(context, 'packages_in_transit')),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'en_attente',
            child: Row(
              children: [
                const Icon(Icons.hourglass_empty, color: Colors.orange),
                const SizedBox(width: 8),
                Text(TranslationHelper.t(context, 'packages_pending')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
