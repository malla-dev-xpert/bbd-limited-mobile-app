import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/devises_service.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/devises.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/container_info_form.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/create_container_form.dart'
    show MainFeesForm, ExtraFeesForm;
import 'package:bbd_limited/models/partner.dart';

class EditContainerModal extends StatefulWidget {
  final Containers container;
  final Function() onContainerUpdated;
  final Function(int)? onStepChanged;

  const EditContainerModal({
    super.key,
    required this.container,
    required this.onContainerUpdated,
    this.onStepChanged,
  });

  @override
  State<EditContainerModal> createState() => EditContainerModalState();
}

class EditContainerModalState extends State<EditContainerModal> {
  int currentStep = 0;

  int get step => currentStep;
  bool get isLoadingState => isLoading;
  final _formKey = GlobalKey<FormState>();
  final _containerInfoKey = GlobalKey<ContainerInfoFormState>();
  final _mainFeesFormKey = GlobalKey<FormState>();
  final _extraFeesFormKey = GlobalKey<FormState>();

  late final TextEditingController refController;
  late final TextEditingController sizeController;
  late final TextEditingController locationFeeController;
  late final TextEditingController locationFeeRateController;
  late final TextEditingController localChargeController;
  late final TextEditingController localChargeRateController;
  late final TextEditingController loadingFeeController;
  late final TextEditingController loadingFeeRateController;
  late final TextEditingController overweightFeeController;
  late final TextEditingController overweightFeeRateController;
  late final TextEditingController checkingFeeController;
  late final TextEditingController checkingFeeRateController;
  late final TextEditingController telxFeeController;
  late final TextEditingController telxFeeRateController;
  late final TextEditingController otherFeesController;
  late final TextEditingController otherFeesRateController;
  late final TextEditingController marginController;
  late final TextEditingController marginRateController;

  bool isLoading = false;
  bool isLoadingDevises = false;

  // Store form values
  bool isAvailable = false;
  Partner? selectedSupplier;

  // Currency selections
  Devise? locationFeeCurrency;
  Devise? localChargeCurrency;
  Devise? loadingFeeCurrency;
  Devise? overweightFeeCurrency;
  Devise? checkingFeeCurrency;
  Devise? telxFeeCurrency;
  Devise? otherFeesCurrency;
  Devise? marginCurrency;

  // Devises list
  List<Devise> devises = [];

  final AuthService authService = AuthService();
  final ContainerServices containerService = ContainerServices();
  final DeviseServices deviseService = DeviseServices();

  @override
  void initState() {
    super.initState();
    refController =
        TextEditingController(text: widget.container.reference ?? '');
    sizeController = TextEditingController(text: widget.container.size ?? '');
    locationFeeController = TextEditingController(
        text: widget.container.locationFee?.toString() ?? '');
    locationFeeRateController = TextEditingController(
        text: widget.container.locationFeeRateToCNY?.toString() ?? '');
    localChargeController = TextEditingController(
        text: widget.container.localCharge?.toString() ?? '');
    localChargeRateController = TextEditingController(
        text: widget.container.localChargeRateToCNY?.toString() ?? '');
    loadingFeeController = TextEditingController(
        text: widget.container.loadingFee?.toString() ?? '');
    loadingFeeRateController = TextEditingController(
        text: widget.container.loadingFeeRateToCNY?.toString() ?? '');
    overweightFeeController = TextEditingController(
        text: widget.container.overweightFee?.toString() ?? '');
    overweightFeeRateController = TextEditingController(
        text: widget.container.overweightFeeRateToCNY?.toString() ?? '');
    checkingFeeController = TextEditingController(
        text: widget.container.checkingFee?.toString() ?? '');
    checkingFeeRateController = TextEditingController(
        text: widget.container.checkingFeeRateToCNY?.toString() ?? '');
    telxFeeController =
        TextEditingController(text: widget.container.telxFee?.toString() ?? '');
    telxFeeRateController = TextEditingController(
        text: widget.container.telxFeeRateToCNY?.toString() ?? '');
    otherFeesController = TextEditingController(
        text: widget.container.otherFees?.toString() ?? '');
    otherFeesRateController = TextEditingController(
        text: widget.container.otherFeesRateToCNY?.toString() ?? '');
    marginController =
        TextEditingController(text: widget.container.margin?.toString() ?? '');
    marginRateController = TextEditingController(
        text: widget.container.marginRateToCNY?.toString() ?? '');

    // Initialize form values
    isAvailable = widget.container.isAvailable ?? false;

    // Load devises and set initial currency values
    _loadDevises();

    // Notifier le parent de l'étape initiale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepChanged?.call(currentStep);
    });
  }

  Future<void> _loadDevises() async {
    setState(() => isLoadingDevises = true);
    try {
      final loadedDevises = await deviseService.findAllDevises();
      setState(() {
        devises = loadedDevises;
        isLoadingDevises = false;

        // Set initial currency selections from container
        if (widget.container.locationFeeCurrencyCode != null &&
            devises.isNotEmpty) {
          try {
            locationFeeCurrency = devises.firstWhere(
              (d) => d.code == widget.container.locationFeeCurrencyCode,
            );
          } catch (e) {
            // Currency not found, leave as null
          }
        }
        if (widget.container.localChargeCurrencyCode != null &&
            devises.isNotEmpty) {
          try {
            localChargeCurrency = devises.firstWhere(
              (d) => d.code == widget.container.localChargeCurrencyCode,
            );
          } catch (e) {
            // Currency not found, leave as null
          }
        }
        if (widget.container.loadingFeeCurrencyCode != null &&
            devises.isNotEmpty) {
          try {
            loadingFeeCurrency = devises.firstWhere(
              (d) => d.code == widget.container.loadingFeeCurrencyCode,
            );
          } catch (e) {
            // Currency not found, leave as null
          }
        }
        if (widget.container.overweightFeeCurrencyCode != null &&
            devises.isNotEmpty) {
          try {
            overweightFeeCurrency = devises.firstWhere(
              (d) => d.code == widget.container.overweightFeeCurrencyCode,
            );
          } catch (e) {
            // Currency not found, leave as null
          }
        }
        if (widget.container.checkingFeeCurrencyCode != null &&
            devises.isNotEmpty) {
          try {
            checkingFeeCurrency = devises.firstWhere(
              (d) => d.code == widget.container.checkingFeeCurrencyCode,
            );
          } catch (e) {
            // Currency not found, leave as null
          }
        }
        if (widget.container.telxFeeCurrencyCode != null &&
            devises.isNotEmpty) {
          try {
            telxFeeCurrency = devises.firstWhere(
              (d) => d.code == widget.container.telxFeeCurrencyCode,
            );
          } catch (e) {
            // Currency not found, leave as null
          }
        }
        if (widget.container.otherFeesCurrencyCode != null &&
            devises.isNotEmpty) {
          try {
            otherFeesCurrency = devises.firstWhere(
              (d) => d.code == widget.container.otherFeesCurrencyCode,
            );
          } catch (e) {
            // Currency not found, leave as null
          }
        }
        if (widget.container.marginCurrencyCode != null && devises.isNotEmpty) {
          try {
            marginCurrency = devises.firstWhere(
              (d) => d.code == widget.container.marginCurrencyCode,
            );
          } catch (e) {
            // Currency not found, leave as null
          }
        }
      });
    } catch (e) {
      setState(() => isLoadingDevises = false);
      // Silently fail - devises will remain empty
    }
  }

  void goToNextStep() {
    if (currentStep == 0) {
      final valid = _formKey.currentState?.validate() ?? false;
      if (valid) {
        setState(() {
          currentStep = 1;
          widget.onStepChanged?.call(currentStep);
        });
      }
    } else if (currentStep == 1) {
      // Tous les champs sont optionnels, on peut toujours passer à l'étape suivante
      // La validation se fait uniquement au niveau des champs individuels
      setState(() {
        currentStep = 2;
        widget.onStepChanged?.call(currentStep);
      });
    }
  }

  void goToPreviousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep -= 1;
        widget.onStepChanged?.call(currentStep);
      });
    }
  }

  void submitForm() {
    _submitForm();
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

      // Conversion des champs de frais en double (nullable)
      double? parseFee(String text) {
        final value = text.trim();
        return value.isEmpty ? null : double.tryParse(value);
      }

      // Conversion des taux en double (nullable)
      double? parseRate(String text) {
        final value = text.trim();
        return value.isEmpty ? null : double.tryParse(value);
      }

      final updatedContainer = widget.container.copyWith(
        reference: reference,
        size: size,
        isAvailable: isAvailable,
        supplier_id: selectedSupplier?.id,
        locationFee: parseFee(locationFeeController.text),
        locationFeeCurrencyCode: locationFeeCurrency?.code,
        locationFeeRateToCNY: parseRate(locationFeeRateController.text),
        localCharge: parseFee(localChargeController.text),
        localChargeCurrencyCode: localChargeCurrency?.code,
        localChargeRateToCNY: parseRate(localChargeRateController.text),
        loadingFee: parseFee(loadingFeeController.text),
        loadingFeeCurrencyCode: loadingFeeCurrency?.code,
        loadingFeeRateToCNY: parseRate(loadingFeeRateController.text),
        overweightFee: parseFee(overweightFeeController.text),
        overweightFeeCurrencyCode: overweightFeeCurrency?.code,
        overweightFeeRateToCNY: parseRate(overweightFeeRateController.text),
        checkingFee: parseFee(checkingFeeController.text),
        checkingFeeCurrencyCode: checkingFeeCurrency?.code,
        checkingFeeRateToCNY: parseRate(checkingFeeRateController.text),
        telxFee: parseFee(telxFeeController.text),
        telxFeeCurrencyCode: telxFeeCurrency?.code,
        telxFeeRateToCNY: parseRate(telxFeeRateController.text),
        otherFees: parseFee(otherFeesController.text),
        otherFeesCurrencyCode: otherFeesCurrency?.code,
        otherFeesRateToCNY: parseRate(otherFeesRateController.text),
        margin: parseFee(marginController.text),
        marginCurrencyCode: marginCurrency?.code,
        marginRateToCNY: parseRate(marginRateController.text),
      );
      final response = await containerService.update(
        widget.container.id!,
        user.id,
        updatedContainer,
      );
      if (response == "UPDATED") {
        widget.onContainerUpdated();
        if (mounted) {
          Navigator.pop(context, true);
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
            bottom: MediaQuery.of(context).viewInsets.bottom + 100),
        child: Builder(
          builder: (context) {
            if (currentStep == 0) {
              return Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    ContainerInfoForm(
                      key: _containerInfoKey,
                      refController: refController,
                      size: sizeController,
                      initialAvailability:
                          widget.container.isAvailable ?? false,
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
                      // initialSupplierId: widget.container.supplier_id, // à activer si ContainerInfoForm le supporte
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            } else if (currentStep == 1) {
              return Form(
                key: _mainFeesFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    MainFeesForm(
                      locationFeeController: locationFeeController,
                      locationFeeRateController: locationFeeRateController,
                      localChargeController: localChargeController,
                      localChargeRateController: localChargeRateController,
                      loadingFeeController: loadingFeeController,
                      loadingFeeRateController: loadingFeeRateController,
                      devises: devises,
                      isLoadingDevises: isLoadingDevises,
                      locationFeeCurrency: locationFeeCurrency,
                      localChargeCurrency: localChargeCurrency,
                      loadingFeeCurrency: loadingFeeCurrency,
                      onLocationFeeCurrencyChanged: (currency) {
                        setState(() {
                          locationFeeCurrency = currency;
                          if (currency?.rate != null) {
                            locationFeeRateController.text =
                                currency!.rate.toString();
                          }
                        });
                      },
                      onLocalChargeCurrencyChanged: (currency) {
                        setState(() {
                          localChargeCurrency = currency;
                          if (currency?.rate != null) {
                            localChargeRateController.text =
                                currency!.rate.toString();
                          }
                        });
                      },
                      onLoadingFeeCurrencyChanged: (currency) {
                        setState(() {
                          loadingFeeCurrency = currency;
                          if (currency?.rate != null) {
                            loadingFeeRateController.text =
                                currency!.rate.toString();
                          }
                        });
                      },
                      getSupplier: () =>
                          _containerInfoKey.currentState?.selectedSupplier,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            } else {
              return Form(
                key: _extraFeesFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    ExtraFeesForm(
                      overweightFeeController: overweightFeeController,
                      overweightFeeRateController: overweightFeeRateController,
                      checkingFeeController: checkingFeeController,
                      checkingFeeRateController: checkingFeeRateController,
                      telxFeeController: telxFeeController,
                      telxFeeRateController: telxFeeRateController,
                      otherFeesController: otherFeesController,
                      otherFeesRateController: otherFeesRateController,
                      marginController: marginController,
                      marginRateController: marginRateController,
                      devises: devises,
                      isLoadingDevises: isLoadingDevises,
                      overweightFeeCurrency: overweightFeeCurrency,
                      checkingFeeCurrency: checkingFeeCurrency,
                      telxFeeCurrency: telxFeeCurrency,
                      otherFeesCurrency: otherFeesCurrency,
                      marginCurrency: marginCurrency,
                      onOverweightFeeCurrencyChanged: (currency) {
                        setState(() {
                          overweightFeeCurrency = currency;
                          if (currency?.rate != null) {
                            overweightFeeRateController.text =
                                currency!.rate.toString();
                          }
                        });
                      },
                      onCheckingFeeCurrencyChanged: (currency) {
                        setState(() {
                          checkingFeeCurrency = currency;
                          if (currency?.rate != null) {
                            checkingFeeRateController.text =
                                currency!.rate.toString();
                          }
                        });
                      },
                      onTelxFeeCurrencyChanged: (currency) {
                        setState(() {
                          telxFeeCurrency = currency;
                          if (currency?.rate != null) {
                            telxFeeRateController.text =
                                currency!.rate.toString();
                          }
                        });
                      },
                      onOtherFeesCurrencyChanged: (currency) {
                        setState(() {
                          otherFeesCurrency = currency;
                          if (currency?.rate != null) {
                            otherFeesRateController.text =
                                currency!.rate.toString();
                          }
                        });
                      },
                      onMarginCurrencyChanged: (currency) {
                        setState(() {
                          marginCurrency = currency;
                          if (currency?.rate != null) {
                            marginRateController.text =
                                currency!.rate.toString();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 24),
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
    locationFeeRateController.dispose();
    localChargeController.dispose();
    localChargeRateController.dispose();
    loadingFeeController.dispose();
    loadingFeeRateController.dispose();
    overweightFeeController.dispose();
    overweightFeeRateController.dispose();
    checkingFeeController.dispose();
    checkingFeeRateController.dispose();
    telxFeeController.dispose();
    telxFeeRateController.dispose();
    otherFeesController.dispose();
    otherFeesRateController.dispose();
    marginController.dispose();
    marginRateController.dispose();
    super.dispose();
  }
}
