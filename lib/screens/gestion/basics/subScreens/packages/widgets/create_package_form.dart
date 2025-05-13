import 'dart:developer';

import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/harbor_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/achats/create_achat_dto.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/harbor.dart';
import 'package:bbd_limited/models/package.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/package_info_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/package_items_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/package_items_list.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/warehouse_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/warehouses.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/models/versement.dart';

class CreatePackageForm extends StatefulWidget {
  const CreatePackageForm({super.key});

  @override
  State<CreatePackageForm> createState() => _CreatePackageFormState();
}

class _CreatePackageFormState extends State<CreatePackageForm>
    with SingleTickerProviderStateMixin {
  int currentStep = 0;
  final _formKeyStep1 = GlobalKey<FormState>();
  bool isLoading = false;

  final TextEditingController refController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController dimensionController = TextEditingController();
  DateTime? selectedDate;

  final List<Map<String, dynamic>> localItems = [];
  final AuthService authService = AuthService();
  final PackageServices packageServices = PackageServices();
  final AchatServices achatServices = AchatServices();
  final PartnerServices partnerServices = PartnerServices();
  final WarehouseServices warehouseServices = WarehouseServices();
  final HarborServices harborServices = HarborServices();
  final VersementServices versementServices = VersementServices();
  final ContainerServices containerServices = ContainerServices();

  List<Partner> clients = [];
  List<Partner> suppliers = [];
  Partner? selectedCLients;
  Partner? selectedSupplier;
  List<Warehouses> warehouses = [];
  Harbor? selectedHarbor;
  List<Harbor> harbors = [];
  Warehouses? selectedWarehouse;
  List<Versement> versements = [];
  Versement? selectedVersement;
  List<Containers> containers = [];
  Containers? selectedContainer;

  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final clientData = await partnerServices.fetchPartnersByType(
        'CLIENT',
        page: 0,
      );
      final supplierData = await partnerServices.fetchPartnersByType(
        'FOURNISSEUR',
        page: 0,
      );
      final warehousesData = await warehouseServices.findAllWarehouses(page: 0);
      final harborData = await harborServices.findAll(page: 0);
      final containerData = await containerServices.findAll(page: 0);

      setState(() {
        clients = clientData;
        suppliers = supplierData;
        warehouses = warehousesData;
        harbors = harborData;
        containers = containerData;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
      showErrorTopSnackBar(context, "Erreur lors du chargement des données");
    }
  }

  Future<void> _loadClientVersements(int clientId) async {
    if (clientId == null) {
      setState(() {
        versements = [];
      });
      return;
    }

    setState(() => isLoading = true);
    try {
      final versementsData = await versementServices.getByClient(clientId);
      setState(() {
        versements = versementsData;
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        isLoading = false;
      });
      showErrorTopSnackBar(context, "Erreur lors du chargement des versements");
    }
  }

  void _goToNextStep() {
    if (currentStep == 0 && !_formKeyStep1.currentState!.validate()) {
      return;
    }

    if (currentStep == 1) {
      String? errorMessage;
      if (selectedCLients == null) {
        errorMessage = "Sélectionnez un client";
      } else if (selectedVersement == null) {
        errorMessage = "Sélectionnez un versement";
      } else if (selectedSupplier == null) {
        errorMessage = "Sélectionnez un fournisseur";
      }

      if (errorMessage != null) {
        showErrorTopSnackBar(context, errorMessage);
        return;
      }
    }

    if (currentStep == 2) {
      String? errorMessage;
      if (selectedWarehouse == null) {
        errorMessage = "Sélectionnez un entrepôt";
      } else if (selectedHarbor == null) {
        errorMessage = "Sélectionnez un port";
      } else if (selectedContainer == null) {
        errorMessage = "Sélectionnez un conteneur";
      }

      if (errorMessage != null) {
        showErrorTopSnackBar(context, errorMessage);
        return;
      }
    }

    setState(() => currentStep++);
  }

  void _goToPreviousStep() {
    setState(() => currentStep--);
  }

  void _addItem(String description, double quantity, double unitPrice) {
    setState(
      () => localItems.add({
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
      }),
    );
  }

  void _removeItem(int index) {
    setState(() => localItems.removeAt(index));
  }

  Future<void> _submitForm() async {
    // Vérification initiale
    if (localItems.isEmpty) {
      showErrorTopSnackBar(context, "Ajoutez au moins un article.");
      return;
    }

    // Vérification des sélections
    if (selectedCLients == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un client");
      return;
    }
    if (selectedSupplier == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un fournisseur");
      return;
    }
    if (selectedWarehouse == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un entrepôt");
      return;
    }
    if (selectedVersement == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un versement");
      return;
    }
    if (selectedHarbor == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un port");
      return;
    }
    if (selectedContainer == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un conteneur");
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = await authService.getUserInfo();
      if (user == null || user.id == null) {
        showErrorTopSnackBar(context, "Utilisateur non connecté");
        return;
      }

      // Conversion du poids
      final weight = double.tryParse(weightController.text);
      if (weight == null || weight <= 0) {
        showErrorTopSnackBar(context, "Poids invalide");
        return;
      }

      // Création du DTO
      final packageDta = Packages.fromJson({
        "reference": refController.text.trim(),
        "weight": weight,
        "dimensions": dimensionController.text.trim(),
        "createdAt":
            selectedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      });

      final createAchatDto = CreateAchatDto(
        versementId: selectedVersement!.id!,
        packageDto: packageDta,
        lignes:
            localItems
                .map(
                  (item) => Achat(
                    descriptionItem: item['description']?.toString() ?? '',
                    quantityItem: (item['quantity'] as num?)?.toDouble() ?? 0.0,
                    prixUnitaire:
                        (item['unitPrice'] as num?)?.toDouble() ?? 0.0,
                  ),
                )
                .toList(),
      );

      // Appel au service avec les IDs corrects
      final result = await achatServices.createAchatForClient(
        clientId: selectedCLients!.id,
        supplierId: selectedSupplier!.id,
        userId: user.id,
        warehouseId: selectedWarehouse!.id,
        containerId: selectedContainer!.id!,
        dto: createAchatDto,
      );

      if (!mounted) return;

      switch (result) {
        case "SUCCESS":
          Navigator.pop(context, true);
          showSuccessTopSnackBar(context, "Colis créé avec succès !");
          break;
        case "INVALID_ACHAT":
          showErrorTopSnackBar(
            context,
            "Le versement ne correspond pas au client",
          );
          break;
        case "INACTIVE_ACHAT":
          showErrorTopSnackBar(context, "Le versement n'est pas actif");
          break;
        default:
          showErrorTopSnackBar(context, "Une erreur inattendue s'est produite");
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(context, "Erreur: ${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKeyStep1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight:
                currentStep == 0 || currentStep == 1 || currentStep == 2
                    ? MediaQuery.of(context).size.height * 0.555
                    : MediaQuery.of(context).size.height * 0.7,
          ),
          child: Stack(
            children: [
              /// 🧱 Contenu principal scrollable
              Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Ajouter un nouveau colis",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getStepSubtitle(),
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Expanded(
                      child: IndexedStack(
                        index: currentStep,
                        children: [
                          // Étape 1: Informations de base
                          ListView(
                            children: [
                              PackageInfoForm(
                                refController: refController,
                                weightController: weightController,
                                dimensionController: dimensionController,
                                initialDate: selectedDate,
                                onDateChanged: (date) {
                                  setState(() {
                                    selectedDate = date;
                                  });
                                },
                              ),
                            ],
                          ),
                          // Étape 2: Sélections (dropdowns)
                          ListView(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Client",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  DropDownCustom<Partner>(
                                    items: clients,
                                    selectedItem: selectedCLients,
                                    onChanged: (client) {
                                      setState(() {
                                        selectedCLients = client;
                                        if (client?.id != selectedCLients?.id) {
                                          // selectedVersement = null;
                                          versements = [];
                                        }
                                      });
                                      if (client != null) {
                                        _loadClientVersements(client.id);
                                      }
                                    },
                                    itemToString:
                                        (client) =>
                                            '${client.firstName + " " + client.lastName} | ${client.phoneNumber}',
                                    hintText: 'Choisir un client...',
                                    prefixIcon: Icons.person_3,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Versement",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  DropDownCustom<Versement>(
                                    items: versements,
                                    selectedItem: selectedVersement,
                                    onChanged:
                                        (versement) => setState(
                                          () => selectedVersement = versement,
                                        ),
                                    itemToString:
                                        (versement) =>
                                            '${versement.reference} | ${versement.montantVerser} | ${versement.partnerName}',
                                    hintText: 'Choisir un versement...',
                                    prefixIcon: Icons.payments,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Fournisseur",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  DropDownCustom<Partner>(
                                    items: suppliers,
                                    selectedItem: selectedSupplier,
                                    onChanged:
                                        (supplier) => setState(
                                          () => selectedSupplier = supplier,
                                        ),
                                    itemToString:
                                        (supplier) =>
                                            '${supplier.firstName + " " + supplier.lastName} | ${supplier.phoneNumber}',
                                    hintText: 'Choisir un fournisseur...',
                                    prefixIcon: Icons.person_add,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Etape 3: Selection des entrepot, port et conteneur
                          ListView(
                            children: [
                              const SizedBox(height: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Entrepot",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  DropDownCustom<Warehouses>(
                                    items: warehouses,
                                    selectedItem: selectedWarehouse,
                                    onChanged:
                                        (warehouse) => setState(
                                          () => selectedWarehouse = warehouse,
                                        ),
                                    itemToString:
                                        (warehouse) =>
                                            '${warehouse.name} | ${warehouse.adresse}',
                                    hintText: 'Choisir un magasin...',
                                    prefixIcon: Icons.warehouse,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Port",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  DropDownCustom<Harbor>(
                                    items: harbors,
                                    selectedItem: selectedHarbor,
                                    onChanged:
                                        (harbor) => setState(
                                          () => selectedHarbor = harbor,
                                        ),
                                    itemToString:
                                        (harbor) =>
                                            '${harbor.name} | ${harbor.location}',
                                    hintText: 'Choisir un port...',
                                    prefixIcon: Icons.cabin_outlined,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Conteneur",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  DropDownCustom<Containers>(
                                    items: containers,
                                    selectedItem: selectedContainer,
                                    onChanged:
                                        (c) => setState(
                                          () => selectedContainer = c,
                                        ),
                                    itemToString: (c) => '${c.reference}',
                                    hintText: 'Choisir un conteneur...',
                                    prefixIcon: Icons.storage,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Étape 4: Articles
                          ListView(
                            children: [
                              PackageItemForm(onAddItem: _addItem),
                              const SizedBox(height: 10),
                              PackageItemsList(
                                items: localItems,
                                onRemoveItem: _removeItem,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                  child: _buildStepControls(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepSubtitle() {
    switch (currentStep) {
      case 0:
        return "Informations de base du colis";
      case 1:
        return "Sélection du client, du fournisseur et du versement";
      case 2:
        return "Sélection de l'entrepôt";
      case 3:
        return "Ajout des articles au colis";
      default:
        return "";
    }
  }

  Widget _buildStepControls() {
    if (currentStep == 0) {
      return confirmationButton(
        isLoading: false,
        label: "Suivant",
        onPressed: _goToNextStep,
        icon: Icons.arrow_forward_ios,
        subLabel: "Chargement...",
      );
    } else if (currentStep == 1 || currentStep == 2) {
      return Row(
        children: [
          Expanded(
            child: TextButton.icon(
              icon: Icon(Icons.arrow_back),
              onPressed: _goToPreviousStep,
              label: Text("Retour"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: confirmationButton(
              isLoading: false,
              label: "Suivant",
              onPressed: _goToNextStep,
              icon: Icons.arrow_forward_ios,
              subLabel: "Chargement...",
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: TextButton.icon(
              icon: Icon(Icons.arrow_back),
              onPressed: _goToPreviousStep,
              label: Text("Retour"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: confirmationButton(
              isLoading: isLoading,
              label: "Enregistrer",
              subLabel: "Enregistrement...",
              icon: Icons.check,
              onPressed: _submitForm,
            ),
          ),
        ],
      );
    }
  }

  @override
  void dispose() {
    refController.dispose();
    weightController.dispose();
    dimensionController.dispose();
    super.dispose();
  }
}
