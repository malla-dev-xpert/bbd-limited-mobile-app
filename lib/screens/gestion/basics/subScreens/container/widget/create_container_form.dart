import 'package:flutter/material.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/container_info_form.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart'; // <-- à créer
import 'package:bbd_limited/utils/snackbar_utils.dart';

class CreateContainerForm extends StatefulWidget {
  const CreateContainerForm({super.key});

  @override
  State<CreateContainerForm> createState() => _CreateContainerFormState();
}

class _CreateContainerFormState extends State<CreateContainerForm> {
  final _formKey = GlobalKey<FormState>();
  final _containerInfoKey = GlobalKey<ContainerInfoFormState>();

  final TextEditingController refController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  bool isLoading = false;

  final AuthService authService = AuthService();
  final ContainerServices containerService = ContainerServices();

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final user = await authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context, "Erreur: Utilisateur non connecté");
        return;
      }

      final reference = refController.text.trim();
      final size = sizeController.text.trim();
      final isAvailable = _containerInfoKey.currentState?.isAvailable ?? false;
      final selectedSupplier = _containerInfoKey.currentState?.selectedSupplier;

      final response = await containerService.create(
        reference,
        size,
        isAvailable,
        user.id.toInt(),
        selectedSupplier?.id,
      );

      if (response == "CREATED") {
        Navigator.pop(context, true);
        showSuccessTopSnackBar(context, "Conteneur enregistré avec succès !");
      } else if (response == "NAME_EXIST") {
        showErrorTopSnackBar(context, "Ce conteneur existe déjà !");
      }
    } catch (e) {
      showErrorTopSnackBar(context, "Une erreur est survenue: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Nouveau conteneur",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ContainerInfoForm(
              key: _containerInfoKey,
              refController: refController,
              size: sizeController,
              initialAvailability: false,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: confirmationButton(
                  isLoading: isLoading,
                  onPressed: _submitForm,
                  label: "Enregistrer",
                  icon: Icons.check_circle_outline_outlined,
                  subLabel: "Enregistrement...",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    refController.dispose();
    super.dispose();
  }
}
