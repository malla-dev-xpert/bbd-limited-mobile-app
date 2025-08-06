import 'dart:async';

import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/create_package_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/package_list_item.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/package_details_screen.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

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
      showErrorTopSnackBar(context,
          AppLocalizations.of(context).translate('error_loading_expeditions'));
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
                    AppLocalizations.of(context)
                        .translate('expedition_modified_success')
                        .replaceAll('{ref}', updatedExpedition.ref ?? ''),
                  );
                  fetchPackages(reset: true);
                }
              } else {
                if (context.mounted) {
                  showErrorTopSnackBar(
                    context,
                    AppLocalizations.of(context)
                        .translate('error_modifying_expedition'),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                showErrorTopSnackBar(
                  context,
                  AppLocalizations.of(context)
                      .translate('error_modifying_expedition'),
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
                        Text(
                          AppLocalizations.of(context)
                              .translate('home_manage_packages_title'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1E49),
                            letterSpacing: -0.5,
                            wordSpacing: 0.2,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)
                              .translate('packages_found')
                              .replaceAll('{count}',
                                  filteredPackages.length.toString()),
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
                    AppLocalizations.of(context).translate('all'),
                  ),
                  _buildTypeFilter(
                    ExpeditionType.boat,
                    Icons.directions_boat,
                    Colors.deepPurple,
                    AppLocalizations.of(context).translate('boat'),
                  ),
                  _buildTypeFilter(
                    ExpeditionType.plane,
                    Icons.airplanemode_active,
                    Colors.amber,
                    AppLocalizations.of(context).translate('plane'),
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
                        labelText: AppLocalizations.of(context)
                            .translate('search_package'),
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
                              PopupMenuItem<ExpeditionStatus>(
                                value: ExpeditionStatus.all,
                                child: Row(
                                  children: [
                                    const Icon(Icons.filter_list,
                                        color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(context)
                                        .translate('filter_all')),
                                  ],
                                ),
                              ),
                              PopupMenuItem<ExpeditionStatus>(
                                value: ExpeditionStatus.received,
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(context)
                                        .translate('filter_delivered')),
                                  ],
                                ),
                              ),
                              PopupMenuItem<ExpeditionStatus>(
                                value: ExpeditionStatus.inTransit,
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_shipping,
                                        color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(context)
                                        .translate('filter_in_transit')),
                                  ],
                                ),
                              ),
                              PopupMenuItem<ExpeditionStatus>(
                                value: ExpeditionStatus.pending,
                                child: Row(
                                  children: [
                                    const Icon(Icons.hourglass_empty,
                                        color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(context)
                                        .translate('filter_pending')),
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
                        : Center(
                            child: Text(AppLocalizations.of(context)
                                .translate('no_expeditions_found')),
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
