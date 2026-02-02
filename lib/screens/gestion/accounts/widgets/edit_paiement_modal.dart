import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/components/date_picker.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/devises_service.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/models/devises.dart';
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
  final TextEditingController tauxUtiliseController = TextEditingController();

  final AuthService authService = AuthService();
  final PartnerServices partnerServices = PartnerServices();
  final VersementServices versementServices = VersementServices();
  final DeviseServices deviseService = DeviseServices();

  List<Partner> clients = [];
  Partner? selectedClient;
  List<Devise> devises = [];
  Devise? selectedDevise;

  @override
  void initState() {
    super.initState();
    montantVerserController.text =
        widget.versement.montantVerser?.toString() ?? '0';
    myDate = widget.versement.createdAt ?? DateTime.now();
    if (widget.versement.deviseCode == 'CNY') {
      tauxUtiliseController.text = '1';
    } else {
      tauxUtiliseController.text =
          widget.versement.tauxUtilise?.toString() ?? '';
    }
    _loadData();
  }

  @override
  void dispose() {
    montantVerserController.dispose();
    tauxUtiliseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final clientData = await partnerServices.findCustomers(page: 0);
      final deviseData = await deviseService.findAllDevises(page: 0);

      if (clientData.isNotEmpty) {
        if (widget.versement.partnerId != null) {
          selectedClient = clientData.firstWhere(
            (c) => c.id == widget.versement.partnerId,
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

      Devise? initialDevise;
      if (widget.versement.deviseCode != null && deviseData.isNotEmpty) {
        try {
          initialDevise = deviseData.firstWhere(
            (d) => d.code == widget.versement.deviseCode,
            orElse: () => deviseData.first,
          );
        } catch (_) {}
      }

      setState(() {
        clients = clientData;
        devises = deviseData;
        selectedDevise = initialDevise;
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

    final montant = double.tryParse(montantVerserController.text) ?? 0.0;
    if (montant <= 0) {
      showErrorTopSnackBar(
          context, AppLocalizations.of(context).translate('invalid_amount'));
      return;
    }
    if (selectedDevise == null || selectedDevise!.id == null) {
      showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('please_select_valid_currency'));
      return;
    }
    final double tauxUtilise;
    if (selectedDevise!.code == 'CNY') {
      tauxUtilise = 1.0;
    } else {
      if (tauxUtiliseController.text.trim().isEmpty) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('rate_required_if_not_cny'));
        return;
      }
      final parsed = double.tryParse(tauxUtiliseController.text.trim());
      if (parsed == null || parsed <= 0) {
        showErrorTopSnackBar(
            context, AppLocalizations.of(context).translate('invalid_rate'));
        return;
      }
      tauxUtilise = parsed;
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
        "montantVerser": montant,
        "createdAt": myDate!.toIso8601String(),
        "partnerId": selectedClient!.id,
        "deviseId": selectedDevise!.id,
        "deviseCode": selectedDevise!.code,
        "tauxUtilise": tauxUtilise,
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
                            label: AppLocalizations.of(context)
                                .translate('amount_to_pay'),
                            icon: Icons.attach_money,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                          const SizedBox(height: 20),
                          DropDownCustom<Devise>(
                            items: devises,
                            selectedItem: selectedDevise,
                            onChanged: (currency) {
                              setState(() {
                                selectedDevise = currency;
                                if (currency?.code == 'CNY') {
                                  tauxUtiliseController.text = '1';
                                } else if (currency?.rate != null) {
                                  tauxUtiliseController.text =
                                      currency!.rate.toString();
                                } else {
                                  tauxUtiliseController.clear();
                                }
                              });
                            },
                            itemToString: (currency) => currency.code,
                            hintText: AppLocalizations.of(context)
                                .translate('choose_currency'),
                            prefixIcon: Icons.currency_exchange,
                          ),
                          const SizedBox(height: 20),
                          buildTextField(
                            controller: tauxUtiliseController,
                            label: selectedDevise?.code == 'CNY'
                                ? AppLocalizations.of(context)
                                    .translate('rate_to_cny_fixed')
                                : AppLocalizations.of(context)
                                    .translate('rate_to_cny_label')
                                    .replaceAll(
                                        '%s', selectedDevise?.code ?? ''),
                            icon: Icons.trending_up,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            readOnly: selectedDevise?.code == 'CNY',
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
                            itemToString: (client) =>
                                '${client.firstName + " " + client.lastName} | ${client.phoneNumber}',
                            hintText: widget.versement.partnerName ??
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
