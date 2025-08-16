import 'package:flutter/material.dart';
import 'package:bbd_limited/models/user.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/confirm_btn.dart';

class UserDetailsBottomSheet extends StatefulWidget {
  final User user;
  final VoidCallback? onUserDisabled;
  final bool isCurrentUser;

  const UserDetailsBottomSheet({
    Key? key,
    required this.user,
    this.onUserDisabled,
    this.isCurrentUser = false,
  }) : super(key: key);

  @override
  State<UserDetailsBottomSheet> createState() => _UserDetailsBottomSheetState();
}

class _UserDetailsBottomSheetState extends State<UserDetailsBottomSheet> {
  final AuthService _authService = AuthService();
  bool _isDisabling = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? MediaQuery.of(context).viewInsets.bottom
            : 0,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec avatar et nom
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.user.firstName ?? ''} ${widget.user.lastName ?? ''}'
                                  .trim()
                                  .isEmpty
                              ? widget.user.username
                              : '${widget.user.firstName ?? ''} ${widget.user.lastName ?? ''}'
                                  .trim(),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${widget.user.username}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Informations détaillées
              _buildInfoSection('Informations personnelles', [
                _buildInfoRow('Nom d\'utilisateur', widget.user.username,
                    Icons.person_outline),
                if (widget.user.firstName != null &&
                    widget.user.firstName!.isNotEmpty)
                  _buildInfoRow('Prénom', widget.user.firstName!, Icons.person),
                if (widget.user.lastName != null &&
                    widget.user.lastName!.isNotEmpty)
                  _buildInfoRow('Nom', widget.user.lastName!, Icons.person),
                if (widget.user.email != null && widget.user.email!.isNotEmpty)
                  _buildInfoRow('Email', widget.user.email!, Icons.email),
                if (widget.user.phoneNumber != null &&
                    widget.user.phoneNumber!.isNotEmpty)
                  _buildInfoRow(
                      'Téléphone', widget.user.phoneNumber!, Icons.phone),
                _buildInfoRow('Rôle', widget.user.roleName ?? 'Non défini',
                    Icons.assignment_ind),
              ]),

              const SizedBox(height: 24),

              // Bouton de désactivation
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      widget.isCurrentUser ? Colors.grey[100] : Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: widget.isCurrentUser
                          ? Colors.grey[300]!
                          : Colors.red[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.isCurrentUser
                                ? Icons.info_outline
                                : Icons.warning_amber_rounded,
                            color: widget.isCurrentUser
                                ? Colors.grey[600]
                                : Colors.red[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isCurrentUser
                                ? 'Actions non disponibles'
                                : 'Actions dangereuses',
                            style: TextStyle(
                              color: widget.isCurrentUser
                                  ? Colors.grey[600]
                                  : Colors.red[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.isCurrentUser
                            ? 'Vous ne pouvez pas désactiver votre propre compte depuis cette interface.'
                            : 'La désactivation de ce compte empêchera l\'utilisateur de se connecter à l\'application.',
                        style: TextStyle(
                          color: widget.isCurrentUser
                              ? Colors.grey[700]
                              : Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                      if (!widget.isCurrentUser) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: Colors.red[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            icon: _isDisabling
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.block, color: Colors.white),
                            label: Text(
                              _isDisabling
                                  ? "Désactivation..."
                                  : "Désactiver le compte",
                              style: const TextStyle(color: Colors.white),
                            ),
                            onPressed:
                                _isDisabling ? null : _showDisableConfirmation,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDisableConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Confirmer la désactivation'),
            ],
          ),
          content: Text(
            'Êtes-vous sûr de vouloir désactiver le compte de ${widget.user.firstName ?? widget.user.username} ?\n\nCette action empêchera l\'utilisateur de se connecter à l\'application.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _disableUser();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Désactiver'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _disableUser() async {
    setState(() {
      _isDisabling = true;
    });

    try {
      final result = await _authService.disableUser(widget.user.id);

      if (mounted) {
        switch (result) {
          case 'SUCCESS':
            showSuccessTopSnackBar(
              context,
              'Compte désactivé avec succès',
            );
            widget.onUserDisabled?.call();
            Navigator.pop(context);
            break;
          case 'USER_NOT_FOUND':
            showErrorTopSnackBar(
              context,
              'Utilisateur non trouvé',
            );
            break;
          case 'PERMISSION_DENIED':
            showErrorTopSnackBar(
              context,
              'Vous n\'avez pas les permissions pour effectuer cette action',
            );
            break;
          case 'INVALID_INPUT':
            showErrorTopSnackBar(
              context,
              'Données invalides',
            );
            break;
          default:
            showErrorTopSnackBar(
              context,
              'Erreur lors de la désactivation du compte',
            );
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          'Erreur de connexion: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDisabling = false;
        });
      }
    }
  }
}
