import 'dart:developer';

import 'package:bbd_limited/components/personal_info_card.dart';
import 'package:bbd_limited/components/privacy_policy_bottom_sheet.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/models/user.dart';
import 'package:bbd_limited/screens/gestion/profil/widgets/change_password_bottom_sheet.dart';
import 'package:bbd_limited/screens/gestion/profil/widgets/language_selection_modal.dart';
import 'package:bbd_limited/screens/gestion/users/widgets/user_form_modal.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  bool isLoading = false;
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(localizations.translate('my_profile')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.grey[50],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 30),
            _buildProfileOptions(context),
            const SizedBox(height: 40),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
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
              setState(() {
                isLoading = true;
              });

              final success = await _authService.updateUser(
                updatedUser.id,
                updatedUser,
              );

              if (success) {
                // Mettre à jour l'utilisateur local
                setState(() {
                  _currentUser = updatedUser;
                });

                // Afficher message de succès
                showSuccessTopSnackBar(
                  context,
                  AppLocalizations.of(context)
                      .translate('profile_updated_successfully'),
                );

                return true;
              } else {
                showErrorTopSnackBar(
                  context,
                  AppLocalizations.of(context).translate('error_updating_user'),
                );
                return false;
              }
            } catch (e) {
              log('Erreur lors de la mise à jour du profil: $e');
              showErrorTopSnackBar(
                context,
                AppLocalizations.of(context).translate('error_updating_user'),
              );
              return false;
            } finally {
              setState(() {
                isLoading = false;
              });
            }
          },
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).primaryColor, width: 3),
          ),
          child: ClipOval(
            child: Material(
              color: Colors.grey[200],
              child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "${_currentUser.firstName ?? ''} ${_currentUser.lastName ?? ''}",
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          _currentUser.email ?? '',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 15),
        OutlinedButton.icon(
          onPressed: isLoading
              ? null
              : () {
                  _showEditUserModal(context, _currentUser);
                },
          icon: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                )
              : const Icon(Icons.edit, size: 18),
          label: isLoading
              ? Text(localizations.translate('updating'))
              : Text(localizations.translate('edit_profile')),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOptions(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildOptionTile(
            context,
            icon: Icons.person_outline,
            title: localizations.translate('personal_info'),
            subtitle: localizations.translate('personal_info_subtitle'),
            onTap: () {
              _showProfileDetails(context);
            },
          ),
          const Divider(height: 1, indent: 20),
          _buildOptionTile(
            context,
            icon: Icons.lock_outline,
            title: localizations.translate('change_password'),
            subtitle: localizations.translate('change_password_subtitle'),
            onTap: () {
              _showChangePasswordModal(context);
            },
          ),
          const Divider(height: 1, indent: 20),
          _buildOptionTile(
            context,
            icon: Icons.flag_outlined,
            title: localizations.translate('language'),
            subtitle: localizations.translate('language_subtitle'),
            onTap: () {
              _showLanguageSelectionModal(context);
            },
          ),
          const Divider(height: 1, indent: 20),
          _buildOptionTile(
            context,
            icon: Icons.policy_outlined,
            title: localizations.translate('privacy_policy'),
            subtitle: localizations.translate('privacy_policy_subtitle'),
            onTap: () {
              _showPrivacyPolicyDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading
            ? null
            : () {
                _showLogoutConfirmation(context);
              },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.red[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              )
            : Text(
                localizations.translate('logout'),
                style: TextStyle(
                    color: Colors.red[400], fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _showProfileDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        height: MediaQuery.of(context).size.height * 0.45,
        child: PersonalInfoCard(user: _currentUser),
      ),
    );
  }

  void _showChangePasswordModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChangePasswordBottomSheet(),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        child: const PrivacyPolicyBottomSheet(),
      ),
    );
  }

  void _showLanguageSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LanguageSelectionModal(),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('logout')),
        content: Text(localizations.translate('logout_confirmation')),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                isLoading = true;
              });
              try {
                final user = await _authService.logout();
                if (user == null) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/login');
                  return;
                }
              } catch (e) {
                log('Erreur lors de la déconnexion: $e');
              } finally {
                setState(() {
                  isLoading = false;
                });
              }
            },
            child: Text(
              localizations.translate('logout'),
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
