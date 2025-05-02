import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/container_info_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/client_dropdown.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/package_info_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/package_items_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/package_items_list.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/warehouse_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/warehouse_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/warehouses.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';

class CreateContainerForm extends StatefulWidget {
  const CreateContainerForm({super.key});

  @override
  State<CreateContainerForm> createState() => _CreateContainerForm();
}

class _CreateContainerForm extends State<CreateContainerForm> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final TextEditingController refController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController dimensionController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final List<Map<String, dynamic>> localItems = [];

  final AuthService authService = AuthService();
  final PackageServices packageServices = PackageServices();
  final PartnerServices partnerServices = PartnerServices();
  final WarehouseServices warehouseServices = WarehouseServices();

  List<Partner> clients = [];
  Partner? selectedClient;
  List<Warehouses> warehouses = [];
  Warehouses? selectedWarehouse;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final clientsData = await partnerServices.fetchPartnersByType(
        'CLIENT',
        page: 0,
      );
      final warehousesData = await warehouseServices.findAllWarehouses(page: 0);

      setState(() {
        clients = clientsData;
        warehouses = warehousesData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      showErrorTopSnackBar(context, "Erreur lors du chargement des données");
    }
  }

  void _addItem(String description, double quantity) {
    setState(() {
      localItems.add({'description': description, 'quantity': quantity});
    });
  }

  void _removeItem(int index) {
    setState(() {
      localItems.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedClient == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un client.");
      return;
    }
    if (selectedWarehouse == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un entrepôt.");
      return;
    }
    if (localItems.isEmpty) {
      showErrorTopSnackBar(context, "Veuillez ajouter au moins un article.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = await authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context, "Erreur: Utilisateur non connecté");
        return;
      }

      final packageId = await packageServices.create(
        refController.text,
        dimensionController.text,
        double.parse(weightController.text),
        user.id,
        selectedWarehouse!.id.toInt(),
        selectedClient!.id.toInt(),
      );

      if (packageId == null) {
        showErrorTopSnackBar(context, "Erreur: Référence déjà utilisée.");
        return;
      }

      await packageServices.addItemsToPackage(
        packageId,
        localItems,
        user.id.toInt(),
      );

      Navigator.pop(context, true);
      showSuccessTopSnackBar(context, "Colis ajoutés avec succès !");
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
                Text(
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
              refController: refController,
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
    quantityController.dispose();
    dimensionController.dispose();
    weightController.dispose();
    super.dispose();
  }
}
