import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/devises_service.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
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

  // Store form values (step 1: preserved when leaving step 0 for submit)
  bool isAvailable = false;
  Partner? selectedSupplier;
  int? savedDepartureHarborId;
  int? savedArrivalHarborId;
  String? savedDepartureHarborName;
  String? savedDepartureHarborLocation;
  String? savedArrivalHarborName;
  String? savedArrivalHarborLocation;

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
  final ItemServices itemService = ItemServices();

  List<Items> _availableItems = [];
  final Set<int> _selectedItemIdsToAdd = {};
  final Set<int> _selectedItemIdsToRemove = {};
  bool _isLoadingItems = false;

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
        final info = _containerInfoKey.currentState;
        setState(() {
          savedDepartureHarborId = info?.departureHarborId;
          savedArrivalHarborId = info?.arrivalHarborId;
          savedDepartureHarborName = info?.selectedDepartureHarbor?.name;
          savedDepartureHarborLocation =
              info?.selectedDepartureHarbor?.location;
          savedArrivalHarborName = info?.selectedArrivalHarbor?.name;
          savedArrivalHarborLocation = info?.selectedArrivalHarbor?.location;
          currentStep = 1;
          widget.onStepChanged?.call(currentStep);
        });
      }
    } else if (currentStep == 1) {
      setState(() {
        currentStep = 2;
        widget.onStepChanged?.call(currentStep);
      });
    } else if (currentStep == 2) {
      setState(() {
        currentStep = 3;
        widget.onStepChanged?.call(currentStep);
        _loadAvailableItems();
      });
    }
  }

  Future<void> _loadAvailableItems() async {
    setState(() => _isLoadingItems = true);
    try {
      final list = await itemService.findAllNotInContainer();
      setState(() {
        _availableItems = list.toList();
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() => _isLoadingItems = false);
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

      // Conversion des taux : CNY => 1.0 (Flutter ne calcule jamais)
      double? parseRate(String text) {
        final value = text.trim();
        return value.isEmpty ? null : double.tryParse(value);
      }

      double? effectiveRate(Devise? currency, String rateText) {
        if (currency == null) return null;
        if (currency.code == 'CNY') return 1.0;
        return parseRate(rateText);
      }

      bool validateFeeRate(double? fee, Devise? currency, double? rate) {
        if (fee == null || fee <= 0 || currency == null) return true;
        if (currency.code == 'CNY') return true;
        return rate != null && rate > 0;
      }

      final locFee = parseFee(locationFeeController.text);
      if (!validateFeeRate(locFee, locationFeeCurrency,
          effectiveRate(locationFeeCurrency, locationFeeRateController.text))) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }
      final locCharge = parseFee(localChargeController.text);
      if (!validateFeeRate(locCharge, localChargeCurrency,
          effectiveRate(localChargeCurrency, localChargeRateController.text))) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }
      final loadFee = parseFee(loadingFeeController.text);
      if (!validateFeeRate(loadFee, loadingFeeCurrency,
          effectiveRate(loadingFeeCurrency, loadingFeeRateController.text))) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }
      final overFee = parseFee(overweightFeeController.text);
      if (!validateFeeRate(
          overFee,
          overweightFeeCurrency,
          effectiveRate(
              overweightFeeCurrency, overweightFeeRateController.text))) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }
      final checkFee = parseFee(checkingFeeController.text);
      if (!validateFeeRate(checkFee, checkingFeeCurrency,
          effectiveRate(checkingFeeCurrency, checkingFeeRateController.text))) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }
      final telFee = parseFee(telxFeeController.text);
      if (!validateFeeRate(telFee, telxFeeCurrency,
          effectiveRate(telxFeeCurrency, telxFeeRateController.text))) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }
      final otherFee = parseFee(otherFeesController.text);
      if (!validateFeeRate(otherFee, otherFeesCurrency,
          effectiveRate(otherFeesCurrency, otherFeesRateController.text))) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }
      final margFee = parseFee(marginController.text);
      if (!validateFeeRate(margFee, marginCurrency,
          effectiveRate(marginCurrency, marginRateController.text))) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('rate_required_if_not_cny'));
        setState(() => isLoading = false);
        return;
      }

      final updatedContainer = widget.container.copyWith(
        reference: reference,
        size: size,
        isAvailable: isAvailable,
        supplier_id: selectedSupplier?.id,
        departureHarborId: savedDepartureHarborId,
        departureHarborName: savedDepartureHarborName,
        departureHarborLocation: savedDepartureHarborLocation,
        arrivalHarborId: savedArrivalHarborId,
        arrivalHarborName: savedArrivalHarborName,
        arrivalHarborLocation: savedArrivalHarborLocation,
        locationFee: locFee,
        locationFeeCurrencyCode: locationFeeCurrency?.code,
        locationFeeRateToCNY:
            effectiveRate(locationFeeCurrency, locationFeeRateController.text),
        localCharge: locCharge,
        localChargeCurrencyCode: localChargeCurrency?.code,
        localChargeRateToCNY:
            effectiveRate(localChargeCurrency, localChargeRateController.text),
        loadingFee: loadFee,
        loadingFeeCurrencyCode: loadingFeeCurrency?.code,
        loadingFeeRateToCNY:
            effectiveRate(loadingFeeCurrency, loadingFeeRateController.text),
        overweightFee: overFee,
        overweightFeeCurrencyCode: overweightFeeCurrency?.code,
        overweightFeeRateToCNY: effectiveRate(
            overweightFeeCurrency, overweightFeeRateController.text),
        checkingFee: checkFee,
        checkingFeeCurrencyCode: checkingFeeCurrency?.code,
        checkingFeeRateToCNY:
            effectiveRate(checkingFeeCurrency, checkingFeeRateController.text),
        telxFee: telFee,
        telxFeeCurrencyCode: telxFeeCurrency?.code,
        telxFeeRateToCNY:
            effectiveRate(telxFeeCurrency, telxFeeRateController.text),
        otherFees: otherFee,
        otherFeesCurrencyCode: otherFeesCurrency?.code,
        otherFeesRateToCNY:
            effectiveRate(otherFeesCurrency, otherFeesRateController.text),
        margin: margFee,
        marginCurrencyCode: marginCurrency?.code,
        marginRateToCNY:
            effectiveRate(marginCurrency, marginRateController.text),
      );
      final itemIdsToAdd =
          _selectedItemIdsToAdd.isEmpty ? null : _selectedItemIdsToAdd.toList();
      final itemIdsToRemove = _selectedItemIdsToRemove.isEmpty
          ? null
          : _selectedItemIdsToRemove.toList();

      final response = await containerService.update(
        widget.container.id!,
        user.id,
        updatedContainer,
        itemIds: itemIdsToAdd,
        itemIdsToRemove: itemIdsToRemove,
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
                      initialDepartureHarborId:
                          widget.container.departureHarborId,
                      initialArrivalHarborId: widget.container.arrivalHarborId,
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
            } else if (currentStep == 2) {
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
            } else {
              // Step 3: Items (add / remove)
              final loc = AppLocalizations.of(context)!;
              final containerItems = widget.container.items ?? [];
              if (_isLoadingItems) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator()));
              }
              final availableToAdd =
                  _availableItems.where((i) => i.containerId == null).toList();
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      loc.translate('container_items_step_title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1E49),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.translate('container_items_step_subtitle'),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    if (containerItems.isNotEmpty) ...[
                      Text(
                        loc.translate('container_items_in_container'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ...containerItems.map((item) {
                        final toRemove =
                            _selectedItemIdsToRemove.contains(item.id);
                        final clientDisplay =
                            item.clientName?.isNotEmpty == true
                                ? item.clientName
                                : (item.clientId != null
                                    ? '#${item.clientId}'
                                    : '—');
                        return CheckboxListTile(
                          value: toRemove,
                          onChanged: (v) {
                            setState(() {
                              if (v == true && item.id != null) {
                                _selectedItemIdsToRemove.add(item.id!);
                              } else {
                                _selectedItemIdsToRemove.remove(item.id);
                              }
                            });
                          },
                          title: Text(item.description ?? 'N/A'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (toRemove)
                                Text(loc.translate('container_will_remove')),
                              Text(
                                '${loc.translate('weight')}: ${item.weight ?? 0} · ${loc.translate('cbn')}: ${item.cbn ?? 0} · ${loc.translate('package_client')}: $clientDisplay',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                    if (availableToAdd.isNotEmpty) ...[
                      Text(
                        loc.translate('container_items_available_to_add'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ...availableToAdd.map((item) {
                        final toAdd = _selectedItemIdsToAdd.contains(item.id);
                        final clientDisplay =
                            item.clientName?.isNotEmpty == true
                                ? item.clientName
                                : (item.clientId != null
                                    ? '#${item.clientId}'
                                    : '—');
                        return CheckboxListTile(
                          value: toAdd,
                          onChanged: (v) {
                            setState(() {
                              if (v == true && item.id != null) {
                                _selectedItemIdsToAdd.add(item.id!);
                              } else {
                                _selectedItemIdsToAdd.remove(item.id);
                              }
                            });
                          },
                          title: Text(item.description ?? 'N/A'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                  '${item.quantity ?? 0} unités${item.carton != null ? ', ${item.carton} cartons' : ''}'),
                              const SizedBox(height: 4),
                              Text(
                                '${loc.translate('weight')}: ${item.weight ?? 0} · ${loc.translate('cbn')}: ${item.cbn ?? 0} · ${loc.translate('package_client')}: $clientDisplay',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }),
                    ],
                    if (availableToAdd.isEmpty && containerItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                            child: Text(
                          loc.translate('container_no_items_available'),
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        )),
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
