import 'package:flutter/material.dart';
import 'package:bbd_limited/models/expedition.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:intl/intl.dart';
import 'package:country_picker/country_picker.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/date_picker.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/core/services/partner_services.dart';

class EditExpeditionBottomSheet extends StatefulWidget {
  final Expedition expedition;
  final Function(Expedition) onSave;

  const EditExpeditionBottomSheet({
    Key? key,
    required this.expedition,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditExpeditionBottomSheet> createState() =>
      _EditExpeditionBottomSheetState();
}

class _EditExpeditionBottomSheetState extends State<EditExpeditionBottomSheet> {
  late TextEditingController _refController;
  late TextEditingController _clientNameController;
  late TextEditingController _clientPhoneController;
  late TextEditingController _weightController;
  late TextEditingController _cbnController;
  late TextEditingController _itemQuantityController;
  late DateTime _startDate;
  late DateTime _arrivalDate;
  late String _expeditionType;
  late String _startCountry;
  late String _destinationCountry;
  final _formKey = GlobalKey<FormState>();
  int currentStep = 0;
  bool isLoading = false;
  final PartnerServices _partnerServices = PartnerServices();
  List<Partner> _clients = [];
  Partner? _selectedClient;

  late String? clientFullname =
      '${widget.expedition.clientName ?? ''} | ${widget.expedition.clientPhone ?? ''}';

  @override
  void initState() {
    super.initState();
    _refController = TextEditingController(text: widget.expedition.ref);
    _clientNameController = TextEditingController(
      text: widget.expedition.clientName,
    );
    _clientPhoneController = TextEditingController(
      text: widget.expedition.clientPhone,
    );
    _weightController = TextEditingController(
      text: widget.expedition.weight?.toString(),
    );
    _cbnController = TextEditingController(
      text: widget.expedition.cbn?.toString(),
    );
    _itemQuantityController = TextEditingController(
      text: widget.expedition.itemQuantity?.toString(),
    );
    _startDate = widget.expedition.startDate ?? DateTime.now();
    _arrivalDate =
        widget.expedition.arrivalDate ??
        DateTime.now().add(const Duration(days: 7));
    _expeditionType =
        (widget.expedition.expeditionType ?? 'avion').toLowerCase();
    _startCountry = widget.expedition.startCountry ?? '';
    _destinationCountry = widget.expedition.destinationCountry ?? '';
    _loadClients();
  }

  Future<void> _loadClients() async {
    final clients = await _partnerServices.fetchPartnersByType(
      'CLIENT',
      page: 0,
    );
    setState(() {
      _clients = clients;
      _selectedClient = clients.firstWhere(
        (client) => client.firstName == widget.expedition.clientName,
        orElse: () => clients.first,
      );
    });
  }

  @override
  void dispose() {
    _refController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _weightController.dispose();
    _cbnController.dispose();
    _itemQuantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _arrivalDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _arrivalDate = picked;
        }
      });
    }
  }

  void _saveExpedition() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedExpedition = widget.expedition.copyWith(
      ref: _refController.text,
      weight: double.tryParse(_weightController.text),
      cbn: double.tryParse(_cbnController.text),
      itemQuantity: double.tryParse(_itemQuantityController.text),
      startDate: _startDate,
      arrivalDate: _arrivalDate,
      expeditionType: _expeditionType,
      startCountry: _startCountry,
      destinationCountry: _destinationCountry,
      clientName: _selectedClient?.firstName,
      clientPhone: _selectedClient?.phoneNumber,
    );

    widget.onSave(updatedExpedition);
    Navigator.pop(context);
  }

  void _goToNextStep() {
    if (currentStep == 0 && !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => currentStep++);
  }

  void _goToPreviousStep() {
    setState(() => currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                          "Modifier l'expédition",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
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
                        // Première étape
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
                                          value: 'bateau',
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
                                          value: 'avion',
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child:
                                      _expeditionType == 'avion'
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
                                    controller: _itemQuantityController,
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
                              hintText:
                                  clientFullname ?? 'Choisir un client...',
                              prefixIcon: Icons.person,
                            ),
                          ],
                        ),
                        // Deuxième étape
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
                                      _startCountry = country.name;
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
                                        Text(
                                          _startCountry.isNotEmpty
                                              ? _startCountry
                                              : 'Choisir un pays',
                                        ),
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
                                      _destinationCountry = country.name;
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
                                        Text(
                                          _destinationCountry.isNotEmpty
                                              ? _destinationCountry
                                              : 'Choisir un pays',
                                        ),
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
                              selectedDate: _arrivalDate,
                              onDateSelected: (date) {
                                setState(() {
                                  _arrivalDate = date;
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
            // Contrôles de navigation
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
              onPressed: _saveExpedition,
            ),
          ),
        ],
      );
    }
  }
}
