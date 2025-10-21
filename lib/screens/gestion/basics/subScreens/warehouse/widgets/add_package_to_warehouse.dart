import 'package:flutter/material.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/providers/package_provider.dart';
import 'package:provider/provider.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/create_container_form.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/create_partner_bottom_sheet.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/date_picker.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/harbor.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/harbor/widgets/add_harbor.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PackageProvider>();
      provider.loadClients();
      provider.loadContainers();
      provider.loadHarbors();
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

  bool _validateCurrentStep(PackageProvider provider) {
    switch (provider.currentStep) {
      case 1:
        // Validation pour l'étape 2 (sélection des items)
        if (provider.selectedItemIds.isEmpty) {
          showErrorTopSnackBar(
              context, "Veuillez sélectionner au moins un item");
          return false;
        }
        return true;
      case 2:
        // Validation pour l'étape 3 (ports + dates)
        if (provider.selectedDepartureHarbor == null) {
          showErrorTopSnackBar(
              context, "Veuillez sélectionner un port de départ");
          return false;
        }
        if (provider.selectedArrivalHarbor == null) {
          showErrorTopSnackBar(
              context, "Veuillez sélectionner un port d'arrivée");
          return false;
        }
        if (provider.startDate == null) {
          showErrorTopSnackBar(
              context, "Veuillez sélectionner une date de départ");
          return false;
        }
        if (provider.estimatedArrivalDate == null) {
          showErrorTopSnackBar(
              context, "Veuillez sélectionner une date d'arrivée estimée");
          return false;
        }
        return true;
      case 3:
        // Validation pour l'étape 4 (conteneur)
        if (provider.selectedContainer == null) {
          showErrorTopSnackBar(context, "Veuillez sélectionner un conteneur");
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _handleSubmit() async {
    final provider = context.read<PackageProvider>();
    final weight = double.tryParse(_weightController.text);
    final cbn = double.tryParse(_cbnController.text);
    final quantity = double.tryParse(_quantityController.text);

    // Validations finales
    if (provider.selectedContainer == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un conteneur");
      return;
    }
    if (provider.selectedDepartureHarbor == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un port de départ");
      return;
    }
    if (provider.selectedArrivalHarbor == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un port d'arrivée");
      return;
    }
    if (provider.startDate == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner une date de départ");
      return;
    }
    if (provider.estimatedArrivalDate == null) {
      showErrorTopSnackBar(
          context, "Veuillez sélectionner une date d'arrivée estimée");
      return;
    }

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
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
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
                                "Ajouter un nouveau colis",
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
                            index: provider.currentStep,
                            children: [
                              // Étape 1 : Infos de base + sélection client
                              _buildStep1(provider),
                              // Étape 2 : Sélection des items
                              _buildItemSelectionStep(provider),
                              // Étape 3 : Ports + dates + conteneur
                              _buildStep2(provider),
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
                      child: _buildStepControls(provider),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepControls(PackageProvider provider) {
    if (provider.currentStep == 0) {
      return confirmationButton(
        isLoading: false,
        label: "Suivant",
        onPressed: () {
          if (_validateStep1()) {
            provider.currentStep++;
          }
        },
        icon: Icons.arrow_forward_ios,
        subLabel: "Chargement...",
      );
    } else if (provider.currentStep == 2) {
      return Row(
        children: [
          Expanded(
            child: TextButton.icon(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                provider.currentStep--;
              },
              label: const Text("Retour"),
            ),
          ),
          const SizedBox(width: 10),
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
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: TextButton.icon(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                provider.currentStep--;
              },
              label: const Text("Retour"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: confirmationButton(
              isLoading: false,
              label: "Suivant",
              onPressed: () {
                if (_validateCurrentStep(provider)) {
                  provider.currentStep++;
                }
              },
              icon: Icons.arrow_forward_ios,
              subLabel: "Chargement...",
            ),
          ),
        ],
      );
    }
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Ce champ est requis';
                        }
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        // Port de départ
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 4,
              child: DropDownCustom<Harbor>(
                items: provider.harbors,
                selectedItem: provider.selectedDepartureHarbor,
                onChanged: (harbor) {
                  provider.selectedDepartureHarbor = harbor;
                },
                itemToString: (harbor) => harbor.name ?? '',
                hintText: AppLocalizations.of(context)
                    .translate('choose_departure_port'),
                prefixIcon: Icons.sailing,
              ),
            ),
            Expanded(
              flex: 1,
              child: IconButton(
                onPressed: () {
                  showAddHarborModal(context).then((_) {
                    provider.loadHarbors();
                  });
                },
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
                items: provider.harbors,
                selectedItem: provider.selectedArrivalHarbor,
                onChanged: (harbor) {
                  provider.selectedArrivalHarbor = harbor;
                },
                itemToString: (harbor) => harbor.name ?? '',
                hintText: AppLocalizations.of(context)
                    .translate('choose_arrival_port'),
                prefixIcon: Icons.sailing,
              ),
            ),
            Expanded(
              flex: 1,
              child: IconButton(
                onPressed: () {
                  showAddHarborModal(context).then((_) {
                    provider.loadHarbors();
                  });
                },
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Date de départ
        DatePickerField(
          label: AppLocalizations.of(context).translate('departure_date'),
          selectedDate: provider.startDate,
          onDateSelected: (date) {
            provider.startDate = date;
          },
        ),
        const SizedBox(height: 20),
        // Date d'arrivée estimée
        DatePickerField(
          label:
              AppLocalizations.of(context).translate('estimated_arrival_date'),
          selectedDate: provider.estimatedArrivalDate,
          onDateSelected: (date) {
            provider.estimatedArrivalDate = date;
          },
        ),
        const SizedBox(height: 20),
        _buildContainerSelector(provider),
      ],
    );
  }

  Widget _buildItemSelectionStep(PackageProvider provider) {
    if (provider.isLoadingItems) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.eligibleItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun item éligible',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Veuillez sélectionner un client pour voir ses items.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView(
      children: [
        ...provider.eligibleItems.map((item) {
          return CheckboxListTile(
            value: provider.selectedItemIds.contains(item.id),
            onChanged: (selected) {
              if (selected == true) {
                provider.addSelectedItemId(item.id!);
              } else {
                provider.removeSelectedItemId(item.id!);
              }
            },
            title: Text(
              item.description ??
                  AppLocalizations.of(context).translate('no_description'),
              style: const TextStyle(fontSize: 16),
            ),
            subtitle: Text(
              '${AppLocalizations.of(context).translate('item_quantity_label')}: ${item.quantity?.toString() ?? "-"}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            secondary: Icon(
              Icons.inventory_2,
              color: provider.selectedItemIds.contains(item.id)
                  ? Colors.blue[700]
                  : Colors.grey[400],
            ),
          );
        }).toList()
      ],
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
                '${client.firstName} ${client.lastName} ${client.lastName.isNotEmpty ? '|' : ''} ${client.phoneNumber}',
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
            icon: const Icon(Icons.add),
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
              provider.selectedContainer = container;
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
                provider.loadContainers();
              }),
            },
            icon: const Icon(Icons.add),
          ),
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
}

Future<bool?> showAddPackageModal(BuildContext context, int warehouseId) async {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return ChangeNotifierProvider(
        create: (_) => PackageProvider(),
        child: AddPackageToWarehouseForm(warehouseId: warehouseId),
      );
    },
  );
}
