import 'dart:async';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/models/user.dart';
import 'package:bbd_limited/screens/gestion/users/widgets/user_form_modal.dart';
import 'package:bbd_limited/screens/gestion/users/widgets/user_details_bottom_sheet.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ManageUsersScreen extends StatefulWidget {
  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController searchController = TextEditingController();
  final AuthService _authService = AuthService();
  Timer? _debounce;

  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  String? _currentFilter;
  User? _currentUser;

  bool _isLoading = false;
  bool _hasMoreData = true;
  int currentPage = 0;

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    fetchUsers();
    _refreshController.stream.listen((_) {
      fetchUsers(reset: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _refreshController.close();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('error_loading_user'),
        );
        return;
      }
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context)
            .translate('error_loading_current_user')
            .replaceAll('{error}', e.toString()),
      );
    }
  }

  Future<void> fetchUsers({bool reset = false}) async {
    if (_isLoading || (!reset && !_hasMoreData)) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        currentPage = 0;
        _hasMoreData = true;
        _allUsers = [];
        _loadCurrentUser();
      }
    });

    try {
      final users = await _authService.getAllUsers(page: currentPage);

      setState(() {
        _allUsers.addAll(users
            .where((user) => user.email != "admin@bbdproject.com")
            .toList());
        _filteredUsers = List.from(_allUsers);
        _applyFilters();

        if (users.isEmpty || users.length < 30) {
          _hasMoreData = false;
        } else {
          currentPage++;
        }
      });
    } catch (e) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context)
            .translate('error_fetching_users')
            .replaceAll('{error}', e.toString()),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final searchUser = user.username.toLowerCase().contains(query) ||
            (user.firstName?.toLowerCase().contains(query) ?? false) ||
            (user.lastName?.toLowerCase().contains(query) ?? false);

        bool allStatus = true;
        if (_currentFilter == 'administrateur') {
          allStatus = user.roleName?.toLowerCase() == 'administrateur';
        }

        return searchUser && allStatus;
      }).toList();
    });
  }

  void filterUsers(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  void handleStatusFilter(String value) {
    setState(() {
      _currentFilter = value;
    });
    _applyFilters();
  }

  Future<void> _openNewUserBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return UserFormModal(
          onSubmit: (user) async {
            try {
              final response = await _authService.createUser(user);
              if (response == AuthService.success) {
                return true;
              } else {
                showErrorTopSnackBar(
                  context,
                  _authService.getResponseMessage(response),
                );
                return false;
              }
            } catch (e) {
              showErrorTopSnackBar(
                context,
                AppLocalizations.of(context).translate('error_creating_user'),
              );
              return false;
            }
          },
        );
      },
    );

    if (result == true) {
      fetchUsers(reset: true);
    }
  }

  void _showEditUserModal(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return UserFormModal(
          user: user,
          onSubmit: (updatedUser) async {
            try {
              final success = await _authService.updateUser(
                updatedUser.id,
                updatedUser,
              );
              if (success) {
                return true;
              } else {
                showErrorTopSnackBar(
                  context,
                  AppLocalizations.of(context).translate('error_updating_user'),
                );
                return false;
              }
            } catch (e) {
              showErrorTopSnackBar(
                context,
                AppLocalizations.of(context).translate('error_updating_user'),
              );
              return false;
            }
          },
        );
      },
    ).then((result) {
      if (result == true) {
        fetchUsers(reset: true);
      }
    });
  }

  Future<void> _delete(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            AppLocalizations.of(context).translate('confirm_user_deletion')),
        content: Text(
          AppLocalizations.of(context)
              .translate('confirm_user_deletion_message')
              .replaceAll('{username}', user.username),
        ),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete, color: Colors.red),
            label: Text(
              _isLoading
                  ? AppLocalizations.of(context).translate('deleting')
                  : AppLocalizations.of(context).translate('delete'),
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });
      final success = await _authService.deleteUser(user.id, _currentUser!);
      if (success) {
        showSuccessTopSnackBar(context,
            AppLocalizations.of(context).translate('user_deleted_success'));
        // Navigator.pop(context, true);
        setState(() {
          _allUsers.removeWhere((d) => d.id == user.id);
          _filteredUsers.removeWhere((d) => d.id == user.id);
        });
      }
    } catch (e) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context)
            .translate('error_deleting_user')
            .replaceAll('{error}', e.toString()),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showUserDetails(User user) async {
    final bool isCurrentUser =
        _currentUser != null && _currentUser!.id == user.id;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return UserDetailsBottomSheet(
          user: user,
          isCurrentUser: isCurrentUser,
          onUserDisabled: () {
            // Rafraîchir la liste après désactivation
            fetchUsers(reset: true);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1E49),
        onPressed: () => _openNewUserBottomSheet(context),
        heroTag: 'users_fab',
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text(
              AppLocalizations.of(context).translate('user_management_title'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 10),

            // Stats Cards
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.blue.withOpacity(0.5)),
                      ),
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _StatItem(
                          title: AppLocalizations.of(context)
                              .translate('user_stats_total'),
                          value: _allUsers.length.toString(),
                          valueStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1E49),
                          ),
                          icon: Icons.people,
                          iconColor: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.purple.withOpacity(0.5)),
                      ),
                      color: Colors.purple[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _StatItem(
                          title: AppLocalizations.of(context)
                              .translate('user_stats_administrators'),
                          value: _allUsers
                              .where((u) => u.roleName == 'ADMINISTRATEUR')
                              .length
                              .toString(),
                          valueStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1E49),
                          ),
                          icon: Icons.admin_panel_settings,
                          iconColor: Colors.purple,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Search and Filter Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)
                      .translate('user_search_hint'),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: filterUsers,
              ),
            ),
            // Users List
            Expanded(
              child: _isLoading && _allUsers.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1A1E49),
                        strokeWidth: 3,
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo.metrics.pixels ==
                                scrollInfo.metrics.maxScrollExtent &&
                            !_isLoading &&
                            _hasMoreData) {
                          fetchUsers();
                        }
                        return false;
                      },
                      child: _filteredUsers.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: () async {
                                await fetchUsers(reset: true);
                              },
                              // displacement: 20,
                              color: Theme.of(context).primaryColor,
                              backgroundColor: Colors.white,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _filteredUsers.length +
                                    (_hasMoreData && _isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _filteredUsers.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  return _buildUserCard(
                                    _filteredUsers[index],
                                  );
                                },
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final bool isCurrentUser =
        _currentUser != null && _currentUser!.id == user.id;

    // Détecter si on est sur mobile ou tablette
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Slidable(
      key: ValueKey(user.id),
      endActionPane: isCurrentUser
          ? null
          : ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) => _showEditUserModal(context, user),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                  label: AppLocalizations.of(context).translate('edit'),
                ),
                SlidableAction(
                  onPressed: (_) => _delete(user),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: AppLocalizations.of(context).translate('delete'),
                ),
              ],
            ),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          dense: true,
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
                child: Text(
                  (user.firstName?.isNotEmpty == true
                          ? user.firstName!
                          : user.username)
                      .substring(0, 1)
                      .toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isCurrentUser)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).translate('user_login_id'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      user.username,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).translate('user_full_name'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${user.firstName ?? ''} ${user.lastName ?? ''}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (isMobile) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    user.roleName ??
                        AppLocalizations.of(context)
                            .translate('role_not_defined'),
                    style: TextStyle(color: Colors.blue[600], fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
          subtitle: isMobile
              ? null
              : Text(
                  '${user.firstName ?? ''} ${user.lastName ?? ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: isMobile
              ? Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 16,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        user.roleName ??
                            AppLocalizations.of(context)
                                .translate('user_role_undefined'),
                        style: TextStyle(color: Colors.blue[600], fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).translate('no_users_found'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).translate('no_users_message'),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final TextStyle valueStyle;
  final IconData icon;
  final Color iconColor;

  const _StatItem({
    required this.title,
    required this.value,
    required this.valueStyle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(value, style: valueStyle),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
