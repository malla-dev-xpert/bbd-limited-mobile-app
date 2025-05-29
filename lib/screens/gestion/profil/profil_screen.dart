import 'dart:developer';

import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/privacy_policy_dialog.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/models/user.dart';
import 'package:bbd_limited/screens/gestion/profil/widgets/change_password_bottom_sheet.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  User? _user;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = await _authService.getUserInfo();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mon Profil'),
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

  Widget _buildProfileHeader(BuildContext context) {
    if (_user == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
          "${_user?.firstName ?? ''} ${_user?.lastName ?? ''}",
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          _user?.email ?? '',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 15),
        OutlinedButton.icon(
          onPressed: () {
            // Action pour modifier le profil
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Modifier le profil'),
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
            title: 'Informations personnelles',
            subtitle: 'Modifier vos coordonnées',
            onTap: () {
              _navigateToEditProfile(context);
            },
          ),
          const Divider(height: 1, indent: 20),
          _buildOptionTile(
            context,
            icon: Icons.lock_outline,
            title: 'Mot de passe',
            subtitle: 'Changer votre mot de passe',
            onTap: () {
              _showChangePasswordModal(context);
            },
          ),
          const Divider(height: 1, indent: 20),
          _buildOptionTile(
            context,
            icon: Icons.flag_outlined,
            title: 'Langues',
            subtitle: 'Changer la langue',
            onTap: () {
              _navigateToDeliveryPreferences(context);
            },
          ),
          const Divider(height: 1, indent: 20),
          _buildOptionTile(
            context,
            icon: Icons.policy_outlined,
            title: 'Politique de confidentialité',
            subtitle: 'Consulter la politique de confidentialité',
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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          _showLogoutConfirmation(context);
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.red[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Déconnexion',
          style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    // Navigation vers l'édition du profil
  }

  void _showChangePasswordModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChangePasswordBottomSheet(),
    );
  }

  void _navigateToDeliveryPreferences(BuildContext context) {
    // Navigation vers les préférences de livraison
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PrivacyPolicyDialog(),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
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
              isLoading == true ? 'Déconnexion en cours...' : 'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
