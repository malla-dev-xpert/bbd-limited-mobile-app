import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/container_info_form.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';

class EditContainerModal extends StatefulWidget {
  final Containers container;
  final Function() onContainerUpdated;

  const EditContainerModal({
    super.key,
    required this.container,
    required this.onContainerUpdated,
  });

  @override
  State<EditContainerModal> createState() => _EditContainerModalState();
}

class _EditContainerModalState extends State<EditContainerModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _refController;
  late final TextEditingController _sizeController;

  final _infoFormKey = GlobalKey<ContainerInfoFormState>();

  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final ContainerServices _containerServices = ContainerServices();

  @override
  void initState() {
    super.initState();
    _refController = TextEditingController(text: widget.container.reference);
    _sizeController = TextEditingController(text: widget.container.size);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = await _authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context, "Erreur: Utilisateur non connecté");
        return;
      }

      final isAvailable = _infoFormKey.currentState?.isAvailable ?? false;

      final updatedContainer = widget.container.copyWith(
        reference: _refController.text,
        size: _sizeController.text,
        isAvailable: isAvailable,
      );

      final success = await _containerServices.update(
        widget.container.id!,
        user.id,
        updatedContainer,
      );

      if (success == "UPDATED") {
        widget.onContainerUpdated();
        if (mounted) {
          Navigator.pop(context);
          showSuccessTopSnackBar(context, "Conteneur modifié avec succès !");
        }
      } else if (success == "REF_EXIST") {
        showErrorTopSnackBar(context, "Le conteneur existe déjà !");
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          "Erreur lors de la modification: ${e.toString()}",
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Modifier le conteneur",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ContainerInfoForm(
                key: _infoFormKey,
                refController: _refController,
                size: _sizeController,
                initialAvailability: widget.container.isAvailable ?? false,
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: confirmationButton(
                  isLoading: _isLoading,
                  onPressed: _submitForm,
                  label: "Enregistrer les modifications",
                  icon: Icons.edit_document,
                  subLabel: "Modification...",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refController.dispose();
    super.dispose();
  }
}
