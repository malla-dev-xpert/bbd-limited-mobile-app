import 'package:flutter/material.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/container_info_form.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/devises_service.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/devises.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class CreateContainerForm extends StatefulWidget {
  final Function(int)? onStepChanged;

  const CreateContainerForm({super.key, this.onStepChanged});

  @override
  State<CreateContainerForm> createState() => CreateContainerFormState();
}

class CreateContainerFormState extends State<CreateContainerForm> {
  int currentStep = 0;

  int get step => currentStep;
  bool get isLoadingState => isLoading;
  final _formKey = GlobalKey<FormState>();
  final _containerInfoKey = GlobalKey<ContainerInfoFormState>();
  final _mainFeesFormKey = GlobalKey<FormState>();
  final _extraFeesFormKey = GlobalKey<ExtraFeesFormState>();

  // Store form values (step 1: preserved when leaving step 0 for submit)
  bool isAvailable = false;
  Partner? selectedSupplier;
  int? savedDepartureHarborId;
  int? savedArrivalHarborId;

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

  // Rate controllers
  final TextEditingController locationFeeRateController =
      TextEditingController();
  final TextEditingController localChargeRateController =
      TextEditingController();
  final TextEditingController loadingFeeRateController =
      TextEditingController();
  final TextEditingController overweightFeeRateController =
      TextEditingController();
  final TextEditingController checkingFeeRateController =
      TextEditingController();
  final TextEditingController telxFeeRateController = TextEditingController();
  final TextEditingController otherFeesRateController = TextEditingController();
  final TextEditingController marginRateController = TextEditingController();

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
  bool isLoadingDevises = false;

  bool isLoading = false;

  final AuthService authService = AuthService();
  final ContainerServices containerService = ContainerServices();
  final DeviseServices deviseService = DeviseServices();

  @override
  void initState() {
    super.initState();
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
          savedDepartureHarborId =
              _containerInfoKey.currentState?.departureHarborId;
          savedArrivalHarborId =
              _containerInfoKey.currentState?.arrivalHarborId;
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
        showErrorTopSnackBar(context,
            AppLocalizations.of(context)!.translate('user_not_connected'));
        return;
      }
      final reference = refController.text.trim();
      final size = sizeController.text.trim();
      // Conversion des champs de frais en double (nullable)
      double? parseFee(String text) {
        final value = text.trim();
        return value.isEmpty ? null : double.tryParse(value);
      }

      // Conversion des taux en double (nullable). CNY => 1.0 (Flutter ne calcule jamais)
      double? parseRate(String text) {
        final value = text.trim();
        return value.isEmpty ? null : double.tryParse(value);
      }

      double? effectiveRate(Devise? currency, String rateText) {
        if (currency == null) return null;
        if (currency.code == 'CNY') return 1.0;
        return parseRate(rateText);
      }

      // Validation : si devise != CNY et montant saisi, taux obligatoire et > 0
      bool validateFeeRate(double? fee, Devise? currency, double? rate) {
        if (fee == null || fee <= 0 || currency == null) return true;
        if (currency.code == 'CNY') return true;
        return rate != null && rate > 0;
      }

      final locFee = parseFee(locationFeeController.text);
      final locRate =
          effectiveRate(locationFeeCurrency, locationFeeRateController.text);
      if (!validateFeeRate(locFee, locationFeeCurrency, locRate)) {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)!
                .translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }
      final locCharge = parseFee(localChargeController.text);
      if (!validateFeeRate(locCharge, localChargeCurrency,
          effectiveRate(localChargeCurrency, localChargeRateController.text))) {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)!
                .translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }
      final loadFee = parseFee(loadingFeeController.text);
      if (!validateFeeRate(loadFee, loadingFeeCurrency,
          effectiveRate(loadingFeeCurrency, loadingFeeRateController.text))) {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)!
                .translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }
      final overFee = parseFee(overweightFeeController.text);
      if (!validateFeeRate(
          overFee,
          overweightFeeCurrency,
          effectiveRate(
              overweightFeeCurrency, overweightFeeRateController.text))) {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)!
                .translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }
      final checkFee = parseFee(checkingFeeController.text);
      if (!validateFeeRate(checkFee, checkingFeeCurrency,
          effectiveRate(checkingFeeCurrency, checkingFeeRateController.text))) {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)!
                .translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }
      final telFee = parseFee(telxFeeController.text);
      if (!validateFeeRate(telFee, telxFeeCurrency,
          effectiveRate(telxFeeCurrency, telxFeeRateController.text))) {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)!
                .translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }
      final otherFee = parseFee(otherFeesController.text);
      if (!validateFeeRate(otherFee, otherFeesCurrency,
          effectiveRate(otherFeesCurrency, otherFeesRateController.text))) {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)!
                .translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }
      final margFee = parseFee(marginController.text);
      if (!validateFeeRate(margFee, marginCurrency,
          effectiveRate(marginCurrency, marginRateController.text))) {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)!
                .translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }

      final response = await containerService.create(
        reference,
        size,
        isAvailable,
        user.id.toInt(),
        selectedSupplier?.id,
        savedDepartureHarborId,
        savedArrivalHarborId,
        locFee,
        locationFeeCurrency?.code,
        locRate,
        locCharge,
        localChargeCurrency?.code,
        effectiveRate(localChargeCurrency, localChargeRateController.text),
        loadFee,
        loadingFeeCurrency?.code,
        effectiveRate(loadingFeeCurrency, loadingFeeRateController.text),
        overFee,
        overweightFeeCurrency?.code,
        effectiveRate(overweightFeeCurrency, overweightFeeRateController.text),
        checkFee,
        checkingFeeCurrency?.code,
        effectiveRate(checkingFeeCurrency, checkingFeeRateController.text),
        telFee,
        telxFeeCurrency?.code,
        effectiveRate(telxFeeCurrency, telxFeeRateController.text),
        otherFee,
        otherFeesCurrency?.code,
        effectiveRate(otherFeesCurrency, otherFeesRateController.text),
        margFee,
        marginCurrency?.code,
        effectiveRate(marginCurrency, marginRateController.text),
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
                          if (currency?.code == 'CNY') {
                            locationFeeRateController.text = '1';
                          } else if (currency?.rate != null) {
                            locationFeeRateController.text =
                                currency!.rate.toString();
                          } else {
                            locationFeeRateController.clear();
                          }
                        });
                      },
                      onLocalChargeCurrencyChanged: (currency) {
                        setState(() {
                          localChargeCurrency = currency;
                          if (currency?.code == 'CNY') {
                            localChargeRateController.text = '1';
                          } else if (currency?.rate != null) {
                            localChargeRateController.text =
                                currency!.rate.toString();
                          } else {
                            localChargeRateController.clear();
                          }
                        });
                      },
                      onLoadingFeeCurrencyChanged: (currency) {
                        setState(() {
                          loadingFeeCurrency = currency;
                          if (currency?.code == 'CNY') {
                            loadingFeeRateController.text = '1';
                          } else if (currency?.rate != null) {
                            loadingFeeRateController.text =
                                currency!.rate.toString();
                          } else {
                            loadingFeeRateController.clear();
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
                          if (currency?.code == 'CNY') {
                            overweightFeeRateController.text = '1';
                          } else if (currency?.rate != null) {
                            overweightFeeRateController.text =
                                currency!.rate.toString();
                          } else {
                            overweightFeeRateController.clear();
                          }
                        });
                      },
                      onCheckingFeeCurrencyChanged: (currency) {
                        setState(() {
                          checkingFeeCurrency = currency;
                          if (currency?.code == 'CNY') {
                            checkingFeeRateController.text = '1';
                          } else if (currency?.rate != null) {
                            checkingFeeRateController.text =
                                currency!.rate.toString();
                          } else {
                            checkingFeeRateController.clear();
                          }
                        });
                      },
                      onTelxFeeCurrencyChanged: (currency) {
                        setState(() {
                          telxFeeCurrency = currency;
                          if (currency?.code == 'CNY') {
                            telxFeeRateController.text = '1';
                          } else if (currency?.rate != null) {
                            telxFeeRateController.text =
                                currency!.rate.toString();
                          } else {
                            telxFeeRateController.clear();
                          }
                        });
                      },
                      onOtherFeesCurrencyChanged: (currency) {
                        setState(() {
                          otherFeesCurrency = currency;
                          if (currency?.code == 'CNY') {
                            otherFeesRateController.text = '1';
                          } else if (currency?.rate != null) {
                            otherFeesRateController.text =
                                currency!.rate.toString();
                          } else {
                            otherFeesRateController.clear();
                          }
                        });
                      },
                      onMarginCurrencyChanged: (currency) {
                        setState(() {
                          marginCurrency = currency;
                          if (currency?.code == 'CNY') {
                            marginRateController.text = '1';
                          } else if (currency?.rate != null) {
                            marginRateController.text =
                                currency!.rate.toString();
                          } else {
                            marginRateController.clear();
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

class MainFeesForm extends StatefulWidget {
  final TextEditingController locationFeeController;
  final TextEditingController locationFeeRateController;
  final TextEditingController localChargeController;
  final TextEditingController localChargeRateController;
  final TextEditingController loadingFeeController;
  final TextEditingController loadingFeeRateController;
  final List<Devise> devises;
  final bool isLoadingDevises;
  final Devise? locationFeeCurrency;
  final Devise? localChargeCurrency;
  final Devise? loadingFeeCurrency;
  final Function(Devise?) onLocationFeeCurrencyChanged;
  final Function(Devise?) onLocalChargeCurrencyChanged;
  final Function(Devise?) onLoadingFeeCurrencyChanged;
  final Partner? Function() getSupplier;

  const MainFeesForm({
    super.key,
    required this.locationFeeController,
    required this.locationFeeRateController,
    required this.localChargeController,
    required this.localChargeRateController,
    required this.loadingFeeController,
    required this.loadingFeeRateController,
    required this.devises,
    required this.isLoadingDevises,
    required this.locationFeeCurrency,
    required this.localChargeCurrency,
    required this.loadingFeeCurrency,
    required this.onLocationFeeCurrencyChanged,
    required this.onLocalChargeCurrencyChanged,
    required this.onLoadingFeeCurrencyChanged,
    required this.getSupplier,
  });

  @override
  State<MainFeesForm> createState() => MainFeesFormState();
}

class MainFeesFormState extends State<MainFeesForm> {
  bool validate() {
    // Tous les champs sont maintenant optionnels
    // La validation se fait uniquement au niveau des champs individuels (format numérique)
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Fee
        buildTextField(
          controller: widget.locationFeeController,
          label: AppLocalizations.of(context)!
                  .translate('container_form_location_fee') +
              " (optionnel)",
          icon: Icons.business,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null &&
                value.isNotEmpty &&
                double.tryParse(value) == null) {
              return AppLocalizations.of(context)!
                  .translate('container_form_validation_fees');
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropDownCustom<Devise>(
                items: widget.devises,
                selectedItem: widget.locationFeeCurrency,
                onChanged: widget.onLocationFeeCurrencyChanged,
                itemToString: (currency) => currency.code,
                hintText:
                    AppLocalizations.of(context)!.translate('choose_currency'),
                prefixIcon: Icons.currency_exchange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildTextField(
                controller: widget.locationFeeRateController,
                label:
                    AppLocalizations.of(context)!.translate('exchange_rate') +
                        " (CNY)",
                icon: Icons.trending_up,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: null,
                readOnly: widget.locationFeeCurrency?.code == 'CNY',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Local Charge
        buildTextField(
          controller: widget.localChargeController,
          label: AppLocalizations.of(context)!
                  .translate('container_form_local_charge') +
              " (optionnel)",
          icon: Icons.location_city,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null &&
                value.isNotEmpty &&
                double.tryParse(value) == null) {
              return AppLocalizations.of(context)!
                  .translate('container_form_validation_fees');
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropDownCustom<Devise>(
                items: widget.devises,
                selectedItem: widget.localChargeCurrency,
                onChanged: widget.onLocalChargeCurrencyChanged,
                itemToString: (currency) => currency.code,
                hintText:
                    AppLocalizations.of(context)!.translate('choose_currency'),
                prefixIcon: Icons.currency_exchange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildTextField(
                controller: widget.localChargeRateController,
                label:
                    AppLocalizations.of(context)!.translate('exchange_rate') +
                        " (CNY)",
                icon: Icons.trending_up,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: null,
                readOnly: widget.localChargeCurrency?.code == 'CNY',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Loading Fee
        buildTextField(
          controller: widget.loadingFeeController,
          label: AppLocalizations.of(context)!
                  .translate('container_form_loading_fee') +
              " (optionnel)",
          icon: Icons.local_shipping,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null &&
                value.isNotEmpty &&
                double.tryParse(value) == null) {
              return AppLocalizations.of(context)!
                  .translate('container_form_validation_fees');
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropDownCustom<Devise>(
                items: widget.devises,
                selectedItem: widget.loadingFeeCurrency,
                onChanged: widget.onLoadingFeeCurrencyChanged,
                itemToString: (currency) => currency.code,
                hintText:
                    AppLocalizations.of(context)!.translate('choose_currency'),
                prefixIcon: Icons.currency_exchange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildTextField(
                controller: widget.loadingFeeRateController,
                label:
                    AppLocalizations.of(context)!.translate('exchange_rate') +
                        " (CNY)",
                icon: Icons.trending_up,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: null,
                readOnly: widget.loadingFeeCurrency?.code == 'CNY',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ExtraFeesForm extends StatefulWidget {
  final TextEditingController overweightFeeController;
  final TextEditingController overweightFeeRateController;
  final TextEditingController checkingFeeController;
  final TextEditingController checkingFeeRateController;
  final TextEditingController telxFeeController;
  final TextEditingController telxFeeRateController;
  final TextEditingController otherFeesController;
  final TextEditingController otherFeesRateController;
  final TextEditingController marginController;
  final TextEditingController marginRateController;
  final List<Devise> devises;
  final bool isLoadingDevises;
  final Devise? overweightFeeCurrency;
  final Devise? checkingFeeCurrency;
  final Devise? telxFeeCurrency;
  final Devise? otherFeesCurrency;
  final Devise? marginCurrency;
  final Function(Devise?) onOverweightFeeCurrencyChanged;
  final Function(Devise?) onCheckingFeeCurrencyChanged;
  final Function(Devise?) onTelxFeeCurrencyChanged;
  final Function(Devise?) onOtherFeesCurrencyChanged;
  final Function(Devise?) onMarginCurrencyChanged;

  const ExtraFeesForm({
    super.key,
    required this.overweightFeeController,
    required this.overweightFeeRateController,
    required this.checkingFeeController,
    required this.checkingFeeRateController,
    required this.telxFeeController,
    required this.telxFeeRateController,
    required this.otherFeesController,
    required this.otherFeesRateController,
    required this.marginController,
    required this.marginRateController,
    required this.devises,
    required this.isLoadingDevises,
    required this.overweightFeeCurrency,
    required this.checkingFeeCurrency,
    required this.telxFeeCurrency,
    required this.otherFeesCurrency,
    required this.marginCurrency,
    required this.onOverweightFeeCurrencyChanged,
    required this.onCheckingFeeCurrencyChanged,
    required this.onTelxFeeCurrencyChanged,
    required this.onOtherFeesCurrencyChanged,
    required this.onMarginCurrencyChanged,
  });

  @override
  State<ExtraFeesForm> createState() => ExtraFeesFormState();
}

class ExtraFeesFormState extends State<ExtraFeesForm> {
  bool validate() {
    // Aucun champ obligatoire ici, tous les frais sont optionnels
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overweight Fee
        buildTextField(
          controller: widget.overweightFeeController,
          label: AppLocalizations.of(context)!
                  .translate('container_form_overweight_fee') +
              " (optionnel)",
          icon: Icons.scale,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null &&
                value.isNotEmpty &&
                double.tryParse(value) == null) {
              return AppLocalizations.of(context)!
                  .translate('container_form_validation_fees');
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropDownCustom<Devise>(
                items: widget.devises,
                selectedItem: widget.overweightFeeCurrency,
                onChanged: widget.onOverweightFeeCurrencyChanged,
                itemToString: (currency) => currency.code,
                hintText:
                    AppLocalizations.of(context)!.translate('choose_currency'),
                prefixIcon: Icons.currency_exchange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildTextField(
                controller: widget.overweightFeeRateController,
                label:
                    AppLocalizations.of(context)!.translate('exchange_rate') +
                        " (CNY)",
                icon: Icons.trending_up,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: null,
                readOnly: widget.overweightFeeCurrency?.code == 'CNY',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Checking Fee
        buildTextField(
          controller: widget.checkingFeeController,
          label: AppLocalizations.of(context)!
                  .translate('container_form_checking_fee') +
              " (optionnel)",
          icon: Icons.verified,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null &&
                value.isNotEmpty &&
                double.tryParse(value) == null) {
              return AppLocalizations.of(context)!
                  .translate('container_form_validation_fees');
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropDownCustom<Devise>(
                items: widget.devises,
                selectedItem: widget.checkingFeeCurrency,
                onChanged: widget.onCheckingFeeCurrencyChanged,
                itemToString: (currency) => currency.code,
                hintText:
                    AppLocalizations.of(context)!.translate('choose_currency'),
                prefixIcon: Icons.currency_exchange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildTextField(
                controller: widget.checkingFeeRateController,
                label:
                    AppLocalizations.of(context)!.translate('exchange_rate') +
                        " (CNY)",
                icon: Icons.trending_up,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: null,
                readOnly: widget.checkingFeeCurrency?.code == 'CNY',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Telx Fee
        buildTextField(
          controller: widget.telxFeeController,
          label: AppLocalizations.of(context)!
                  .translate('container_form_telx_fee') +
              " (optionnel)",
          icon: Icons.phone_android,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null &&
                value.isNotEmpty &&
                double.tryParse(value) == null) {
              return AppLocalizations.of(context)!
                  .translate('container_form_validation_fees');
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropDownCustom<Devise>(
                items: widget.devises,
                selectedItem: widget.telxFeeCurrency,
                onChanged: widget.onTelxFeeCurrencyChanged,
                itemToString: (currency) => currency.code,
                hintText:
                    AppLocalizations.of(context)!.translate('choose_currency'),
                prefixIcon: Icons.currency_exchange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildTextField(
                controller: widget.telxFeeRateController,
                label:
                    AppLocalizations.of(context)!.translate('exchange_rate') +
                        " (CNY)",
                icon: Icons.trending_up,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: null,
                readOnly: widget.telxFeeCurrency?.code == 'CNY',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Other Fees
        buildTextField(
          controller: widget.otherFeesController,
          label: AppLocalizations.of(context)!
                  .translate('container_form_other_fees') +
              " (optionnel)",
          icon: Icons.more_horiz,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null &&
                value.isNotEmpty &&
                double.tryParse(value) == null) {
              return AppLocalizations.of(context)!
                  .translate('container_form_validation_fees');
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropDownCustom<Devise>(
                items: widget.devises,
                selectedItem: widget.otherFeesCurrency,
                onChanged: widget.onOtherFeesCurrencyChanged,
                itemToString: (currency) => currency.code,
                hintText:
                    AppLocalizations.of(context)!.translate('choose_currency'),
                prefixIcon: Icons.currency_exchange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildTextField(
                controller: widget.otherFeesRateController,
                label:
                    AppLocalizations.of(context)!.translate('exchange_rate') +
                        " (CNY)",
                icon: Icons.trending_up,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: null,
                readOnly: widget.otherFeesCurrency?.code == 'CNY',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Margin
        buildTextField(
          controller: widget.marginController,
          label:
              AppLocalizations.of(context)!.translate('container_form_margin') +
                  " (optionnel)",
          icon: Icons.add,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null &&
                value.isNotEmpty &&
                double.tryParse(value) == null) {
              return AppLocalizations.of(context)!
                  .translate('container_form_validation_fees');
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropDownCustom<Devise>(
                items: widget.devises,
                selectedItem: widget.marginCurrency,
                onChanged: widget.onMarginCurrencyChanged,
                itemToString: (currency) => currency.code,
                hintText:
                    AppLocalizations.of(context)!.translate('choose_currency'),
                prefixIcon: Icons.currency_exchange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildTextField(
                controller: widget.marginRateController,
                label:
                    AppLocalizations.of(context)!.translate('exchange_rate') +
                        " (CNY)",
                icon: Icons.trending_up,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: null,
                readOnly: widget.marginCurrency?.code == 'CNY',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
