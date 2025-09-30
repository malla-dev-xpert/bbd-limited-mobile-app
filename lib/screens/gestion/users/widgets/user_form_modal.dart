import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bbd_limited/models/user.dart';
import 'package:bbd_limited/models/branch.dart';
import 'package:bbd_limited/core/services/role_services.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/utils/password_generator.dart';

class UserFormModal extends StatefulWidget {
  final User? user;
  final Function(User) onSubmit;

  const UserFormModal({Key? key, this.user, required this.onSubmit})
      : super(key: key);

  @override
  State<UserFormModal> createState() => _UserFormModalState();
}

class _UserFormModalState extends State<UserFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _roleServices = RoleServices();

  Role? _selectedRole;
  Branch? _selectedBranch;
  List<Role> _roles = [];
  List<Branch> _branches = [];
  bool _isLoading = true;
  bool _obscurePassword = true;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadRoles();
    _loadBranches();
    if (widget.user != null) {
      _usernameController.text = widget.user!.username;
      _firstNameController.text = widget.user!.firstName ?? '';
      _lastNameController.text = widget.user!.lastName ?? '';
      _emailController.text = widget.user!.email ?? '';
      _phoneController.text = widget.user!.phoneNumber ?? '';
    }
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await _roleServices.getAllRoles();
      setState(() {
        _roles = roles;
        if (widget.user != null && widget.user!.roleName != null) {
          _selectedRole = _roles.firstWhere(
            (role) => role.name == widget.user!.roleName,
            orElse: () => _roles.first,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des rôles: $e')),
      );
    }
  }

  void _loadBranches() {
    setState(() {
      _branches = Branch.getAllBranches();
      _isLoading = false;
      if (widget.user != null && widget.user!.branchName != null) {
        try {
          _selectedBranch = Branch.fromName(widget.user!.branchName!);
        } catch (e) {
          // Si le nom de branche n'est pas trouvé, utiliser la première branche
          _selectedBranch = _branches.first;
        }
      }
    });
  }

  void _generatePassword() {
    final password = PasswordGenerator.generateSimplePassword(length: 10);
    setState(() {
      _passwordController.text = password;
    });
  }

  void _copyPassword() {
    if (_passwordController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _passwordController.text));
      showSuccessTopSnackBar(
          context, 'Mot de passe copié dans le presse-papiers');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('form_errors'),
      );
      return;
    }

    if (_selectedRole == null) {
      showErrorTopSnackBar(context,
          AppLocalizations.of(context).translate('please_select_role'));
      return;
    }

    if (_selectedBranch == null) {
      showErrorTopSnackBar(context,
          AppLocalizations.of(context).translate('please_select_country'));
      return;
    }

    if (_selectedBranch!.code.isEmpty) {
      showErrorTopSnackBar(context, 'Erreur: Code de branche invalide');
      return;
    }

    // Vérifier que le mot de passe est fourni pour un nouvel utilisateur
    if (widget.user == null && _passwordController.text.isEmpty) {
      showErrorTopSnackBar(context,
          AppLocalizations.of(context).translate('please_enter_password'));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Debug: Afficher le code de branche sélectionné
      print('Selected branch code: ${_selectedBranch!.code}');
      print('Selected branch name: ${_selectedBranch!.name}');

      final user = widget.user == null
          ? User(
              id: 0,
              username: _usernameController.text,
              firstName: _firstNameController.text,
              lastName: _lastNameController.text,
              email: _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
              phoneNumber: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
              roleName: _selectedRole!.name,
              password: _passwordController.text, // 👈 Ajouté pour la création
              branchName: _selectedBranch!.code, // 👈 Ajouté pour le pays
            )
          : widget.user!.copyWith(
              username: _usernameController.text,
              firstName: _firstNameController.text,
              lastName: _lastNameController.text,
              email: _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
              phoneNumber: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
              roleName: _selectedRole!.name,
              branchName: _selectedBranch!.code, // 👈 Ajouté pour le pays
            );

      await widget.onSubmit(user);

      if (mounted) {
        showSuccessTopSnackBar(
          context,
          widget.user == null
              ? AppLocalizations.of(context).translate('user_created_success')
              : AppLocalizations.of(context).translate('user_updated_success'),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(context,
            '${AppLocalizations.of(context).translate('error')}: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToNextStep() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 1);
      }
    } else {
      _submitForm();
    }
  }

  void _goToPreviousStep() {
    setState(() => _currentStep = 0);
  }

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
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.user == null
                          ? AppLocalizations.of(context)
                              .translate('user_form_create_title')
                          : AppLocalizations.of(context)
                              .translate('user_form_edit_title'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_currentStep == 0) ...[
                  buildTextField(
                    controller: _usernameController,
                    label: AppLocalizations.of(context)
                        .translate('user_form_username_label'),
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context).translate(
                            'user_form_validation_username_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    controller: _firstNameController,
                    label: AppLocalizations.of(context)
                        .translate('user_form_first_name_label'),
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context).translate(
                            'user_form_validation_first_name_required');
                      }
                      if (value.length < 2) {
                        return AppLocalizations.of(context).translate(
                            'user_form_validation_first_name_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    controller: _lastNameController,
                    label: AppLocalizations.of(context)
                        .translate('user_form_last_name_label'),
                    icon: Icons.person_outline,
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Veuillez entrer un nom';
                    //   }
                    //   if (value.length < 2) {
                    //     return 'Le nom doit contenir au moins 2 caractères';
                    //   }
                    //   return null;
                    // },
                  ),
                ] else ...[
                  // Champ mot de passe avec génération et copie
                  if (widget.user == null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .translate('user_form_password_label'),
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Colors.black),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.refresh,
                                        color: Colors.black),
                                    onPressed: _generatePassword,
                                    tooltip: AppLocalizations.of(context)
                                        .translate(
                                            'user_form_generate_password'),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.black,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy,
                                        color: Colors.black),
                                    onPressed: _copyPassword,
                                    tooltip: AppLocalizations.of(context)
                                        .translate('user_form_copy_password'),
                                  ),
                                ],
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context).translate(
                                    'user_form_validation_password_required');
                              }
                              if (value.length < 6) {
                                return AppLocalizations.of(context).translate(
                                    'user_form_validation_password_min_length');
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  buildTextField(
                    controller: _emailController,
                    label: AppLocalizations.of(context)
                        .translate('user_form_email_label'),
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (!emailRegex.hasMatch(value)) {
                          return AppLocalizations.of(context)
                              .translate('user_form_validation_email_invalid');
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    controller: _phoneController,
                    label: AppLocalizations.of(context)
                        .translate('user_form_phone_label'),
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropDownCustom<Branch>(
                    items: _branches,
                    selectedItem: _selectedBranch,
                    onChanged: (Branch? value) {
                      setState(() {
                        _selectedBranch = value;
                      });
                    },
                    itemToString: (branch) => branch.toString(),
                    hintText: AppLocalizations.of(context)
                        .translate('user_form_country_hint'),
                    prefixIcon: Icons.public,
                    labelText: AppLocalizations.of(context)
                        .translate('user_form_country_label'),
                  ),
                  const SizedBox(height: 16),
                  DropDownCustom<Role>(
                    items: _roles,
                    selectedItem: _selectedRole,
                    onChanged: (Role? value) {
                      setState(() {
                        _selectedRole = value;
                      });
                    },
                    itemToString: (role) => role.name,
                    hintText: AppLocalizations.of(context)
                        .translate('user_form_role_hint'),
                    prefixIcon: Icons.assignment_ind,
                  ),
                ],
                const SizedBox(height: 24),
                if (_currentStep == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: confirmationButton(
                      isLoading: false,
                      label: AppLocalizations.of(context).translate('next'),
                      onPressed: _goToNextStep,
                      icon: Icons.arrow_forward_ios,
                      subLabel:
                          AppLocalizations.of(context).translate('loading'),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _goToPreviousStep,
                            label: Text(
                                AppLocalizations.of(context).translate('back')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: confirmationButton(
                            isLoading: _isLoading,
                            label: widget.user == null
                                ? AppLocalizations.of(context)
                                    .translate('user_form_save')
                                : AppLocalizations.of(context)
                                    .translate('user_form_save'),
                            subLabel: AppLocalizations.of(context)
                                .translate('user_form_saving'),
                            icon: Icons.check,
                            onPressed: _submitForm,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
