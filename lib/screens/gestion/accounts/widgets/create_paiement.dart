import 'dart:developer';

import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/components/date_picker.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';

class CreatePaiementModal extends StatefulWidget {
  final Function(DateTime)? onDateChanged;
  const CreatePaiementModal({super.key, this.onDateChanged});

  @override
  State<CreatePaiementModal> createState() => _CreatePaiementModalState();
}

class _CreatePaiementModalState extends State<CreatePaiementModal>
    with SingleTickerProviderStateMixin {
  int currentStep = 0;
  final _formKeyStep1 = GlobalKey<FormState>();
  bool isLoading = false;
  DateTime? myDate;

  final TextEditingController montantVerserController = TextEditingController();

  final AuthService authService = AuthService();
  final PartnerServices partnerServices = PartnerServices();
  final VersementServices versementServices = VersementServices();

  List<Partner> clients = [];
  Partner? selectedCLients;

  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final clientData = await partnerServices.findAll(page: 0);

      setState(() {
        clients = clientData;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
      showErrorTopSnackBar(context, "Erreur lors du chargement des données");
    }
  }

  Future<void> _submitForm() async {
    if (montantVerserController.text.isEmpty) {
      showErrorTopSnackBar(context, "Veuillez entrer un montant");
      return;
    }
    if (selectedCLients == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un client");
      return;
    }
    if (myDate == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner une date");
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = await authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context, "Erreur: Utilisateur non connecté");
        setState(() => isLoading = false);
        return;
      }

      final versementDto = Versement.fromJson({
        "montantVerser": double.tryParse(montantVerserController.text),
        "createdAt": myDate!.toIso8601String(),
      });

      final result = await versementServices.create(
        user.id,
        selectedCLients!.id,
        versementDto,
      );

      if (result == "CREATED") {
        Navigator.pop(context, true);
        showSuccessTopSnackBar(
          context,
          "Nouveau versement effectué avec succès",
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      showErrorTopSnackBar(context, "Erreur: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
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
            maxHeight: MediaQuery.of(context).size.height * 0.5,
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
                        Text(
                          "Effectuer un paiement",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                          ListView(
                            children: [
                              buildTextField(
                                controller: montantVerserController,
                                label: "Montant à versé",
                                icon: Icons.attach_money,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 20),
                              DropDownCustom<Partner>(
                                items: clients,
                                selectedItem: selectedCLients,
                                onChanged: (client) {
                                  setState(() {
                                    selectedCLients = client;
                                  });
                                },
                                itemToString:
                                    (client) =>
                                        '${client.firstName + " " + client.lastName} | ${client.phoneNumber}',
                                hintText: 'Choisir un client...',
                                prefixIcon: Icons.person_3,
                              ),
                              const SizedBox(height: 20),
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
                  child: confirmationButton(
                    isLoading: isLoading,
                    label: "Enregistrer",
                    subLabel: "Enregistrement...",
                    icon: Icons.check,
                    onPressed: _submitForm,
                  ),
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
    super.dispose();
  }
}
