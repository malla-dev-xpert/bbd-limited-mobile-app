import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/log_service.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/models/activity_log.dart';
import 'package:bbd_limited/models/user.dart';
import 'package:bbd_limited/components/activity_log_item.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

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

  bool get isAdmin {
    final permissions = _user?.role?.permissions ?? [];
    return permissions.contains('IS_ADMIN');
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

        // Si admin, charger les logs
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

  Future<void> _loadLogs({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (refresh) {
        _currentPage = 0;
        _hasMore = true;
        _isInitialLoading = true;
      }
    });

    try {
      final page = refresh ? 0 : _currentPage;
      final newLogs = await _logService.getLogs(page: page);

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
      }
    } catch (e) {
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
      ),
      body: _isCheckingAdmin || _isInitialLoading
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
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index < _logs.length) {
                                    return ActivityLogItem(log: _logs[index]);
                                  } else if (_hasMore) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF1A1E49),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                                childCount: _logs.length + (_hasMore ? 1 : 0),
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
