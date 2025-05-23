import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/expedition_services.dart';
import 'package:bbd_limited/models/expedition.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/date_picker.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/core/services/partner_services.dart';

class CreateExpeditionForm extends StatefulWidget {
  final bool isExpeditionScreen;
  final String? clientId;
  final Function()? onExpeditionCreated;
  const CreateExpeditionForm({
    super.key,
    this.isExpeditionScreen = false,
    this.clientId,
    this.onExpeditionCreated,
  });

  @override
  _CreateExpeditionFormState createState() => _CreateExpeditionFormState();
}

class _CreateExpeditionFormState extends State<CreateExpeditionForm> {
  final _formKey = GlobalKey<FormState>();
  final PartnerServices _partnerServices = PartnerServices();

  final AuthService authService = AuthService();
  final ExpeditionServices expeditionServices = ExpeditionServices();

  final TextEditingController _refController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _cbnController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  String _expeditionType = 'Bateau';
  Country? _departureCountry;
  Country? _arrivalCountry;
  DateTime? _startDate;
  DateTime? _estimatedArrivalDate;
  List<Partner> _clients = [];
  Partner? _selectedClient;
  bool isLoading = false;
  int currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final clients = await _partnerServices.fetchPartnersByType(
      'CLIENT',
      page: 0,
    );
    setState(() {
      _clients = clients;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        constraints: BoxConstraints(
          maxHeight:
              widget.isExpeditionScreen == true
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
                      Expanded(
                        child: Text(
                          "Ajouter une expédition",
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
                        // Step 1
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
                              validator:
                                  (value) =>
                                      value?.isEmpty ?? true
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
                                  child:
                                      _expeditionType == 'Avion'
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
                                    icon:
                                        Icons
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

                            if (widget.isExpeditionScreen)
                              DropDownCustom<Partner>(
                                items: _clients,
                                selectedItem: _selectedClient,
                                onChanged: (client) {
                                  setState(() {
                                    _selectedClient = client;
                                  });
                                },
                                itemToString:
                                    (client) =>
                                        '${client.firstName} ${client.lastName} | ${client.phoneNumber}',
                                hintText: 'Choisir un client...',
                                prefixIcon: Icons.person,
                              ),
                          ],
                        ),
                        // Step 2
                        ListView(
                          children: [
                            // Pays de départ
                            InkWell(
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
                                  onSelect: (Country country) {
                                    setState(() {
                                      _departureCountry = country;
                                    });
                                  },
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pays de départ',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        _departureCountry != null
                                            ? Row(
                                              children: [
                                                Text(
                                                  _departureCountry!.flagEmoji,
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(_departureCountry!.name),
                                              ],
                                            )
                                            : const Text('Choisir un pays'),
                                      ],
                                    ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Pays d'arrivée
                            InkWell(
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
                                  onSelect: (Country country) {
                                    setState(() {
                                      _arrivalCountry = country;
                                    });
                                  },
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pays d\'arrivée',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        _arrivalCountry != null
                                            ? Row(
                                              children: [
                                                Text(
                                                  _arrivalCountry!.flagEmoji,
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(_arrivalCountry!.name),
                                              ],
                                            )
                                            : const Text('Choisir un pays'),
                                      ],
                                    ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
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

  Future<void> _submitForm() async {
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
        }
      } else if (_expeditionType == "Bateau") {
        if (cbn == null) {
          showErrorTopSnackBar(context, "Le cbn est invalid");
        }
      }

      // Création du DTO
      final dto = Expedition.fromJson({
        "ref": _refController.text.trim(),
        "weight": weight,
        "itemQuantity": quantity,
        "cbn": cbn,
        "startDate": _startDate?.toUtc().toIso8601String(),
        "arrivalDate": _estimatedArrivalDate?.toUtc().toIso8601String(),
        "expeditionType": _expeditionType,
        "startCountry": _departureCountry!.name,
        "destinationCountry": _arrivalCountry!.name,
      });

      // Appel au service avec les IDs corrects
      final result = await expeditionServices.create(
        dto: dto,
        clientId:
            widget.isExpeditionScreen
                ? _selectedClient!.id
                : int.parse(widget.clientId!),
        userId: user.id,
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

  void _goToNextStep() {
    if (currentStep == 0 && !_formKey.currentState!.validate()) {
      return;
    }

    if (currentStep == 1) {
      String? errorMessage;

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

  Widget _buildStepControls() {
    if (currentStep == 0) {
      return confirmationButton(
        isLoading: false,
        label: "Suivant",
        onPressed: _goToNextStep,
        icon: Icons.arrow_forward_ios,
        subLabel: "Chargement...",
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
}
