import 'package:bbd_limited/components/confirm_btn.dart';
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

class CreatePackageForm extends StatefulWidget {
  const CreatePackageForm({super.key});

  @override
  State<CreatePackageForm> createState() => _CreatePackageFormState();
}

class _CreatePackageFormState extends State<CreatePackageForm> {
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
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
      child: Form(
        key: _formKey,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            minHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Ajouter un nouveau colis",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.clear, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PackageInfoForm(
                  refController: refController,
                  weightController: weightController,
                  dimensionController: dimensionController,
                ),
                const SizedBox(height: 10),
                ClientDropdown(
                  clients: clients,
                  selectedClient: selectedClient,
                  onChanged:
                      (client) => setState(() => selectedClient = client),
                ),
                const SizedBox(height: 10),
                WarehouseDropdown(
                  warehouses: warehouses,
                  selectedWarehouse: selectedWarehouse,
                  onChanged:
                      (warehouse) =>
                          setState(() => selectedWarehouse = warehouse),
                ),
                const SizedBox(height: 20),
                PackageItemForm(onAddItem: _addItem),
                const SizedBox(height: 10),
                PackageItemsList(items: localItems, onRemoveItem: _removeItem),
                const SizedBox(height: 20),
                localItems.isNotEmpty
                    ? confirmationButton(
                      isLoading: isLoading,
                      onPressed: _submitForm,
                      label: "Enregistrer",
                      icon: Icons.check_circle_outline_rounded,
                      subLabel: "Enregistrement...",
                    )
                    : Text(""),
              ],
            ),
          ),
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
