import 'package:flutter/material.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/container_info_form.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart'; // <-- à créer
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/models/partner.dart'; // Import correct pour Partner
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class CreateContainerForm extends StatefulWidget {
  const CreateContainerForm({super.key});

  @override
  State<CreateContainerForm> createState() => _CreateContainerFormState();
}

class _CreateContainerFormState extends State<CreateContainerForm> {
  int currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _containerInfoKey = GlobalKey<ContainerInfoFormState>();
  final _mainFeesFormKey = GlobalKey<FormState>();
  final _extraFeesFormKey = GlobalKey<ExtraFeesFormState>();

  // Store form values
  bool isAvailable = false;
  Partner? selectedSupplier;

  final TextEditingController refController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();

  // Fees controllers
  final TextEditingController locationFeeController = TextEditingController();
  final TextEditingController localChargeController = TextEditingController();
  final TextEditingController loadingFeeController = TextEditingController();
  final TextEditingController overweightFeeController = TextEditingController();
  final TextEditingController checkingFeeController = TextEditingController();
  final TextEditingController telxFeeController = TextEditingController();
  final TextEditingController otherFeesController = TextEditingController();
  final TextEditingController marginController = TextEditingController();

  bool isLoading = false;

  final AuthService authService = AuthService();
  final ContainerServices containerService = ContainerServices();

  void _goToNextStep() {
    if (currentStep == 0) {
      final valid = _formKey.currentState?.validate() ?? false;
      if (valid) {
        setState(() => currentStep = 1);
      } else {
        print('[DEBUG] Échec validation étape 1');
      }
    } else if (currentStep == 1) {
      final valid = _mainFeesFormKey.currentState?.validate() ?? false;
      if (valid) {
        setState(() => currentStep = 2);
      }
    }
  }

  void _goToPreviousStep() {
    if (currentStep > 0) {
      setState(() => currentStep -= 1);
    }
  }

  Future<void> _submitForm() async {
    setState(() => isLoading = true);
    try {
      final user = await authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context)!.translate('user_not_connected'));
        return;
      }
      final reference = refController.text.trim();
      final size = sizeController.text.trim();
      // Conversion des champs de frais en double
      double parseFee(String text) {
        final value = text.trim();
        return value.isEmpty ? 0.0 : (double.tryParse(value) ?? 0.0);
      }

      final response = await containerService.create(
        reference,
        size,
        isAvailable,
        user.id.toInt(),
        selectedSupplier?.id,
        parseFee(locationFeeController.text),
        parseFee(localChargeController.text),
        parseFee(loadingFeeController.text),
        parseFee(overweightFeeController.text),
        parseFee(checkingFeeController.text),
        parseFee(telxFeeController.text),
        parseFee(otherFeesController.text),
        parseFee(marginController.text),
      );
      if (response == "CREATED") {
        Navigator.pop(context, true);
        showSuccessTopSnackBar(context,
            AppLocalizations.of(context)!.translate('container_form_saved'));
      } else if (response == "NAME_EXIST") {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context)!.translate('container_form_error'));
      }
    } catch (e) {
      showErrorTopSnackBar(context,
          AppLocalizations.of(context)!.translate('container_form_error'));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Builder(
          builder: (context) {
            if (currentStep == 0) {
              return Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .translate('container_create'),
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ContainerInfoForm(
                      key: _containerInfoKey,
                      refController: refController,
                      size: sizeController,
                      initialAvailability: false,
                      onAvailabilityChanged: (value) {
                        setState(() {
                          isAvailable = value;
                        });
                      },
                      onSupplierChanged: (value) {
                        setState(() {
                          selectedSupplier = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: confirmationButton(
                          isLoading: false,
                          onPressed: _goToNextStep,
                          label:
                              AppLocalizations.of(context)!.translate('next'),
                          icon: Icons.arrow_forward,
                          subLabel: "",
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else if (currentStep == 1) {
              return Form(
                key: _mainFeesFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _goToPreviousStep,
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Text(
                          AppLocalizations.of(context)!
                              .translate('container_form_location_fee'),
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    MainFeesForm(
                      locationFeeController: locationFeeController,
                      localChargeController: localChargeController,
                      loadingFeeController: loadingFeeController,
                      getSupplier: () =>
                          _containerInfoKey.currentState?.selectedSupplier,
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: confirmationButton(
                          isLoading: false,
                          onPressed: _goToNextStep,
                          label:
                              AppLocalizations.of(context)!.translate('next'),
                          icon: Icons.arrow_forward,
                          subLabel: "",
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Form(
                key: _extraFeesFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _goToPreviousStep,
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Text(
                          AppLocalizations.of(context)!
                              .translate('container_form_other_fees'),
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ExtraFeesForm(
                      overweightFeeController: overweightFeeController,
                      checkingFeeController: checkingFeeController,
                      telxFeeController: telxFeeController,
                      otherFeesController: otherFeesController,
                      marginController: marginController,
                      locationFeeController: locationFeeController,
                      localChargeController: localChargeController,
                      loadingFeeController: loadingFeeController,
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: confirmationButton(
                          isLoading: isLoading,
                          onPressed: _submitForm,
                          label: AppLocalizations.of(context)!
                              .translate('container_form_save'),
                          icon: Icons.check_circle_outline_outlined,
                          subLabel: AppLocalizations.of(context)!
                              .translate('container_form_saving'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    refController.dispose();
    sizeController.dispose();
    locationFeeController.dispose();
    localChargeController.dispose();
    loadingFeeController.dispose();
    overweightFeeController.dispose();
    checkingFeeController.dispose();
    telxFeeController.dispose();
    otherFeesController.dispose();
    marginController.dispose();
    super.dispose();
  }
}

class MainFeesForm extends StatefulWidget {
  final TextEditingController locationFeeController;
  final TextEditingController localChargeController;
  final TextEditingController loadingFeeController;
  final Partner? Function() getSupplier;

  const MainFeesForm({
    super.key,
    required this.locationFeeController,
    required this.localChargeController,
    required this.loadingFeeController,
    required this.getSupplier,
  });

  @override
  State<MainFeesForm> createState() => MainFeesFormState();
}

class MainFeesFormState extends State<MainFeesForm> {
  bool validate() {
    final supplier = widget.getSupplier();
    final locationFee = widget.locationFeeController.text.trim();
    final localCharge = widget.localChargeController.text.trim();
    final loadingFee = widget.loadingFeeController.text.trim();
    print(
        '[DEBUG] locationFee="$locationFee" localCharge="$localCharge" loadingFee="$loadingFee" supplier=$supplier');
    if (supplier != null && locationFee.isEmpty) {
      showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)!
              .translate('container_form_validation_fees'));
      return false;
    }
    if (localCharge.isEmpty) {
      showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)!
              .translate('container_form_validation_fees'));
      return false;
    }
    if (loadingFee.isEmpty) {
      showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)!
              .translate('container_form_validation_fees'));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final supplier = widget.getSupplier();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTextField(
          controller: widget.locationFeeController,
          label: AppLocalizations.of(context)!
                  .translate('container_form_location_fee') +
              (supplier != null ? " *" : " (optionnel)"),
          icon: Icons.business,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (supplier != null && (value == null || value.isEmpty)) {
              return AppLocalizations.of(context)!
                  .translate('container_form_validation_fees');
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: widget.localChargeController,
          label: AppLocalizations.of(context)!
                  .translate('container_form_local_charge') +
              " *",
          icon: Icons.location_city,
          keyboardType: TextInputType.number,
          validator: (value) => value == null || value.isEmpty
              ? AppLocalizations.of(context)!
                  .translate('container_form_validation_fees')
              : null,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: widget.loadingFeeController,
          label: AppLocalizations.of(context)!
                  .translate('container_form_loading_fee') +
              " *",
          icon: Icons.local_shipping,
          keyboardType: TextInputType.number,
          validator: (value) => value == null || value.isEmpty
              ? AppLocalizations.of(context)!
                  .translate('container_form_validation_fees')
              : null,
        ),
      ],
    );
  }
}

class ExtraFeesForm extends StatefulWidget {
  final TextEditingController overweightFeeController;
  final TextEditingController checkingFeeController;
  final TextEditingController telxFeeController;
  final TextEditingController otherFeesController;
  final TextEditingController marginController;
  // Pour le calcul du total
  final TextEditingController locationFeeController;
  final TextEditingController localChargeController;
  final TextEditingController loadingFeeController;

  const ExtraFeesForm({
    super.key,
    required this.overweightFeeController,
    required this.checkingFeeController,
    required this.telxFeeController,
    required this.otherFeesController,
    required this.marginController,
    required this.locationFeeController,
    required this.localChargeController,
    required this.loadingFeeController,
  });

  @override
  State<ExtraFeesForm> createState() => ExtraFeesFormState();
}

class ExtraFeesFormState extends State<ExtraFeesForm> {
  double get totalFees {
    double sum = 0;
    sum += double.tryParse(widget.locationFeeController.text) ?? 0;
    sum += double.tryParse(widget.localChargeController.text) ?? 0;
    sum += double.tryParse(widget.loadingFeeController.text) ?? 0;
    sum += double.tryParse(widget.overweightFeeController.text) ?? 0;
    sum += double.tryParse(widget.checkingFeeController.text) ?? 0;
    sum += double.tryParse(widget.telxFeeController.text) ?? 0;
    sum += double.tryParse(widget.otherFeesController.text) ?? 0;
    return sum;
  }

  bool validate() {
    // Aucun champ obligatoire ici, marge optionnelle
    return true;
  }

  @override
  void initState() {
    super.initState();
    widget.locationFeeController.addListener(_onChanged);
    widget.localChargeController.addListener(_onChanged);
    widget.loadingFeeController.addListener(_onChanged);
    widget.overweightFeeController.addListener(_onChanged);
    widget.checkingFeeController.addListener(_onChanged);
    widget.telxFeeController.addListener(_onChanged);
    widget.otherFeesController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.locationFeeController.removeListener(_onChanged);
    widget.localChargeController.removeListener(_onChanged);
    widget.loadingFeeController.removeListener(_onChanged);
    widget.overweightFeeController.removeListener(_onChanged);
    widget.checkingFeeController.removeListener(_onChanged);
    widget.telxFeeController.removeListener(_onChanged);
    widget.otherFeesController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTextField(
          controller: widget.overweightFeeController,
          label: AppLocalizations.of(context)!
                  .translate('container_form_overweight_fee') +
              " (optionnel)",
          icon: Icons.scale,
          keyboardType: TextInputType.number,
          validator: null,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: widget.checkingFeeController,
          label: AppLocalizations.of(context)!
                  .translate('container_form_checking_fee') +
              " (optionnel)",
          icon: Icons.verified,
          keyboardType: TextInputType.number,
          validator: null,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: widget.telxFeeController,
          label: AppLocalizations.of(context)!
                  .translate('container_form_telx_fee') +
              " (optionnel)",
          icon: Icons.phone_android,
          keyboardType: TextInputType.number,
          validator: null,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: widget.otherFeesController,
          label: AppLocalizations.of(context)!
                  .translate('container_form_other_fees') +
              " (optionnel)",
          icon: Icons.more_horiz,
          keyboardType: TextInputType.number,
          validator: null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!
                        .translate('container_total_fees') +
                    " : ",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              "${totalFees.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: widget.marginController,
          label:
              AppLocalizations.of(context)!.translate('container_form_margin'),
          icon: Icons.add,
          keyboardType: TextInputType.number,
          validator: null,
        ),
      ],
    );
  }
}
