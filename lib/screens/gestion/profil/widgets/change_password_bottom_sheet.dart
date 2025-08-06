import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

class ChangePasswordBottomSheet extends StatefulWidget {
  const ChangePasswordBottomSheet({super.key});

  @override
  State<ChangePasswordBottomSheet> createState() =>
      _ChangePasswordBottomSheetState();
}

class _ChangePasswordBottomSheetState extends State<ChangePasswordBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final localizations = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) return;

    // Vérifier que les mots de passe correspondent
    if (_newPasswordController.text != _confirmPasswordController.text) {
      showErrorTopSnackBar(
          context, localizations.translate('passwords_dont_match'));
      return;
    }

    setState(() => _isLoading = true);
    final currentContext = context;

    try {
      final result = await _authService.changePassword(
        oldPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (result == "PASSWORD_EDITED") {
        if (mounted) {
          Navigator.pop(currentContext);

          await showDialog(
            context: currentContext,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  Icon(Icons.security, color: Colors.green[400]),
                  const SizedBox(width: 8),
                  Text(localizations.translate('security_enhanced')),
                ],
              ),
              content: Text(
                localizations.translate('security_logout_message'),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _authService.logout();
                    if (mounted) {
                      Navigator.of(currentContext).pop();
                      Navigator.pushNamedAndRemoveUntil(
                        currentContext,
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                  child: Text(localizations.translate('understood')),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          showErrorTopSnackBar(currentContext,
              localizations.translate('error_changing_password'));
        }
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('Ancien mot de passe incorrect')) {
          showErrorTopSnackBar(currentContext,
              localizations.translate('old_password_incorrect'));
        } else {
          showErrorTopSnackBar(currentContext, e.toString());
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.translate('change_password_title'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: localizations.translate('current_password'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(
                    Icons.lock,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations
                        .translate('please_enter_current_password');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: localizations.translate('new_password'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(
                    Icons.lock,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.translate('please_enter_new_password');
                  }
                  if (value.length < 6) {
                    return localizations.translate('password_too_short');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: localizations.translate('confirm_new_password'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(
                    Icons.lock,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations
                        .translate('please_confirm_new_password');
                  }
                  if (value != _newPasswordController.text) {
                    return localizations.translate('passwords_dont_match');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 50),
              confirmationButton(
                isLoading: _isLoading,
                onPressed: _changePassword,
                label: localizations.translate('change_password_button'),
                icon: Icons.lock_outline,
                subLabel: localizations.translate('changing_password'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
