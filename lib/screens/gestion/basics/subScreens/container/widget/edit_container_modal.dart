import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/container_info_form.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/create_container_form.dart'
    show MainFeesForm, ExtraFeesForm, Partner;

class EditContainerModal extends StatefulWidget {
  final Containers container;
  final Function() onContainerUpdated;

  const EditContainerModal({
    super.key,
    required this.container,
    required this.onContainerUpdated,
  });

  @override
  State<EditContainerModal> createState() => _EditContainerModalState();
}

class _EditContainerModalState extends State<EditContainerModal> {
  int currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _containerInfoKey = GlobalKey<ContainerInfoFormState>();
  final _mainFeesFormKey = GlobalKey<FormState>();
  final _extraFeesFormKey = GlobalKey<FormState>();

  late final TextEditingController refController;
  late final TextEditingController sizeController;
  late final TextEditingController locationFeeController;
  late final TextEditingController localChargeController;
  late final TextEditingController loadingFeeController;
  late final TextEditingController overweightFeeController;
  late final TextEditingController checkingFeeController;
  late final TextEditingController telxFeeController;
  late final TextEditingController otherFeesController;
  late final TextEditingController marginController;

  bool isLoading = false;

  final AuthService authService = AuthService();
  final ContainerServices containerService = ContainerServices();

  @override
  void initState() {
    super.initState();
    refController =
        TextEditingController(text: widget.container.reference ?? '');
    sizeController = TextEditingController(text: widget.container.size ?? '');
    locationFeeController = TextEditingController(
        text: widget.container.locationFee?.toString() ?? '');
    localChargeController = TextEditingController(
        text: widget.container.localCharge?.toString() ?? '');
    loadingFeeController = TextEditingController(
        text: widget.container.loadingFee?.toString() ?? '');
    overweightFeeController = TextEditingController(
        text: widget.container.overweightFee?.toString() ?? '');
    checkingFeeController = TextEditingController(
        text: widget.container.checkingFee?.toString() ?? '');
    telxFeeController =
        TextEditingController(text: widget.container.telxFee?.toString() ?? '');
    otherFeesController = TextEditingController(
        text: widget.container.otherFees?.toString() ?? '');
    marginController =
        TextEditingController(text: widget.container.margin?.toString() ?? '');
  }

  void _goToNextStep() {
    if (currentStep == 0) {
      final valid = _formKey.currentState?.validate() ?? false;
      if (valid) {
        setState(() => currentStep = 1);
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
        showErrorTopSnackBar(context, "Erreur: Utilisateur non connecté");
        return;
      }
      final reference = refController.text.trim();
      final size = sizeController.text.trim();
      final isAvailable = _containerInfoKey.currentState?.isAvailable ?? false;
      final selectedSupplier = _containerInfoKey.currentState?.selectedSupplier;
      double parseFee(String text) {
        final value = text.trim();
        return value.isEmpty ? 0.0 : (double.tryParse(value) ?? 0.0);
      }

      final updatedContainer = widget.container.copyWith(
        reference: reference,
        size: size,
        isAvailable: isAvailable,
        supplier_id: selectedSupplier?.id,
        locationFee: parseFee(locationFeeController.text),
        localCharge: parseFee(localChargeController.text),
        loadingFee: parseFee(loadingFeeController.text),
        overweightFee: parseFee(overweightFeeController.text),
        checkingFee: parseFee(checkingFeeController.text),
        telxFee: parseFee(telxFeeController.text),
        otherFees: parseFee(otherFeesController.text),
        margin: parseFee(marginController.text),
      );
      final response = await containerService.update(
        widget.container.id!,
        user.id,
        updatedContainer,
      );
      if (response == "UPDATED") {
        widget.onContainerUpdated();
        if (mounted) {
          Navigator.pop(context);
          showSuccessTopSnackBar(context, "Conteneur modifié avec succès !");
        }
      } else if (response == "REF_EXIST") {
        showErrorTopSnackBar(context, "Le conteneur existe déjà !");
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          "Erreur lors de la modification:  [${e.toString()}\u001b[0m",
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
                        const Text(
                          "Modifier le conteneur",
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
                      initialAvailability:
                          widget.container.isAvailable ?? false,
                      // initialSupplierId: widget.container.supplier_id, // à activer si ContainerInfoForm le supporte
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: confirmationButton(
                          isLoading: false,
                          onPressed: _goToNextStep,
                          label: "Suivant",
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
                        const Text(
                          "Frais principaux",
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
                          label: "Suivant",
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
                        const Text(
                          "Frais additionnels",
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
                          label: "Enregistrer les modifications",
                          icon: Icons.check_circle_outline_outlined,
                          subLabel: "Modification...",
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
