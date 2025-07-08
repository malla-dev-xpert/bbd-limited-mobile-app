import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/warehouse_services.dart';
import 'package:bbd_limited/core/services/harbor_services.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/warehouses.dart';
import 'package:bbd_limited/models/harbor.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/create_container_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/widgets/create_warehouse_form.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/date_picker.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/create_partner_bottom_sheet.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/harbor/widgets/add_harbor.dart';

class CreateExpeditionForm extends StatefulWidget {
  final bool isPackageScreen;
  final String? clientId;
  final Function()? onExpeditionCreated;
  const CreateExpeditionForm({
    super.key,
    this.isPackageScreen = false,
    this.clientId,
    this.onExpeditionCreated,
  });

  @override
  _CreateExpeditionFormState createState() => _CreateExpeditionFormState();
}

class _CreateExpeditionFormState extends State<CreateExpeditionForm> {
  final _formKey = GlobalKey<FormState>();
  final PartnerServices _partnerServices = PartnerServices();
  final ContainerServices _containerServices = ContainerServices();
  final WarehouseServices _warehouseServices = WarehouseServices();
  final HarborServices _harborServices = HarborServices();

  final AuthService authService = AuthService();
  final PackageServices packageServices = PackageServices();

  final TextEditingController _refController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _cbnController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  String _expeditionType = 'Bateau';
  DateTime? _startDate;
  DateTime? _estimatedArrivalDate;
  List<Partner> _clients = [];
  Partner? _selectedClient;
  bool isLoading = false;
  int currentStep = 0;

  List<Containers> _containers = [];
  List<Warehouses> _warehouses = [];
  Containers? _selectedContainer;
  Warehouses? _selectedWarehouse;

  List<Items> _eligibleItems = [];
  Set<int> _selectedItemIds = {};
  bool _isLoadingItems = false;

  List<Harbor> _harbors = [];
  Harbor? _selectedDepartureHarbor;
  Harbor? _selectedArrivalHarbor;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _loadContainers();
    _loadWarehouses();
    _loadHarbors();
  }

  Future<void> _loadClients() async {
    final clients = await _partnerServices.findCustomers(page: 0);
    setState(() {
      _clients = clients;
    });
  }

  Future<void> _loadContainers() async {
    final containers = await _containerServices.findAll(page: 0);
    setState(() {
      _containers = containers;
    });
  }

  Future<void> _loadWarehouses() async {
    final warehouses = await _warehouseServices.findAllWarehouses(page: 0);
    setState(() {
      _warehouses = warehouses;
    });
  }

  Future<void> _loadEligibleItems(int clientId) async {
    setState(() => _isLoadingItems = true);
    try {
      _eligibleItems = await ItemServices().findItemsByClient(clientId);
      _selectedItemIds.clear();
    } catch (e) {
      setState(() {
        _eligibleItems = [];
        _selectedItemIds.clear();
      });
      showErrorTopSnackBar(
          context, "Erreur lors du chargement des items: ${e.toString()}");
    } finally {
      setState(() => _isLoadingItems = false);
    }
  }

  Future<void> _loadHarbors() async {
    final harbors = await _harborServices.findAll(page: 0);
    setState(() {
      _harbors = harbors;
    });
  }

  void _showCreateHarborModal() async {
    final result = await showAddHarborModal(context);
    if (result == true) {
      await _loadHarbors();
    }
  }

  void _onClientSelected(Partner? client) {
    setState(() {
      _selectedClient = client;
    });
    if (client != null && client.id != null) {
      _loadEligibleItems(client.id!);
    } else {
      setState(() {
        _eligibleItems = [];
        _selectedItemIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: widget.isPackageScreen == true
              ? MediaQuery.of(context).size.height * 0.7
              : MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Ajouter un colis",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: IndexedStack(
                      index: currentStep,
                      children: [
                        // Étape 1 : Infos de base + sélection client
                        ListView(
                          children: [
                            // Type d'expédition
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'Type d\'expédition',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: const Text('Bateau'),
                                          value: 'Bateau',
                                          groupValue: _expeditionType,
                                          onChanged: (value) {
                                            setState(() {
                                              _expeditionType = value!;
                                            });
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: const Text('Avion'),
                                          value: 'Avion',
                                          groupValue: _expeditionType,
                                          onChanged: (value) {
                                            setState(() {
                                              _expeditionType = value!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            buildTextField(
                              controller: _refController,
                              label: "Référence de l'expédition",
                              icon: Icons.numbers,
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Ce champ est requis'
                                  : null,
                            ),
                            const SizedBox(height: 20),

                            // Champ Poids ou CBN selon le type
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _expeditionType == 'Avion'
                                      ? buildTextField(
                                          controller: _weightController,
                                          label: "Poids (kg)",
                                          icon: Icons.scale,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value?.isEmpty ?? true) {
                                              return 'Ce champ est requis';
                                            }
                                            if (double.tryParse(value!) ==
                                                null) {
                                              return 'Veuillez entrer un nombre valide';
                                            }
                                            return null;
                                          },
                                        )
                                      : buildTextField(
                                          controller: _cbnController,
                                          label: "CBN",
                                          icon: Icons.monitor_weight,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value?.isEmpty ?? true) {
                                              return 'Ce champ est requis';
                                            }
                                            if (double.tryParse(value!) ==
                                                null) {
                                              return 'Veuillez entrer un nombre valide';
                                            }
                                            return null;
                                          },
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: buildTextField(
                                    controller: _quantityController,
                                    label: "Nombre de carton",
                                    icon: Icons
                                        .production_quantity_limits_outlined,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Ce champ est requis';
                                      }
                                      if (double.tryParse(value!) == null) {
                                        return 'Veuillez entrer un nombre valide';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            if (widget.isPackageScreen)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: DropDownCustom<Partner>(
                                      items: _clients,
                                      selectedItem: _selectedClient,
                                      onChanged: _onClientSelected,
                                      itemToString: (client) =>
                                          '${client.firstName} ${client.lastName} ${client.lastName.isNotEmpty ? '|' : ''} ${client.phoneNumber}',
                                      hintText: 'Choisir un client...',
                                      prefixIcon: Icons.person,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: IconButton(
                                      onPressed: _showCreateClientBottomSheet,
                                      icon: const Icon(Icons.add),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        // Étape 2 : Sélection des items
                        _buildItemSelectionStep(),
                        // Étape 3
                        ListView(
                          children: [
                            // Port de départ
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: DropDownCustom<Harbor>(
                                    items: _harbors,
                                    selectedItem: _selectedDepartureHarbor,
                                    onChanged: (harbor) {
                                      setState(() {
                                        _selectedDepartureHarbor = harbor;
                                      });
                                    },
                                    itemToString: (harbor) => harbor.name ?? '',
                                    hintText: 'Choisir un port de départ...',
                                    prefixIcon: Icons.sailing,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: IconButton(
                                    onPressed: _showCreateHarborModal,
                                    icon: const Icon(Icons.add),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Port d'arrivée
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: DropDownCustom<Harbor>(
                                    items: _harbors,
                                    selectedItem: _selectedArrivalHarbor,
                                    onChanged: (harbor) {
                                      setState(() {
                                        _selectedArrivalHarbor = harbor;
                                      });
                                    },
                                    itemToString: (harbor) => harbor.name ?? '',
                                    hintText: "Choisir un port d'arrivée...",
                                    prefixIcon: Icons.sailing,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: IconButton(
                                    onPressed: _showCreateHarborModal,
                                    icon: const Icon(Icons.add),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Date de départ
                            DatePickerField(
                              label: "Date de départ",
                              selectedDate: _startDate,
                              onDateSelected: (date) {
                                setState(() {
                                  _startDate = date;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            // Date d'arrivée estimée
                            DatePickerField(
                              label: "Date d'arrivée estimée",
                              selectedDate: _estimatedArrivalDate,
                              onDateSelected: (date) {
                                setState(() {
                                  _estimatedArrivalDate = date;
                                });
                              },
                            ),
                          ],
                        ),
                        // Step 4 - Container and Warehouse Selection
                        ListView(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              spacing: 10,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: DropDownCustom<Containers>(
                                    items: _containers,
                                    selectedItem: _selectedContainer,
                                    onChanged: (container) {
                                      setState(() {
                                        _selectedContainer = container;
                                      });
                                    },
                                    itemToString: (container) =>
                                        '${container.reference}',
                                    hintText: 'Choisir un container...',
                                    prefixIcon: Icons.inventory_2,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: IconButton(
                                    onPressed: _showCreateContainerBottomSheet,
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                        Colors.grey[100],
                                      ),
                                      fixedSize: MaterialStateProperty.all(
                                        const Size(55, 55),
                                      ),
                                      padding: MaterialStateProperty.all(
                                        EdgeInsets.zero,
                                      ),
                                      shape: MaterialStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              spacing: 10,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: DropDownCustom<Warehouses>(
                                    items: _warehouses,
                                    selectedItem: _selectedWarehouse,
                                    onChanged: (warehouse) {
                                      setState(() {
                                        _selectedWarehouse = warehouse;
                                      });
                                    },
                                    itemToString: (warehouse) =>
                                        '${warehouse.name} - ${warehouse.adresse}',
                                    hintText: 'Choisir un entrepôt...',
                                    prefixIcon: Icons.warehouse,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: IconButton(
                                    onPressed: _showCreateWarehouseBottomSheet,
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                        Colors.grey[100],
                                      ),
                                      fixedSize: MaterialStateProperty.all(
                                        const Size(55, 55),
                                      ),
                                      padding: MaterialStateProperty.all(
                                        EdgeInsets.zero,
                                      ),
                                      shape: MaterialStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add),
                                  ),
                                ),
                              ],
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
    );
  }

  void _goToNextStep() {
    if (currentStep == 0 && widget.isPackageScreen && _selectedClient == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un client.");
      return;
    }
    if (currentStep == 1 &&
        _eligibleItems.isNotEmpty &&
        _selectedItemIds.isEmpty) {
      showErrorTopSnackBar(context, "Veuillez sélectionner au moins un item.");
      return;
    }
    if (currentStep == 2) {
      // Validation pour l'étape 3 (ports et dates)
      if (_selectedDepartureHarbor == null) {
        showErrorTopSnackBar(
            context, "Veuillez sélectionner le port de départ.");
        return;
      }
      if (_selectedArrivalHarbor == null) {
        showErrorTopSnackBar(
            context, "Veuillez sélectionner le port d'arrivée.");
        return;
      }
      if (_startDate == null) {
        showErrorTopSnackBar(
            context, "Veuillez sélectionner la date de départ.");
        return;
      }
      if (_estimatedArrivalDate == null) {
        showErrorTopSnackBar(
            context, "Veuillez sélectionner la date d'arrivée estimée.");
        return;
      }
    }
    if (currentStep == 3) {
      // Validation pour l'étape 4 (conteneur et entrepôt)
      if (_selectedContainer == null) {
        showErrorTopSnackBar(context, "Veuillez sélectionner un conteneur.");
        return;
      }
      if (_selectedWarehouse == null) {
        showErrorTopSnackBar(context, "Veuillez sélectionner un entrepôt.");
        return;
      }
    }
    setState(() => currentStep++);
  }

  void _goToPreviousStep() {
    setState(() => currentStep--);
  }

  Future<void> _submitForm() async {
    // Validation finale avant soumission
    if (_selectedContainer == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un conteneur.");
      return;
    }
    if (_selectedWarehouse == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un entrepôt.");
      return;
    }
    if (_selectedDepartureHarbor == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner le port de départ.");
      return;
    }
    if (_selectedArrivalHarbor == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner le port d'arrivée.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = await authService.getUserInfo();
      if (user == null || user.id == null) {
        showErrorTopSnackBar(context, "Utilisateur non connecté");
        return;
      }

      // Conversion des champs
      final weight = double.tryParse(_weightController.text);
      final cbn = double.tryParse(_cbnController.text);
      final quantity = double.tryParse(_quantityController.text);

      if (_expeditionType == "Avion") {
        if (weight == null) {
          showErrorTopSnackBar(context, "Le poids est invalid");
          return;
        }
      } else if (_expeditionType == "Bateau") {
        if (cbn == null) {
          showErrorTopSnackBar(context, "Le cbn est invalid");
          return;
        }
      }

      // Création du DTO
      final dto = Packages(
        ref: _refController.text.trim(),
        weight: weight,
        itemQuantity: quantity,
        cbn: cbn,
        startDate: _startDate,
        arrivalDate: _estimatedArrivalDate,
        expeditionType: _expeditionType,
        startCountry: _selectedDepartureHarbor?.name,
        destinationCountry: _selectedArrivalHarbor?.name,
        startHarborId: _selectedDepartureHarbor?.id,
        destinationHarborId: _selectedArrivalHarbor?.id,
        containerId: _selectedContainer?.id,
        warehouseId: _selectedWarehouse?.id,
        itemIds: _selectedItemIds.toList(),
      );

      // Appel au service avec les IDs corrects
      final result = await packageServices.create(
        dto: dto,
        clientId: widget.isPackageScreen
            ? _selectedClient!.id
            : int.parse(widget.clientId!),
        userId: user.id,
        containerId: _selectedContainer!.id!,
        warehouseId: _selectedWarehouse!.id,
      );

      if (!mounted) return;

      switch (result) {
        case "SUCCESS":
          widget.onExpeditionCreated?.call();
          Navigator.pop(context, true);
          showSuccessTopSnackBar(context, "Expédition créée avec succès !");
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

  Widget _buildStepControls() {
    if (currentStep == 0) {
      return confirmationButton(
        isLoading: false,
        label: "Suivant",
        onPressed: _goToNextStep,
        icon: Icons.arrow_forward_ios,
        subLabel: "Chargement...",
      );
    } else if (currentStep == 3) {
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
              isLoading: false,
              label: "Suivant",
              onPressed: _goToNextStep,
              icon: Icons.arrow_forward_ios,
              subLabel: "Chargement...",
            ),
          ),
        ],
      );
    }
  }

  void _showCreateClientBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePartnerBottomSheet(),
    ).then((_) {
      _loadClients(); // Recharger la liste des clients après la création
    });
  }

  void _showCreateContainerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const CreateContainerForm(),
      ),
    ).then((_) {
      _loadContainers(); // Recharger la liste des clients après la création
    });
  }

  void _showCreateWarehouseBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const CreateWarehouseForm(),
      ),
    ).then((_) {
      _loadWarehouses(); // Recharger la liste des entrepôts après la création
    });
  }

  Widget _buildItemSelectionStep() {
    if (_isLoadingItems) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_eligibleItems.isEmpty) {
      return const Center(child: Text("Aucun item éligible pour ce client."));
    }
    return ListView(
      children: _eligibleItems.map((item) {
        return CheckboxListTile(
          value: _selectedItemIds.contains(item.id),
          onChanged: (selected) {
            setState(() {
              if (selected == true) {
                _selectedItemIds.add(item.id!);
              } else {
                _selectedItemIds.remove(item.id);
              }
            });
          },
          title: Text(item.description ?? "Sans description"),
          subtitle: Text("Quantité: " + (item.quantity?.toString() ?? "-")),
        );
      }).toList(),
    );
  }
}
