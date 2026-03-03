import 'dart:async';
import 'dart:developer';

import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
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
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/create_partner_bottom_sheet.dart';

class NewVersementModal extends ConsumerStatefulWidget {
  final Function(DateTime)? onDateChanged;
  final bool isVersementScreen;
  final String? clientId;
  final Function()? onVersementCreated;
  final Versement? versementToEdit; // Nouveau paramètre pour l'édition

  const NewVersementModal({
    super.key,
    this.onDateChanged,
    this.isVersementScreen = false,
    this.clientId,
    this.onVersementCreated,
    this.versementToEdit, // Nouveau paramètre optionnel
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
  final TextEditingController tauxUtiliseController = TextEditingController();

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
    _initializeFormData();
    _loadClientsData();
    _loadDevisesData();
  }

  void _initializeFormData() {
    if (widget.versementToEdit != null) {
      // Initialiser les champs avec les données du versement à modifier
      montantVerserController.text =
          widget.versementToEdit!.montantVerser?.toString() ?? '';
      commissionnaireNameController.text =
          widget.versementToEdit!.commissionnaireName ?? '';
      commissionnairePhoneController.text =
          widget.versementToEdit!.commissionnairePhone ?? '';
      noteController.text = widget.versementToEdit!.note ?? '';
      myDate = widget.versementToEdit!.createdAt ?? DateTime.now();
      // Taux : 1 si CNY, sinon valeur du versement (Flutter ne calcule jamais)
      if (widget.versementToEdit!.deviseCode == 'CNY') {
        tauxUtiliseController.text = '1';
      } else {
        tauxUtiliseController.text =
            widget.versementToEdit!.tauxUtilise?.toString() ?? '';
      }

      if (widget.versementToEdit!.type != null) {
        selectedType = VersementType.values.firstWhere(
          (type) =>
              type.toString().split('.').last == widget.versementToEdit!.type,
          orElse: () => VersementType.General,
        );
      }
    }
  }

  Future<void> _loadClientsData() async {
    setState(() => isLoading = true);
    try {
      if (widget.isVersementScreen) {
        final clientData = await partnerServices.findCustomers(page: 0);
        setState(() {
          clients = clientData;
          // Si on est en mode édition, sélectionner le client du versement
          if (widget.versementToEdit != null &&
              widget.versementToEdit!.partnerId != null) {
            selectedCLients = clientData.firstWhere(
              (c) => c.id == widget.versementToEdit!.partnerId,
              orElse: () => clientData.first,
            );
          }
          isLoading = false;
        });
      } else if (widget.clientId != null) {
        final clientData = await partnerServices.findCustomers(page: 0);
        final client = clientData.firstWhere(
          (c) => c.id.toString() == widget.clientId,
          orElse: () => throw Exception(
              AppLocalizations.of(context).translate('client_not_found')),
        );
        setState(() {
          selectedCLients = client;
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() => isLoading = false);
      showErrorTopSnackBar(context,
          AppLocalizations.of(context).translate('error_loading_data'));
    }
  }

  Future<void> _loadDevisesData() async {
    setState(() => isLoading = true);
    try {
      final deviseData = await deviseServices.findAllDevises(page: 0);
      setState(() {
        devises = deviseData;
        // Si on est en mode édition, sélectionner la devise du versement
        if (widget.versementToEdit != null &&
            widget.versementToEdit!.deviseCode != null) {
          selectedDevise = deviseData.firstWhere(
            (d) => d.code == widget.versementToEdit!.deviseCode,
            orElse: () => deviseData.first,
          );
        }
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
      showErrorTopSnackBar(context,
          AppLocalizations.of(context).translate('error_loading_data'));
    }
  }

  Future<void> _submitForm() async {
    try {
      // Validation des champs
      if (montantVerserController.text.isEmpty) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('please_enter_amount'));
        return;
      }

      final montant = double.tryParse(montantVerserController.text) ?? 0.0;
      if (montant <= 0) {
        showErrorTopSnackBar(
            context, AppLocalizations.of(context).translate('invalid_amount'));
        return;
      }

      if (widget.isVersementScreen && selectedCLients == null) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('please_select_client'));
        return;
      }

      if (myDate == null) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('please_select_date'));
        return;
      }

      if (selectedDevise == null || selectedDevise!.id == null) {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('please_select_valid_currency'));
        return;
      }

      // Taux : obligatoire si devise != CNY ; fixé à 1 si devise = CNY (Flutter ne calcule jamais)
      final double tauxUtilise;
      if (selectedDevise!.code == 'CNY') {
        tauxUtilise = 1.0;
      } else {
        if (tauxUtiliseController.text.trim().isEmpty) {
          showErrorTopSnackBar(
              context,
              AppLocalizations.of(context)
                  .translate('rate_required_if_not_cny'));
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

      if (selectedType == null) {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('please_select_versement_type'));
        return;
      }

      final clientId = widget.isVersementScreen
          ? selectedCLients!.id
          : int.parse(widget.clientId!);

      setState(() => isLoading = true);

      final proceed = await _shouldProceedWithVersement(
        amount: montant,
        clientId: clientId,
      );

      if (!proceed) {
        setState(() => isLoading = false);
        return;
      }

      final user = await authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('user_not_connected'));
        setState(() => isLoading = false);
        return;
      }

      final versementDto = Versement.fromJson({
        "montantVerser": montant,
        "createdAt": myDate!.toIso8601String(),
        "partnerId": clientId,
        "commissionnaireName": commissionnaireNameController.text,
        "commissionnairePhone": commissionnairePhoneController.text,
        "type": selectedType.toString().split('.').last,
        "note": noteController.text,
        "deviseId": selectedDevise!.id,
        "deviseCode": selectedDevise!.code,
        "tauxUtilise": tauxUtilise,
      });

      bool success = false;
      String successMessage = '';

      if (widget.versementToEdit != null) {
        // Mode modification
        success = await versementServices.updatePaiement(
          widget.versementToEdit!.id!,
          user.id,
          clientId,
          versementDto,
        );
        successMessage =
            AppLocalizations.of(context).translate('versement_updated_success');
      } else {
        // Mode création
        final result = await versementServices.create(
          user.id,
          clientId,
          selectedDevise!.id!,
          versementDto,
        );
        success = result != null;
        successMessage =
            AppLocalizations.of(context).translate('new_versement_success');
      }

      if (success) {
        widget.onVersementCreated?.call();
        Navigator.pop(context, true);
        showSuccessTopSnackBar(context, successMessage);
      } else {
        showErrorTopSnackBar(
          context,
          widget.versementToEdit != null
              ? AppLocalizations.of(context).translate('versement_update_error')
              : AppLocalizations.of(context)
                  .translate('versement_creation_error'),
        );
      }
    } catch (e) {
      showErrorTopSnackBar(context, "Erreur: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showCreateClientBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePartnerBottomSheet(),
    ).then((_) {
      _loadClientsData(); // Recharger la liste des clients après la création
    });
  }

  Widget _buildRateToCnyField() {
    final isCny = selectedDevise?.code == 'CNY';
    final label = isCny
        ? AppLocalizations.of(context).translate('rate_to_cny_fixed')
        : AppLocalizations.of(context)
            .translate('rate_to_cny_label')
            .replaceAll('%s', selectedDevise?.code ?? '');
    return buildTextField(
      controller: tauxUtiliseController,
      label: label,
      icon: Icons.trending_up,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      readOnly: isCny,
    );
  }

  bool _validateFirstStep() {
    if (widget.isVersementScreen && selectedCLients == null) {
      showErrorTopSnackBar(context,
          AppLocalizations.of(context).translate('please_select_client'));
      return false;
    }
    if (montantVerserController.text.isEmpty) {
      showErrorTopSnackBar(context,
          AppLocalizations.of(context).translate('please_enter_amount'));
      return false;
    }
    if (selectedType == null) {
      showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('please_select_versement_type'));
      return false;
    }
    if (selectedDevise == null || selectedDevise!.id == null) {
      showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('please_select_valid_currency'));
      return false;
    }
    // Taux : obligatoire si devise != CNY ; si CNY, pas de saisie requise (fixé à 1)
    if (selectedDevise!.code != 'CNY') {
      if (tauxUtiliseController.text.trim().isEmpty) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('rate_required_if_not_cny'));
        return false;
      }
      final tauxUtilise = double.tryParse(tauxUtiliseController.text.trim());
      if (tauxUtilise == null || tauxUtilise <= 0) {
        showErrorTopSnackBar(
            context, AppLocalizations.of(context).translate('invalid_rate'));
        return false;
      }
    }
    return true;
  }

  Future<bool> _shouldProceedWithVersement({
    required double amount,
    required int clientId,
  }) async {
    final localizations = AppLocalizations.of(context);
    try {
      final versements = await versementServices.getByClient(clientId);
      final hasDuplicate = versements.any((versement) {
        if (widget.versementToEdit != null &&
            versement.id == widget.versementToEdit!.id) {
          return false;
        }
        final existingAmount = versement.montantVerser ?? 0;
        return (existingAmount - amount).abs() < 0.01;
      });

      if (!hasDuplicate) {
        return true;
      }

      final userChoice = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            localizations.translate('duplicate_deposit_title'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Text(
            localizations.translate('duplicate_deposit_message'),
            style: TextStyle(
              color: Colors.grey[800],
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                localizations.translate('cancel'),
                style: const TextStyle(color: Colors.black87),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                localizations.translate('continue_deposit'),
              ),
            ),
          ],
        ),
      );

      return userChoice ?? false;
    } catch (e) {
      showErrorTopSnackBar(
        context,
        '${localizations.translate('unknown_error')}: ${e.toString()}',
      );
      return false;
    }
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
                      widget.versementToEdit != null
                          ? (currentStep == 0
                              ? AppLocalizations.of(context)
                                  .translate('edit_versement_information')
                              : currentStep == 1
                                  ? AppLocalizations.of(context).translate(
                                      'edit_date_and_commissionnaire')
                                  : AppLocalizations.of(context)
                                      .translate('edit_additional_note'))
                          : (currentStep == 0
                              ? AppLocalizations.of(context)
                                  .translate('versement_information')
                              : currentStep == 1
                                  ? AppLocalizations.of(context)
                                      .translate('date_and_commissionnaire')
                                  : AppLocalizations.of(context)
                                      .translate('additional_note')),
                      style: AppTextSize.titleStyle(context)
                          .copyWith(letterSpacing: -0.5),
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
                          if (widget.isVersementScreen)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropDownCustom<Partner>(
                                    items: clients,
                                    selectedItem: selectedCLients,
                                    onChanged: (client) {
                                      setState(() {
                                        selectedCLients = client;
                                      });
                                    },
                                    itemToString: (client) =>
                                        '${client.firstName} ${client.lastName} ${client.lastName.isNotEmpty ? '|' : ''}  ${client.phoneNumber}',
                                    hintText: AppLocalizations.of(context)
                                        .translate('choose_client'),
                                    prefixIcon: Icons.person_3,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: IconButton(
                                    onPressed: _showCreateClientBottomSheet,
                                    icon: const Icon(Icons.add),
                                  ),
                                ),
                              ],
                            ),
                          if (widget.isVersementScreen)
                            const SizedBox(height: 10),
                          buildTextField(
                            controller: montantVerserController,
                            label: AppLocalizations.of(context)
                                .translate('amount_to_pay'),
                            icon: Icons.attach_money,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
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
                            hintText: AppLocalizations.of(context)
                                .translate('choose_versement_type'),
                            prefixIcon: Icons.category,
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
                                      // CNY : taux fixé à 1 (non éditable). Sinon pré-remplir depuis la devise (suggestion uniquement)
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
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                onPressed: _showAddDeviseDialog,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildRateToCnyField(),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildTextField(
                            controller: commissionnaireNameController,
                            label: AppLocalizations.of(context)
                                .translate('commissionnaire_full_name'),
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 10),
                          buildTextField(
                            controller: commissionnairePhoneController,
                            label: AppLocalizations.of(context)
                                .translate('commissionnaire_phone'),
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 10),
                          DatePickerField(
                            label: AppLocalizations.of(context)
                                .translate('payment_date'),
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
                          TextFormField(
                            controller: noteController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)
                                  .translate('note_optional'),
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
                        label: Text(
                            AppLocalizations.of(context).translate('back')),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    if (currentStep > 0) const SizedBox(width: 10),
                    Expanded(
                      child: confirmationButton(
                        isLoading: isLoading,
                        label: currentStep == 2
                            ? AppLocalizations.of(context).translate('save')
                            : AppLocalizations.of(context).translate('next'),
                        subLabel:
                            AppLocalizations.of(context).translate('saving'),
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
    tauxUtiliseController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void _showAddDeviseDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).translate('add_new_devise'),
                      style: AppTextSize.headlineStyle(context,
                          color: const Color(0xFF1A1E49)),
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
                onSubmit: (name, code, rate) async {
                  setState(() => _isLoading = true);
                  try {
                    final user = await authService.getUserInfo();
                    if (user == null) {
                      showErrorTopSnackBar(
                          context,
                          AppLocalizations.of(context)
                              .translate('invalid_user_session'));
                      return;
                    }

                    final result = await ref
                        .read(deviseListProvider.notifier)
                        .createDevise(
                          name: name,
                          code: code,
                          rateToCny: rate,
                          userId: user.id,
                        );

                    log("Résultat création devise: $result");

                    if (result == "SUCCESS") {
                      Navigator.pop(context);
                      await _loadDevisesData();
                      showSuccessTopSnackBar(
                          context,
                          AppLocalizations.of(context)
                              .translate('devise_created_success'));
                    } else if (result == "NAME_EXIST") {
                      showErrorTopSnackBar(
                          context,
                          AppLocalizations.of(context)
                              .translate('devise_name_exists'));
                    } else if (result == "CODE_EXIST") {
                      showErrorTopSnackBar(
                          context,
                          AppLocalizations.of(context)
                              .translate('devise_code_exists'));
                    } else if (result == "RATE_NOT_FOUND") {
                      showErrorTopSnackBar(
                          context,
                          AppLocalizations.of(context)
                              .translate('exchange_rate_not_found'));
                    } else if (result == "RATE_SERVICE_ERROR") {
                      showErrorTopSnackBar(
                          context,
                          AppLocalizations.of(context)
                              .translate('exchange_rate_service_error'));
                    } else if (result == "CONNECTION_ERROR") {
                      showErrorTopSnackBar(
                          context,
                          AppLocalizations.of(context)
                              .translate('network_error'));
                    } else {
                      showErrorTopSnackBar(
                          context,
                          result ??
                              AppLocalizations.of(context)
                                  .translate('unknown_error'));
                    }
                  } catch (e) {
                    showErrorTopSnackBar(context,
                        '${AppLocalizations.of(context).translate('server_error')}: ${e.toString()}');
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
