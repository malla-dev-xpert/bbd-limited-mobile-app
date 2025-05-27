import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/create_container_form.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/create_partner_bottom_sheet.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:country_picker/country_picker.dart';
import 'package:bbd_limited/components/date_picker.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/providers/package_provider.dart';
import 'package:bbd_limited/models/partner.dart';

class AddPackageForm extends StatefulWidget {
  final int warehouseId;

  const AddPackageForm({Key? key, required this.warehouseId}) : super(key: key);

  @override
  State<AddPackageForm> createState() => _AddPackageFormState();
}

class _AddPackageFormState extends State<AddPackageForm> {
  final _formKey = GlobalKey<FormState>();
  final _refController = TextEditingController();
  final _weightController = TextEditingController();
  final _cbnController = TextEditingController();
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PackageProvider>();
      provider.loadClients();
      provider.loadContainers();
    });
  }

  @override
  void dispose() {
    _refController.dispose();
    _weightController.dispose();
    _cbnController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  bool _validateStep1() {
    if (_refController.text.isEmpty) {
      showErrorTopSnackBar(context, "Veuillez entrer une référence");
      return false;
    }
    final provider = context.read<PackageProvider>();
    if (provider.expeditionType == 'Avion' && _weightController.text.isEmpty) {
      showErrorTopSnackBar(context, "Veuillez entrer un poids");
      return false;
    }
    if (provider.expeditionType == 'Bateau' && _cbnController.text.isEmpty) {
      showErrorTopSnackBar(context, "Veuillez entrer un CBN");
      return false;
    }
    if (_quantityController.text.isEmpty) {
      showErrorTopSnackBar(context, "Veuillez entrer le nombre de cartons");
      return false;
    }
    if (provider.selectedClient == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un client");
      return false;
    }
    return true;
  }

  Future<void> _handleSubmit() async {
    final provider = context.read<PackageProvider>();
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
      containerId: provider.selectedContainer?.id ?? 0,
      context: context,
    );

    if (success) {
      Navigator.pop(context, true);
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Ajouter un nouveau colis",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
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
                          index: provider.currentStep,
                          children: [
                            _buildStep1(provider),
                            _buildStep2(provider),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildNavigationButtons(provider),
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
                          return 'Ce champ est requis';
                        if (double.tryParse(value!) == null) {
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
                        if (value?.isEmpty ?? true)
                          return 'Ce champ est requis';
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
        _buildClientSelector(provider),
        const SizedBox(height: 20),
        _buildContainerSelector(provider)
      ],
    );
  }

  Widget _buildStep2(PackageProvider provider) {
    return ListView(
      children: [
        _buildCountrySelector(
          label: 'Pays de départ',
          selectedCountry: provider.departureCountry,
          onCountrySelected: (country) {
            provider.departureCountry = country;
          },
        ),
        const SizedBox(height: 20),
        _buildCountrySelector(
          label: 'Pays d\'arrivée',
          selectedCountry: provider.arrivalCountry,
          onCountrySelected: (country) {
            provider.arrivalCountry = country;
          },
        ),
        const SizedBox(height: 20),
        DatePickerField(
          label: "Date de départ",
          selectedDate: provider.startDate,
          onDateSelected: (date) {
            provider.startDate = date;
          },
        ),
        const SizedBox(height: 20),
        DatePickerField(
          label: "Date d'arrivée estimée",
          selectedDate: provider.estimatedArrivalDate,
          onDateSelected: (date) {
            provider.estimatedArrivalDate = date;
          },
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(PackageProvider provider) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(
          children: [
            if (provider.currentStep > 0)
              Expanded(
                child: TextButton.icon(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    provider.currentStep--;
                  },
                  label: Text("Retour"),
                ),
              ),
            if (provider.currentStep == 0)
              Expanded(
                child: confirmationButton(
                  isLoading: false,
                  label: "Suivant",
                  onPressed: () {
                    if (_validateStep1()) {
                      provider.currentStep++;
                    }
                  },
                  icon: Icons.arrow_forward_ios,
                  subLabel: "Chargement...",
                ),
              )
            else
              Expanded(
                child: confirmationButton(
                  isLoading: provider.isLoading,
                  label: "Enregistrer",
                  subLabel: "Enregistrement...",
                  icon: Icons.check,
                  onPressed: _handleSubmit,
                ),
              ),
          ],
        ),
      ),
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

  Widget _buildClientSelector(PackageProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          flex: 3,
          child: DropDownCustom<Partner>(
            items: provider.clients,
            selectedItem: provider.selectedClient,
            onChanged: (client) {
              provider.selectedClient = client;
            },
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
                provider.loadClients();
              });
            },
            icon: Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildContainerSelector(PackageProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 10,
      children: [
        Expanded(
          flex: 4,
          child: DropDownCustom<Containers>(
            items: provider.container,
            selectedItem: provider.selectedContainer,
            onChanged: (container) {
              setState(() {
                provider.selectedContainer = container;
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
            onPressed: () => {
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
                provider
                    .loadContainers(); // Recharger la liste des clients après la création
              }),
            },
            icon: const Icon(Icons.add),
          ),
        ),
      ],
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
          countryListTheme: CountryListThemeData(
            flagSize: 25,
            backgroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16),
            bottomSheetHeight: 300,
            borderRadius: const BorderRadius.only(
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
}
