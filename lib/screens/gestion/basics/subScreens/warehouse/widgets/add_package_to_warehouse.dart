import 'package:flutter/material.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/providers/package_provider.dart';
import 'package:provider/provider.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/create_container_form.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/create_partner_bottom_sheet.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:country_picker/country_picker.dart';
import 'package:bbd_limited/components/date_picker.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/core/services/item_services.dart';

class AddPackageToWarehouseForm extends StatefulWidget {
  final int warehouseId;
  const AddPackageToWarehouseForm({Key? key, required this.warehouseId})
      : super(key: key);

  @override
  State<AddPackageToWarehouseForm> createState() =>
      _AddPackageToWarehouseFormState();
}

class _AddPackageToWarehouseFormState extends State<AddPackageToWarehouseForm> {
  final _formKey = GlobalKey<FormState>();
  final _refController = TextEditingController();
  final _weightController = TextEditingController();
  final _cbnController = TextEditingController();
  final _quantityController = TextEditingController();

  int currentStep = 0;
  bool isLoading = false;

  List<Partner> _clients = [];
  Partner? _selectedClient;
  List<Containers> _containers = [];
  Containers? _selectedContainer;

  // Items
  List<dynamic> _eligibleItems = [];
  bool _isLoadingItems = false;

  // Pays/dates
  Country? _departureCountry;
  Country? _arrivalCountry;
  DateTime? _startDate;
  DateTime? _estimatedArrivalDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClients();
      _loadContainers();
    });
  }

  Future<void> _loadClients() async {
    final provider = context.read<PackageProvider>();
    await provider.loadClients();
    setState(() {
      _clients = provider.clients;
    });
  }

  Future<void> _loadContainers() async {
    final provider = context.read<PackageProvider>();
    await provider.loadContainers();
    setState(() {
      _containers = provider.container;
    });
  }

  Future<void> _loadEligibleItems(int clientId) async {
    setState(() => _isLoadingItems = true);
    try {
      _eligibleItems = await ItemServices().findItemsByClient(clientId);
      final provider = context.read<PackageProvider>();
      provider.clearSelectedItemIds();
    } catch (e) {
      setState(() {
        _eligibleItems = [];
      });
      final provider = context.read<PackageProvider>();
      provider.clearSelectedItemIds();
      showErrorTopSnackBar(
          context, "Erreur lors du chargement des items: " + e.toString());
    } finally {
      setState(() => _isLoadingItems = false);
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
      });
      final provider = context.read<PackageProvider>();
      provider.clearSelectedItemIds();
    }
  }

  @override
  void dispose() {
    _refController.dispose();
    _weightController.dispose();
    _cbnController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    if (currentStep == 0 && _selectedClient == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un client.");
      return;
    }
    if (currentStep == 1 &&
        _eligibleItems.isNotEmpty &&
        context.read<PackageProvider>().selectedItemIds.isEmpty) {
      showErrorTopSnackBar(context, "Veuillez sélectionner au moins un item.");
      return;
    }
    if (currentStep == 2) {
      if (_departureCountry == null) {
        showErrorTopSnackBar(
            context, "Veuillez sélectionner le pays de départ.");
        return;
      }
      if (_arrivalCountry == null) {
        showErrorTopSnackBar(
            context, "Veuillez sélectionner le pays d'arrivée.");
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
      if (_selectedContainer == null) {
        showErrorTopSnackBar(context, "Veuillez sélectionner un conteneur.");
        return;
      }
    }
    setState(() => currentStep++);
  }

  void _goToPreviousStep() {
    setState(() => currentStep--);
  }

  Future<void> _handleSubmit() async {
    if (_selectedContainer == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un conteneur.");
      return;
    }
    if (_departureCountry == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner le pays de départ.");
      return;
    }
    if (_arrivalCountry == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner le pays d'arrivée.");
      return;
    }
    setState(() => isLoading = true);
    try {
      final provider = context.read<PackageProvider>();
      provider.selectedClient = _selectedClient;
      provider.departureCountry = _departureCountry;
      provider.arrivalCountry = _arrivalCountry;
      provider.startDate = _startDate;
      provider.estimatedArrivalDate = _estimatedArrivalDate;
      final weight = double.tryParse(_weightController.text);
      final cbn = double.tryParse(_cbnController.text);
      final quantity = double.tryParse(_quantityController.text);
      if (provider.expeditionType == "Avion" && weight == null) {
        showErrorTopSnackBar(context, "Le poids est invalid");
        return;
      }
      if (provider.expeditionType == "Bateau" && cbn == null) {
        showErrorTopSnackBar(context, "Le cbn est invalid");
        return;
      }
      final success = await provider.createPackage(
        ref: _refController.text,
        weight: weight,
        cbn: cbn,
        quantity: quantity ?? 0,
        warehouseId: widget.warehouseId,
        containerId: _selectedContainer?.id ?? 0,
        context: context,
      );
      if (success) {
        Navigator.pop(context, true);
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PackageProvider>(
      builder: (context, provider, child) {
        return Form(
          key: _formKey,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 80.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Text(
                              "Ajouter un nouveau colis",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1,
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
                            _buildStep1(provider),
                            _buildStep2(),
                            _buildStep3(),
                            _buildStep4(),
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
                        vertical: 10, horizontal: 10),
                    child: _buildStepControls(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep1(PackageProvider provider) {
    return ListView(
      children: [
        _buildExpeditionTypeSelector(provider),
        const SizedBox(height: 20),
        buildTextField(
          controller: _refController,
          label: "Référence de l'expédition",
          icon: Icons.numbers,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Ce champ est requis' : null,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: provider.expeditionType == 'Avion'
                  ? buildTextField(
                      controller: _weightController,
                      label: "Poids (kg)",
                      icon: Icons.scale,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true)
                          return "Ce champ est requis";
                        if (double.tryParse(value!) == null) {
                          return "Veuillez entrer un nombre valide";
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
                        if (value?.isEmpty ?? true)
                          return "Ce champ est requis";
                        if (double.tryParse(value!) == null) {
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
                icon: Icons.production_quantity_limits_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Ce champ est requis';
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              flex: 3,
              child: DropDownCustom<Partner>(
                items: _clients,
                selectedItem: _selectedClient,
                onChanged: _onClientSelected,
                itemToString: (client) =>
                    '${client.firstName} ${client.lastName} | ${client.phoneNumber}',
                hintText: 'Choisir un client...',
                prefixIcon: Icons.person,
              ),
            ),
            Expanded(
              flex: 1,
              child: IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const CreatePartnerBottomSheet(),
                  ).then((_) {
                    _loadClients();
                  });
                },
                icon: Icon(Icons.add),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    if (_isLoadingItems) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_eligibleItems.isEmpty) {
      return const Center(child: Text("Aucun item éligible pour ce client."));
    }
    return ListView(
      children: _eligibleItems.map((item) {
        return CheckboxListTile(
          value:
              context.read<PackageProvider>().selectedItemIds.contains(item.id),
          onChanged: (selected) {
            final provider = context.read<PackageProvider>();
            if (selected == true) {
              provider.addSelectedItemId(item.id!);
            } else {
              provider.removeSelectedItemId(item.id!);
            }
          },
          title: Text(item.description ?? "Sans description"),
          subtitle: Text("Quantité: ${item.quantity?.toString() ?? "-"}"),
        );
      }).toList(),
    );
  }

  Widget _buildStep3() {
    return ListView(
      children: [
        _buildCountrySelector(
          label: 'Pays de départ',
          selectedCountry: _departureCountry,
          onCountrySelected: (country) {
            setState(() {
              _departureCountry = country;
            });
          },
        ),
        const SizedBox(height: 20),
        _buildCountrySelector(
          label: 'Pays d\'arrivée',
          selectedCountry: _arrivalCountry,
          onCountrySelected: (country) {
            setState(() {
              _arrivalCountry = country;
            });
          },
        ),
        const SizedBox(height: 20),
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
    );
  }

  Widget _buildStep4() {
    return ListView(
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
                itemToString: (container) => '${container.reference}',
                hintText: 'Choisir un conténeur...',
                prefixIcon: Icons.inventory_2,
              ),
            ),
            Expanded(
              flex: 1,
              child: IconButton(
                onPressed: () {
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
                    _loadContainers();
                  });
                },
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpeditionTypeSelector(PackageProvider provider) {
    return Container(
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
                  groupValue: provider.expeditionType,
                  onChanged: (value) {
                    provider.expeditionType = value!;
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Avion'),
                  value: 'Avion',
                  groupValue: provider.expeditionType,
                  onChanged: (value) {
                    provider.expeditionType = value!;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountrySelector({
    required String label,
    required Country? selectedCountry,
    required Function(Country) onCountrySelected,
  }) {
    return InkWell(
      onTap: () {
        showCountryPicker(
          context: context,
          showPhoneCode: true,
          countryListTheme: const CountryListThemeData(
            flagSize: 25,
            backgroundColor: Colors.white,
            textStyle: TextStyle(fontSize: 16),
            bottomSheetHeight: 300,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          onSelect: onCountrySelected,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                selectedCountry != null
                    ? Row(
                        children: [
                          Text(
                            selectedCountry.flagEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Text(selectedCountry.name),
                        ],
                      )
                    : const Text('Choisir un pays'),
              ],
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
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
              icon: const Icon(Icons.arrow_back),
              onPressed: _goToPreviousStep,
              label: const Text("Retour"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: confirmationButton(
              isLoading: isLoading,
              label: "Enregistrer",
              subLabel: "Enregistrement...",
              icon: Icons.check,
              onPressed: _handleSubmit,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: TextButton.icon(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goToPreviousStep,
              label: const Text("Retour"),
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
}

Future<bool?> showAddPackageModal(BuildContext context, int warehouseId) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return ChangeNotifierProvider(
        create: (_) => PackageProvider(),
        child: Dialog(
          backgroundColor: Colors.white,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: AddPackageToWarehouseForm(warehouseId: warehouseId),
        ),
      );
    },
  );
}
