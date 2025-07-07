import 'dart:async';
import 'dart:developer';

import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/components/date_picker.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/services/devises_service.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/models/devises.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/widgets/devise/devise_form.dart';
import 'package:bbd_limited/providers/devise_provider.dart';

class NewVersementModal extends ConsumerStatefulWidget {
  final Function(DateTime)? onDateChanged;
  final bool isVersementScreen;
  final String? clientId;
  final Function()? onVersementCreated;

  const NewVersementModal({
    super.key,
    this.onDateChanged,
    this.isVersementScreen = false,
    this.clientId,
    this.onVersementCreated,
  });

  @override
  ConsumerState<NewVersementModal> createState() => _NewVersementModalState();
}

class _NewVersementModalState extends ConsumerState<NewVersementModal>
    with SingleTickerProviderStateMixin {
  int currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  DateTime? myDate;

  final TextEditingController montantVerserController = TextEditingController();
  final TextEditingController commissionnaireNameController =
      TextEditingController();
  final TextEditingController commissionnairePhoneController =
      TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  final AuthService authService = AuthService();
  final PartnerServices partnerServices = PartnerServices();
  final VersementServices versementServices = VersementServices();
  final DeviseServices deviseServices = DeviseServices();

  // Stream controllers for error handling
  final StreamController<String> _errorStreamController =
      StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorStreamController.stream;

  bool _isLoading = false;

  List<Partner> clients = [];
  Partner? selectedCLients;

  List<Devise> devises = [];
  Devise? selectedDevise;

  int currentPage = 0;

  VersementType? selectedType;
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClientsData();
    _loadDevisesData();
  }

  Future<void> _loadClientsData() async {
    setState(() => isLoading = true);
    try {
      if (widget.isVersementScreen) {
        final clientData = await partnerServices.findCustomers(page: 0);
        setState(() {
          clients = clientData;
          isLoading = false;
        });
      } else if (widget.clientId != null) {
        final clientData = await partnerServices.findCustomers(page: 0);
        final client = clientData.firstWhere(
          (c) => c.id.toString() == widget.clientId,
          orElse: () => throw Exception("Client non trouvé"),
        );
        setState(() {
          selectedCLients = client;
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() => isLoading = false);
      showErrorTopSnackBar(context, "Erreur lors du chargement des données");
    }
  }

  Future<void> _loadDevisesData() async {
    setState(() => isLoading = true);
    try {
      final deviseData = await deviseServices.findAllDevises(page: 0);
      setState(() {
        devises = deviseData;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
      showErrorTopSnackBar(context, "Erreur lors du chargement des données");
    }
  }

  Future<void> _submitForm() async {
    try {
      // Validation des champs
      if (montantVerserController.text.isEmpty) {
        showErrorTopSnackBar(context, "Veuillez entrer un montant");
        return;
      }

      final montant = double.tryParse(montantVerserController.text) ?? 0.0;
      if (montant <= 0) {
        showErrorTopSnackBar(context, "Montant invalide");
        return;
      }

      if (widget.isVersementScreen && selectedCLients == null) {
        showErrorTopSnackBar(context, "Veuillez sélectionner un client");
        return;
      }

      if (myDate == null) {
        showErrorTopSnackBar(context, "Veuillez sélectionner une date");
        return;
      }

      if (selectedDevise == null || selectedDevise!.id == null) {
        showErrorTopSnackBar(
            context, "Veuillez sélectionner une devise valide");
        return;
      }

      if (selectedType == null) {
        showErrorTopSnackBar(
            context, "Veuillez sélectionner un type de versement");
        return;
      }

      setState(() => isLoading = true);

      final user = await authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context, "Erreur: Utilisateur non connecté");
        setState(() => isLoading = false);
        return;
      }

      final versementDto = Versement.fromJson({
        "montantVerser": montant,
        "createdAt": myDate!.toIso8601String(),
        "partnerId": widget.isVersementScreen
            ? selectedCLients!.id
            : int.tryParse(widget.clientId ?? ''),
        "commissionnaireName": commissionnaireNameController.text,
        "commissionnairePhone": commissionnairePhoneController.text,
        "type": selectedType.toString().split('.').last,
        "note": noteController.text,
      });

      final result = await versementServices.create(
        user.id,
        widget.isVersementScreen
            ? selectedCLients!.id
            : int.parse(widget.clientId!),
        selectedDevise!.id!,
        versementDto,
      );

      if (result != null) {
        widget.onVersementCreated?.call();
        Navigator.pop(context, true);
        showSuccessTopSnackBar(
          context,
          "Nouveau versement effectué avec succès",
        );
      }
    } catch (e) {
      showErrorTopSnackBar(context, "Erreur: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  bool _validateFirstStep() {
    if (montantVerserController.text.isEmpty) {
      showErrorTopSnackBar(context, "Veuillez entrer un montant");
      return false;
    }
    if (widget.isVersementScreen && selectedCLients == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un client");
      return false;
    }
    if (myDate == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner une date");
      return false;
    }
    if (selectedType == null) {
      showErrorTopSnackBar(
          context, "Veuillez sélectionner un type de versement");
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
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
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      currentStep == 0
                          ? "Informations du versement"
                          : currentStep == 1
                              ? "Informations du commissionnaire"
                              : "Note additionnelle",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Flexible(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: IndexedStack(
                    index: currentStep,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildTextField(
                            controller: montantVerserController,
                            label: "Montant à versé",
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 10),
                          DropDownCustom<VersementType>(
                            items: VersementType.values.toList(),
                            selectedItem: selectedType,
                            onChanged: (type) {
                              setState(() {
                                selectedType = type;
                              });
                            },
                            itemToString: (type) =>
                                type.toString().split('.').last,
                            hintText: 'Choisir un type de versement...',
                            prefixIcon: Icons.category,
                          ),
                          const SizedBox(height: 10),
                          if (widget.isVersementScreen)
                            DropDownCustom<Partner>(
                              items: clients,
                              selectedItem: selectedCLients,
                              onChanged: (client) {
                                setState(() {
                                  selectedCLients = client;
                                });
                              },
                              itemToString: (client) =>
                                  '${client.firstName} ${client.lastName} ${client.lastName.isNotEmpty ? '|' : ''}  ${client.phoneNumber}',
                              hintText: 'Choisir un client...',
                              prefixIcon: Icons.person_3,
                            ),
                          if (widget.isVersementScreen)
                            const SizedBox(height: 10),
                          DatePickerField(
                            label: "Date de paiement",
                            selectedDate: myDate,
                            onDateSelected: (date) {
                              setState(() {
                                myDate = date;
                              });
                            },
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildTextField(
                            controller: commissionnaireNameController,
                            label: "Nom complet du commissionnaire",
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 10),
                          buildTextField(
                            controller: commissionnairePhoneController,
                            label: "Téléphone du commissionnaire",
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: DropDownCustom<Devise>(
                                  items: devises,
                                  selectedItem: selectedDevise,
                                  onChanged: (currency) {
                                    setState(() {
                                      selectedDevise = currency;
                                    });
                                  },
                                  itemToString: (currency) => currency.code,
                                  hintText: 'Choisir une devise...',
                                  prefixIcon: Icons.currency_exchange,
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                onPressed: _showAddDeviseDialog,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: noteController,
                            decoration: InputDecoration(
                              labelText: "Note (optionnelle)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            maxLines: 6,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                child: Row(
                  children: [
                    if (currentStep > 0)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            currentStep--;
                          });
                        },
                        label: const Text("Retour"),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    if (currentStep > 0) const SizedBox(width: 10),
                    Expanded(
                      child: confirmationButton(
                        isLoading: isLoading,
                        label: currentStep == 2 ? "Enregistrer" : "Suivant",
                        subLabel: "Enregistrement...",
                        icon: currentStep == 2
                            ? Icons.check
                            : Icons.arrow_forward,
                        onPressed: currentStep == 2
                            ? _submitForm
                            : () {
                                if (_validateFirstStep()) {
                                  setState(() {
                                    currentStep++;
                                  });
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    montantVerserController.dispose();
    commissionnaireNameController.dispose();
    commissionnairePhoneController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _rateController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void _showAddDeviseDialog() {
    String? nameError;
    String? codeError;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(24),
                width: MediaQuery.of(context).size.width * 0.95,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            'Ajouter une nouvelle devise',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1E49),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    DeviseForm(
                      isLoading: _isLoading,
                      isEditing: false,
                      nameError: nameError,
                      codeError: codeError,
                      onSubmit: (name, code, rate) async {
                        setState(() => _isLoading = true);
                        try {
                          final user = await authService.getUserInfo();
                          if (user == null) {
                            showErrorTopSnackBar(
                                context, 'Session utilisateur invalide');
                            return;
                          }

                          final result = await ref
                              .read(deviseListProvider.notifier)
                              .createDevise(
                                name: name,
                                code: code,
                                rate: rate,
                                userId: user.id,
                              );

                          log("Résultat création devise: $result");

                          if (result == "SUCCESS") {
                            Navigator.pop(context);
                            showSuccessTopSnackBar(
                                context, 'Devise créée avec succès!');
                          } else if (result == "NAME_EXIST") {
                            showErrorTopSnackBar(
                                context, 'Le nom de devise existe déjà');
                          } else if (result == "CODE_EXIST") {
                            showErrorTopSnackBar(
                                context, 'Le code de devise existe déjà');
                          } else if (result == "RATE_NOT_FOUND") {
                            showErrorTopSnackBar(
                                context, 'Taux de conversion non trouvé');
                          } else if (result == "RATE_SERVICE_ERROR") {
                            showErrorTopSnackBar(
                                context, 'Erreur du service de taux');
                          } else if (result == "CONNECTION_ERROR") {
                            showErrorTopSnackBar(
                                context, 'Erreur de connexion');
                          } else {
                            // Affiche le message d'erreur tel quel s'il provient du backend
                            showErrorTopSnackBar(
                                context, result ?? 'Erreur inconnue');
                          }
                        } catch (e) {
                          showErrorTopSnackBar(
                              context, 'Erreur serveur: ${e.toString()}');
                        } finally {
                          setState(() => _isLoading = false);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
