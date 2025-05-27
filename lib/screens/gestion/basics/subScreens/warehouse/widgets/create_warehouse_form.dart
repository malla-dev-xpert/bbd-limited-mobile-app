import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/warehouse_services.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

class CreateWarehouseForm extends StatefulWidget {
  const CreateWarehouseForm({Key? key}) : super(key: key);

  @override
  State<CreateWarehouseForm> createState() => _CreateWarehouseFormState();
}

class _CreateWarehouseFormState extends State<CreateWarehouseForm> {
  final _formKey = GlobalKey<FormState>();
  final WarehouseServices _warehouseServices = WarehouseServices();
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _storageTypeController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                const Text(
                  'Ajouter un entrepôt',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            buildTextField(
              controller: _nameController,
              label: "Nom de l'entrepôt",
              icon: Icons.warehouse,
              validator:
                  (value) =>
                      value?.isEmpty ?? true ? 'Ce champ est requis' : null,
            ),
            const SizedBox(height: 10),
            buildTextField(
              controller: _adresseController,
              label: "Adresse",
              icon: Icons.location_on,
              validator:
                  (value) =>
                      value?.isEmpty ?? true ? 'Ce champ est requis' : null,
            ),
            const SizedBox(height: 10),
            buildTextField(
              controller: _storageTypeController,
              label: "Type de stockage",
              icon: Icons.storage,
              validator:
                  (value) =>
                      value?.isEmpty ?? true ? 'Ce champ est requis' : null,
            ),
            const SizedBox(height: 20),
            confirmationButton(
              isLoading: _isLoading,
              label: "Enregistrer",
              onPressed: _saveWarehouse,
              icon: Icons.check,
              subLabel: "Enregistrement...",
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveWarehouse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.getUserInfo();
      if (user == null || user.id == null) {
        showErrorTopSnackBar(context, "Utilisateur non connecté");
        return;
      }

      final result = await _warehouseServices.create(
        _nameController.text.trim(),
        _adresseController.text.trim(),
        _storageTypeController.text.trim(),
        user.id,
      );

      if (!mounted) return;

      switch (result) {
        case "CREATED":
          Navigator.pop(context, true);
          showSuccessTopSnackBar(context, "Entrepôt créé avec succès !");
          break;
        case "NAME_EXIST":
          showErrorTopSnackBar(context, "Un entrepôt avec ce nom existe déjà");
          break;
        case "ADRESS_EXIST":
          showErrorTopSnackBar(
            context,
            "Un entrepôt existe déjà à cette adresse",
          );
          break;
        default:
          showErrorTopSnackBar(context, "Une erreur inattendue s'est produite");
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(context, "Erreur: ${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
