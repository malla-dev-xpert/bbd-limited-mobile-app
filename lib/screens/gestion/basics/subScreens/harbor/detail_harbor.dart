import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/harbor_services.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/harbor.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/container_detail_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/container_list_item.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/pages/edit_container_page.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/harbor/pages/embark_containers_page.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HarborDetailPage extends StatefulWidget {
  final Harbor harbor;

  const HarborDetailPage({required this.harbor, Key? key}) : super(key: key);

  @override
  State<HarborDetailPage> createState() => _HarborDetailPageState();
}

class _HarborDetailPageState extends State<HarborDetailPage> {
  final AuthService _authService = AuthService();
  final HarborServices _harborServices = HarborServices();
  final ContainerServices _containerServices = ContainerServices();
  bool _isLoading = false;
  bool _isRefreshing = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Containers> get _filteredContainers {
    if (_searchQuery.isEmpty) {
      return widget.harbor.containers
              ?.where((c) =>
                  c.status != Status.DELETE && c.status != Status.RETRIEVE)
              .toList() ??
          [];
    }
    return widget.harbor.containers
            ?.where((c) =>
                c.status != Status.DELETE &&
                c.status != Status.RETRIEVE &&
                (c.reference
                        ?.toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ??
                    false))
            .toList() ??
        [];
  }

  Future<void> _handleAddContainers() async {
    if (_isLoading || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final count = await Navigator.push<int>(
        context,
        MaterialPageRoute(
          builder: (context) => EmbarkContainersPage(
            harborId: widget.harbor.id,
            harborName: widget.harbor.name,
          ),
        ),
      );

      if (count != null && count > 0 && mounted) {
        final updatedHarbor = await _harborServices.getHarborDetails(
          widget.harbor.id,
        );
        setState(() => widget.harbor.containers = updatedHarbor.containers);
        showSuccessTopSnackBar(
          context,
          AppLocalizations.of(context)!.translate('harbor_detail_add_success'),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)!.translate('harbor_detail_error_update'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _handleContainerDismiss(Containers container) async {
    final loc = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.translate('harbor_detail_remove_confirm_title')),
          backgroundColor: Colors.white,
          content: Text(
            loc
                .translate('harbor_detail_remove_confirm_message')
                .replaceAll(
                    '{reference}', container.reference ?? ''),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                loc.translate('cancel'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                loc.translate('confirm'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return false;

    try {
      final user = await _authService.getUserInfo();
      if (user == null) {
        if (mounted) {
          showErrorTopSnackBar(
              context, loc.translate('harbor_detail_error_user'));
        }
        return false;
      }

      if (container.id == null) {
        showErrorTopSnackBar(
            context, loc.translate('harbor_detail_error_container'));
        return false;
      }

      if (mounted) setState(() => _isLoading = true);

      final result = await _harborServices.retrieveContainerToHarbor(
        container.id!,
        user.id.toInt(),
        widget.harbor.id,
      );

      if (result == "SUCCESS" && mounted) {
        final updatedHarbor = await _harborServices.getHarborDetails(
          widget.harbor.id,
        );
        setState(() {
          widget.harbor.containers = updatedHarbor.containers;
        });
        showSuccessTopSnackBar(
            context, loc.translate('harbor_detail_remove_success'));
        return true;
      } else if (result == "IMPOSSIBLE" && mounted) {
        showErrorTopSnackBar(
          context,
          loc.translate('harbor_detail_error_remove_impossible'),
        );
      } else if (result == "CONTAINER_ALREADY_RETRIEVED" && mounted) {
        showErrorTopSnackBar(
            context, loc.translate('harbor_detail_error_already_retrieved'));
      }
      return false;
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          loc.translate('harbor_detail_error_remove'),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openContainerDetail(Containers item) async {
    if (item.id == null) return;
    setState(() => _isLoading = true);
    try {
      final fullContainer =
          await _containerServices.getContainerDetails(item.id!);
      if (!mounted) return;
      final updated = await Navigator.push<Containers>(
        context,
        MaterialPageRoute(
          builder: (context) => ContainerDetailPage(
            container: fullContainer,
          ),
        ),
      );
      if (updated != null && mounted) {
        setState(() {
          final idx =
              widget.harbor.containers?.indexWhere((c) => c.id == updated.id);
          if (idx != null && idx >= 0 && widget.harbor.containers != null) {
            widget.harbor.containers![idx] = updated;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)!
              .translate('harbor_detail_error_load_container'),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openEditContainer(Containers item) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditContainerPage(
          container: item,
          onContainerUpdated: () => fetchPackages(),
        ),
      ),
    );
  }

  Future<void> fetchPackages() async {
    try {
      final updatedHarbor = await _harborServices.getHarborDetails(
        widget.harbor.id,
      );
      if (mounted) {
        setState(() {
          widget.harbor.containers = updatedHarbor.containers;
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)!.translate('harbor_detail_error_update'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final formattedDate = widget.harbor.createdAt != null
        ? DateFormat.yMMMMEEEEd().format(widget.harbor.createdAt!)
        : loc.translate('harbor_detail_date_unavailable');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            actions: [
              IconButton(
                onPressed: _isRefreshing
                    ? null
                    : () async {
                        setState(() => _isRefreshing = true);
                        await fetchPackages();
                        if (mounted) {
                          setState(() => _isRefreshing = false);
                        }
                      },
                tooltip: loc.translate('harbor_detail_refresh_tooltip'),
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(200),
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Color(0xFF1A1E49),
                        ),
                      ),
              ),
            ],
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.harbor.name ?? loc.translate('harbor_detail_no_name'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.harbor.location ?? loc.translate('harbor_detail_no_address'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory,
                                size: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "${widget.harbor.containers?.where((c) => c.status != Status.DELETE && c.status != Status.RETRIEVE).length ?? 0} ${loc.translate('harbor_detail_containers_count')}",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              background: Hero(
                tag: 'portImage-${widget.harbor.id}',
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.asset(
                        "assets/images/ports.jpg",
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildContainersListSection(),
        ],
      ),
    );
  }

  SliverList _buildContainersListSection() {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.harbor.containers?.isNotEmpty ?? false) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!
                            .translate('harbor_detail_container_list'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _handleAddContainers,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF7F78AF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      label: Text(AppLocalizations.of(context)!
                          .translate('harbor_detail_embark_button')),
                      icon: const Icon(Icons.add, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: buildTextField(
                    controller: _searchController,
                    label: AppLocalizations.of(context)!
                        .translate('harbor_detail_search_placeholder'),
                    icon: Icons.search,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (widget.harbor.containers == null ||
                  widget.harbor.containers!.isEmpty)
                _buildEmptyContainersState()
              else if (_searchQuery.isNotEmpty && _filteredContainers.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!
                            .translate('harbor_detail_no_results'),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!
                            .translate('harbor_detail_no_results_subtitle'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _filteredContainers
                      .map(
                        (item) => ContainerListItem(
                          container: item,
                          onTap: () => _openContainerDetail(item),
                          onEdit: () => _openEditContainer(item),
                          onDelete: () {
                            _handleContainerDismiss(item).then((removed) {
                              if (removed && mounted) fetchPackages();
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildEmptyContainersState() {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height * 0.2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.translate('harbor_detail_empty_state')),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleAddContainers,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                loc.translate('harbor_detail_embark_one'),
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7F78AF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
