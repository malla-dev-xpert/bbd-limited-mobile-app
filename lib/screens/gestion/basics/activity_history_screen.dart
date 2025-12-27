import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/log_service.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/models/activity_log.dart';
import 'package:bbd_limited/models/user.dart';
import 'package:bbd_limited/components/activity_log_item.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/enums/date_filter_option.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:intl/intl.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  final LogService _logService = LogService();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();

  List<ActivityLog> _logs = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isInitialLoading = true;
  bool _isCheckingAdmin = true;
  String? _errorMessage;
  User? _user;

  // Filtres
  List<User> _allUsers = [];
  User? _selectedUser;
  DateFilterOption _selectedDateOption = DateFilterOption.all;
  DateTime? _customDate;

  bool get isAdmin {
    final permissions = _user?.role?.permissions ?? [];
    return permissions.contains('IS_ADMIN');
  }

  bool _hasActiveFilters() {
    return _selectedUser != null || _selectedDateOption != DateFilterOption.all;
  }

  Widget? _buildActiveFiltersBar(AppLocalizations localizations) {
    final filters = <Widget>[];

    if (_selectedUser != null) {
      filters.add(
        _buildFilterChip(
          icon: Icons.person,
          label: localizations.translate('activity_history_user'),
          value: _getUserDisplayName(_selectedUser!),
          onRemove: () {
            setState(() {
              _selectedUser = null;
            });
            _loadLogs(refresh: true);
          },
        ),
      );
    }

    if (_selectedDateOption != DateFilterOption.all) {
      String dateLabel;
      if (_selectedDateOption == DateFilterOption.customDate &&
          _customDate != null) {
        dateLabel = DateFormat('dd/MM/yyyy').format(_customDate!);
      } else {
        dateLabel = _selectedDateOption.getDisplayName(localizations);
      }

      filters.add(
        _buildFilterChip(
          icon: Icons.calendar_today,
          label: localizations.translate('filter_by_date'),
          value: dateLabel,
          onRemove: () {
            setState(() {
              _selectedDateOption = DateFilterOption.all;
              _customDate = null;
            });
            _loadLogs(refresh: true);
          },
        ),
      );
    }

    if (filters.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  localizations.translate('active_filters'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (filters.length > 1)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedUser = null;
                        _selectedDateOption = DateFilterOption.all;
                        _customDate = null;
                      });
                      _loadLogs(refresh: true);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      localizations.translate('clear_filters'),
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF1A1E49),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ...filters,
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E49).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1A1E49).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRemove,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: const Color(0xFF1A1E49),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A1E49),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoad();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _checkAdminAndLoad() async {
    try {
      final user = await _authService.getUserInfo();
      if (mounted) {
        setState(() {
          _user = user;
          _isCheckingAdmin = false;
        });

        // Vérifier si l'utilisateur est admin
        if (!isAdmin) {
          // Rediriger vers la page d'accueil si l'utilisateur n'est pas admin
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).translate('forbidden'),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Si admin, charger les utilisateurs et les logs
        await _loadUsers();
        _loadLogs();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingAdmin = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreLogs();
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _authService.getAllUsers(page: 0);
      if (mounted) {
        setState(() {
          _allUsers = users;
        });
      }
    } catch (e) {
      // Erreur silencieuse, on continue sans filtre utilisateur
    }
  }

  Future<void> _loadLogs({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    // Si refresh, réinitialiser tout immédiatement
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      _logs = [];
      // Réinitialiser la position du scroll
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }

    // Calculer les dates de filtre AVANT le setState
    DateTime? dateStart;
    DateTime? dateEnd;

    if (_selectedDateOption != DateFilterOption.all) {
      if (_selectedDateOption == DateFilterOption.customDate &&
          _customDate != null) {
        // Pour une date personnalisée, filtrer sur toute la journée
        dateStart = DateTime(
            _customDate!.year, _customDate!.month, _customDate!.day, 0, 0, 0);
        dateEnd = DateTime(_customDate!.year, _customDate!.month,
            _customDate!.day, 23, 59, 59);
      } else {
        final dateRange = _selectedDateOption.getDateRange();
        if (dateRange != null) {
          // S'assurer que les dates ont les heures correctes
          dateStart = DateTime(
            dateRange.start.year,
            dateRange.start.month,
            dateRange.start.day,
            0,
            0,
            0,
          );
          dateEnd = DateTime(
            dateRange.end.year,
            dateRange.end.month,
            dateRange.end.day,
            23,
            59,
            59,
          );
        }
      }
    }

    // Mettre à jour l'état de chargement
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        if (refresh) {
          _isInitialLoading = true;
        }
      });
    }

    try {
      final page = refresh ? 0 : _currentPage;

      log('Loading logs - page: $page, userId: ${_selectedUser?.id}, dateStart: $dateStart, dateEnd: $dateEnd');

      final newLogs = await _logService.getLogs(
        page: page,
        userId: _selectedUser?.id,
        dateStart: dateStart,
        dateEnd: dateEnd,
      );

      log('Loaded ${newLogs.length} logs, refresh: $refresh');

      if (mounted) {
        setState(() {
          if (refresh) {
            _logs = newLogs;
          } else {
            _logs.addAll(newLogs);
          }
          _hasMore = newLogs.length == 20; // 20 logs par page
          _currentPage = page + 1;
          _isLoading = false;
          _isInitialLoading = false;
        });

        log('After setState: logs count: ${_logs.length}, hasMore: $_hasMore');
      }
    } catch (e) {
      log('Error loading logs: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreLogs() async {
    await _loadLogs(refresh: false);
  }

  Future<void> _onRefresh() async {
    await _loadLogs(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width > 800;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1E49)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          localizations.translate('activity_history_title'),
          style: const TextStyle(
            color: Color(0xFF1A1E49),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: _hasActiveFilters()
                      ? const Color(0xFF1A1E49)
                      : Colors.grey[400],
                ),
                onPressed: () => _showFilterBottomSheet(context),
              ),
              if (_hasActiveFilters())
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_hasActiveFilters()) _buildActiveFiltersBar(localizations)!,
          Expanded(
            child: _isCheckingAdmin || _isInitialLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1A1E49),
                    ),
                  )
                : _errorMessage != null && _logs.isEmpty
                    ? _buildErrorState(localizations)
                    : _logs.isEmpty
                        ? _buildEmptyState(localizations)
                        : RefreshIndicator(
                            onRefresh: _onRefresh,
                            color: const Color(0xFF1A1E49),
                            child: _logs.isEmpty && _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF1A1E49),
                                    ),
                                  )
                                : CustomScrollView(
                                    key: ValueKey(
                                      'logs_${_selectedUser?.id}_${_selectedDateOption}_${_customDate?.toString()}_${_logs.length}',
                                    ),
                                    controller: _scrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    slivers: [
                                      SliverPadding(
                                        padding: EdgeInsets.all(
                                            isTablet ? 24.0 : 16.0),
                                        sliver: SliverList(
                                          delegate: SliverChildBuilderDelegate(
                                            (context, index) {
                                              if (index < _logs.length) {
                                                return ActivityLogItem(
                                                  key: ValueKey(
                                                      'log_${_logs[index].id}_$index'),
                                                  log: _logs[index],
                                                );
                                              } else if (_hasMore) {
                                                return const Padding(
                                                  padding: EdgeInsets.all(16.0),
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Color(0xFF1A1E49),
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                return const SizedBox.shrink();
                                              }
                                            },
                                            childCount: _logs.length +
                                                (_hasMore ? 1 : 0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('activity_history_error'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? localizations.translate('network_error'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadLogs(refresh: true),
              icon: const Icon(Icons.refresh),
              label: Text(localizations.translate('try_again')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1E49),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('activity_history_empty'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('activity_history_empty_desc'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    localizations.translate('filter'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1E49),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtre utilisateur
                  Text(
                    localizations.translate('activity_history_user'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1E49),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildUserFilter(localizations),
                  const SizedBox(height: 24),
                  // Filtre date
                  Text(
                    localizations.translate('filter_by_date'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1E49),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Options de date prédéfinies
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDateOptionChip(
                        context,
                        DateFilterOption.all,
                        localizations,
                      ),
                      _buildDateOptionChip(
                        context,
                        DateFilterOption.today,
                        localizations,
                      ),
                      _buildDateOptionChip(
                        context,
                        DateFilterOption.yesterday,
                        localizations,
                      ),
                      _buildDateOptionChip(
                        context,
                        DateFilterOption.thisWeek,
                        localizations,
                      ),
                      _buildDateOptionChip(
                        context,
                        DateFilterOption.customDate,
                        localizations,
                      ),
                    ],
                  ),
                  // Sélecteur de date personnalisé
                  if (_selectedDateOption == DateFilterOption.customDate) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectCustomDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _customDate != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(_customDate!)
                                    : localizations
                                        .translate('filter_date_custom'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _customDate != null
                                      ? Colors.black87
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedUser = null;
                              _selectedDateOption = DateFilterOption.all;
                              _customDate = null;
                            });
                            Navigator.of(context).pop();
                            _loadLogs(refresh: true);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            localizations.translate('clear_filters'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                            _loadLogs(refresh: true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1E49),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            localizations.translate('apply_filters'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateOptionChip(
    BuildContext context,
    DateFilterOption option,
    AppLocalizations localizations,
  ) {
    final isSelected = _selectedDateOption == option;
    return FilterChip(
      label: Text(option.getDisplayName(localizations)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          final shouldCloseSheet = option != DateFilterOption.customDate;

          setState(() {
            _selectedDateOption = option;
            if (option != DateFilterOption.customDate) {
              _customDate = null;
            }
          });

          // Appliquer automatiquement le filtre si ce n'est pas une date personnalisée
          if (shouldCloseSheet) {
            // Fermer le bottom sheet d'abord
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            // Puis charger les logs après un court délai pour laisser le sheet se fermer
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                _loadLogs(refresh: true);
              }
            });
          }
        }
      },
      selectedColor: const Color(0xFF1A1E49).withOpacity(0.2),
      checkmarkColor: const Color(0xFF1A1E49),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1A1E49) : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF1A1E49) : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Future<void> _selectCustomDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _customDate = picked;
        _selectedDateOption = DateFilterOption.customDate;
      });

      // Fermer le bottom sheet
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Appliquer automatiquement le filtre après sélection de la date
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _loadLogs(refresh: true);
        }
      });
    }
  }

  Widget _buildUserFilter(AppLocalizations localizations) {
    final allUsersOption = localizations.translate('filter_all_users');
    final userOptions = [
      allUsersOption,
      ..._allUsers.map((u) => _getUserDisplayName(u))
    ];
    final selectedValue = _selectedUser == null
        ? allUsersOption
        : _getUserDisplayName(_selectedUser!);

    return CustomDropdown<String>.search(
      hintText: allUsersOption,
      initialItem: selectedValue,
      decoration: CustomDropdownDecoration(
        prefixIcon: const Icon(Icons.person),
        closedBorder: Border.all(color: Colors.grey[300]!),
        expandedBorder: Border.all(color: Colors.grey[300]!),
        closedFillColor: Colors.white,
        expandedFillColor: Colors.white,
        closedSuffixIcon: const Icon(Icons.keyboard_arrow_down),
        expandedSuffixIcon: const Icon(Icons.keyboard_arrow_up),
      ),
      noResultFoundText: localizations.translate('no_data'),
      searchHintText: localizations.translate('search'),
      items: userOptions,
      onChanged: (value) {
        setState(() {
          if (value == allUsersOption) {
            _selectedUser = null;
          } else {
            _selectedUser = _allUsers.firstWhere(
              (user) => _getUserDisplayName(user) == value,
            );
          }
        });

        // Fermer le bottom sheet
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Appliquer automatiquement le filtre utilisateur
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _loadLogs(refresh: true);
          }
        });
      },
    );
  }

  String _getUserDisplayName(User user) {
    if (user.firstName != null && user.lastName != null) {
      return '${user.firstName} ${user.lastName}';
    } else if (user.firstName != null) {
      return user.firstName!;
    } else if (user.lastName != null) {
      return user.lastName!;
    } else {
      return user.username;
    }
  }
}
