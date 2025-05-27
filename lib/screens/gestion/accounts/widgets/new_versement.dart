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

class NewVersementModal extends StatefulWidget {
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
  State<NewVersementModal> createState() => _NewVersementModalState();
}

class _NewVersementModalState extends State<NewVersementModal>
    with SingleTickerProviderStateMixin {
  int currentStep = 0;
  final _formKey = GlobalKey<FormState>();
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

  Future<void> _submitForm() async {
    if (montantVerserController.text.isEmpty) {
      showErrorTopSnackBar(context, "Veuillez entrer un montant");
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
        "clientId":
            widget.isVersementScreen
                ? selectedCLients!.id
                : int.parse(widget.clientId!),
      });

      final result = await versementServices.create(
        user.id,
        widget.isVersementScreen
            ? selectedCLients!.id
            : int.parse(widget.clientId!),
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
      setState(() => isLoading = false);
      showErrorTopSnackBar(context, "Erreur: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
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
            maxHeight:
                widget.isVersementScreen == true
                    ? MediaQuery.of(context).size.height * 0.45
                    : MediaQuery.of(context).size.height * 0.35,
          ),
          child: Stack(
            children: [
              /// 🧱 Contenu principal scrollable
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Effectuer un nouveau versement",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
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
                              if (widget.isVersementScreen)
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
                                          '${client.firstName} ${client.lastName} | ${client.phoneNumber}',
                                  hintText: 'Choisir un client...',
                                  prefixIcon: Icons.person_3,
                                ),
                              if (widget.isVersementScreen)
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
