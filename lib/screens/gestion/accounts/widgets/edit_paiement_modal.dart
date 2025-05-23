import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/components/date_picker.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

class EditPaiementModal extends StatefulWidget {
  final Versement versement;
  final Function() onPaiementUpdated;

  const EditPaiementModal({
    super.key,
    required this.versement,
    required this.onPaiementUpdated,
  });

  @override
  State<EditPaiementModal> createState() => _EditPaiementModalState();
}

class _EditPaiementModalState extends State<EditPaiementModal> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  DateTime? myDate;

  final TextEditingController montantVerserController = TextEditingController();

  final AuthService authService = AuthService();
  final PartnerServices partnerServices = PartnerServices();
  final VersementServices versementServices = VersementServices();

  List<Partner> clients = [];
  Partner? selectedClient;

  @override
  void initState() {
    super.initState();
    montantVerserController.text =
        widget.versement.montantVerser?.toString() ?? '0';
    myDate = widget.versement.createdAt ?? DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final clientData = await partnerServices.findAll(page: 0);

      if (clientData.isNotEmpty) {
        if (widget.versement.clientId != null) {
          selectedClient = clientData.firstWhere(
            (c) => c.id == widget.versement.clientId,
            orElse: () => clientData.first,
          );
        } else if (widget.versement.partnerName != null) {
          selectedClient = clientData.firstWhere(
            (c) =>
                '${c.firstName} ${c.lastName}' == widget.versement.partnerName,
            orElse: () => clientData.first,
          );
        } else {
          selectedClient = clientData.first;
        }
      }

      setState(() {
        clients = clientData;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
      if (mounted) {
        showErrorTopSnackBar(context, "Erreur lors du chargement des données");
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
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

      final montant = double.tryParse(montantVerserController.text) ?? 0.0;

      final versementDto = Versement.fromJson({
        "montantVerser": montant,
        "createdAt": myDate!.toIso8601String(),
      });

      final success = await versementServices.updatePaiement(
        widget.versement.id!,
        user.id,
        selectedClient!.id,
        versementDto,
      );

      if (success) {
        widget.onPaiementUpdated();
        if (mounted) {
          Navigator.pop(context);
          showSuccessTopSnackBar(context, "Versement modifié avec succès !");
        }
      } else {
        showErrorTopSnackBar(context, "Erreur lors de la modification");
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          "Erreur lors de la modification: ${e.toString()}",
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Modifier le paiement",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(widget.versement.reference!),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Expanded(
                      child: ListView(
                        children: [
                          buildTextField(
                            controller: montantVerserController,
                            label: "Montant versé",
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          DropDownCustom<Partner>(
                            items: clients,
                            selectedItem: selectedClient,
                            onChanged: (client) {
                              setState(() {
                                selectedClient = client;
                              });
                            },
                            itemToString:
                                (client) =>
                                    '${client.firstName + " " + client.lastName} | ${client.phoneNumber}',
                            hintText:
                                widget.versement.partnerName ??
                                'Choisir un client...',
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
                    label: "Enregistrer les modifications",
                    subLabel: "Modification...",
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
}
