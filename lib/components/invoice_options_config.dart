import 'package:flutter/material.dart';
import 'package:bbd_limited/models/invoice_options.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/components/item_selection_bottom_sheet.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/selective_margin.dart';

class InvoiceOptionsConfig extends StatefulWidget {
  final InvoiceOptions options;
  final ValueChanged<InvoiceOptions> onOptionsChanged;
  final String currencySymbol;
  final List<Items>? items;

  const InvoiceOptionsConfig({
    Key? key,
    required this.options,
    required this.onOptionsChanged,
    this.currencySymbol = '¥',
    this.items,
  }) : super(key: key);

  @override
  State<InvoiceOptionsConfig> createState() => _InvoiceOptionsConfigState();
}

class _InvoiceOptionsConfigState extends State<InvoiceOptionsConfig> {
  late InvoiceOptions _options;
  final _formKey = GlobalKey<FormState>();
  final _lineMarginController = TextEditingController();
  final _lineDiscountController = TextEditingController();
  final _globalMarginController = TextEditingController();
  final _discountController = TextEditingController();
  final _storageFeeController = TextEditingController();
  bool _shouldSkipNextControllerSync = false;

  @override
  void initState() {
    super.initState();
    _options = widget.options;
    _initializeControllers();
    _addControllersListeners();
  }

  @override
  void didUpdateWidget(InvoiceOptionsConfig oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options) {
      _options = widget.options;
      if (_shouldSkipNextControllerSync) {
        _shouldSkipNextControllerSync = false;
      } else {
        _updateControllersFromOptions();
      }
    }
  }

  void _initializeControllers() {
    _updateControllersFromOptions();
  }

  void _updateControllersFromOptions() {
    _setControllerText(_lineMarginController, _options.lineMarginValue);
    _setControllerText(_lineDiscountController, _options.lineDiscountValue);
    _setControllerText(_globalMarginController, _options.globalMarginValue);
    _setControllerText(_discountController, _options.discountValue);
    _setControllerText(_storageFeeController, _options.storageFeeAmount);
  }

  void _setControllerText(TextEditingController controller, double? value) {
    final newText = value?.toString() ?? '';
    if (controller.text != newText) {
      controller.text = newText;
    }
  }

  void _addControllersListeners() {
    // Suppression des listeners automatiques pour éviter les mises à jour pendant la frappe
  }

  @override
  void dispose() {
    _lineMarginController.dispose();
    _lineDiscountController.dispose();
    _globalMarginController.dispose();
    _discountController.dispose();
    _storageFeeController.dispose();
    super.dispose();
  }

  void _updateOptions(
    InvoiceOptions newOptions, {
    bool fromTextInput = false,
  }) {
    if (fromTextInput) {
      _shouldSkipNextControllerSync = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _shouldSkipNextControllerSync = false;
      });
    }
    setState(() {
      _options = newOptions;
    });
    widget.onOptionsChanged(newOptions);
  }

  void _handleNumericInput({
    required String value,
    required InvoiceOptions Function(double? parsedValue) buildOptions,
  }) {
    if (value.isEmpty) {
      _updateOptions(buildOptions(null), fromTextInput: true);
      return;
    }

    final normalizedValue = value.replaceAll(',', '.');
    final parsedValue = double.tryParse(normalizedValue);
    if (parsedValue != null) {
      _updateOptions(buildOptions(parsedValue), fromTextInput: true);
    }
  }

  /// Désactive la marge par ligne et remet sa valeur à null
  InvoiceOptions _disableLineMargin(InvoiceOptions currentOptions) {
    return InvoiceOptions(
      enableLineMargin: false,
      lineMarginValue: null, // Forcer à null
      lineMarginType: currentOptions.lineMarginType,
      enableGlobalMargin: currentOptions.enableGlobalMargin,
      globalMarginValue: currentOptions.globalMarginValue,
      globalMarginType: currentOptions.globalMarginType,
      enableLineDiscount: currentOptions.enableLineDiscount,
      lineDiscountValue: currentOptions.lineDiscountValue,
      lineDiscountType: currentOptions.lineDiscountType,
      enableDiscount: currentOptions.enableDiscount,
      discountType: currentOptions.discountType,
      discountValue: currentOptions.discountValue,
      enableAdditionalFees: currentOptions.enableAdditionalFees,
      additionalFees: currentOptions.additionalFees,
      enableStorageFees: currentOptions.enableStorageFees,
      storageFeeAmount: currentOptions.storageFeeAmount,
      storageFeeType: currentOptions.storageFeeType,
      enableSelectiveItemMargins:
          false, // Désactiver aussi les marges sélectives
      selectiveItemMargins: const {},
      enableSelectiveFeeMargins: currentOptions.enableSelectiveFeeMargins,
      selectiveFeeMargins: currentOptions.selectiveFeeMargins,
    );
  }

  /// Désactive la remise par ligne et remet sa valeur à null
  InvoiceOptions _disableLineDiscount(InvoiceOptions currentOptions) {
    return InvoiceOptions(
      enableLineMargin: currentOptions.enableLineMargin,
      lineMarginValue: currentOptions.lineMarginValue,
      lineMarginType: currentOptions.lineMarginType,
      enableGlobalMargin: currentOptions.enableGlobalMargin,
      globalMarginValue: currentOptions.globalMarginValue,
      globalMarginType: currentOptions.globalMarginType,
      enableLineDiscount: false,
      lineDiscountValue: null, // Forcer à null
      lineDiscountType: currentOptions.lineDiscountType,
      enableSelectiveLineDiscounts: false,
      selectiveLineDiscounts: const {},
      enableDiscount: currentOptions.enableDiscount,
      discountType: currentOptions.discountType,
      discountValue: currentOptions.discountValue,
      enableAdditionalFees: currentOptions.enableAdditionalFees,
      additionalFees: currentOptions.additionalFees,
      enableStorageFees: currentOptions.enableStorageFees,
      storageFeeAmount: currentOptions.storageFeeAmount,
      storageFeeType: currentOptions.storageFeeType,
      enableSelectiveItemMargins: currentOptions.enableSelectiveItemMargins,
      selectiveItemMargins: currentOptions.selectiveItemMargins,
      enableSelectiveFeeMargins: currentOptions.enableSelectiveFeeMargins,
      selectiveFeeMargins: currentOptions.selectiveFeeMargins,
    );
  }

  /// Désactive la remise globale et remet sa valeur à null
  InvoiceOptions _disableDiscount(InvoiceOptions currentOptions) {
    return InvoiceOptions(
      enableLineMargin: currentOptions.enableLineMargin,
      lineMarginValue: currentOptions.lineMarginValue,
      lineMarginType: currentOptions.lineMarginType,
      enableGlobalMargin: currentOptions.enableGlobalMargin,
      globalMarginValue: currentOptions.globalMarginValue,
      globalMarginType: currentOptions.globalMarginType,
      enableLineDiscount: currentOptions.enableLineDiscount,
      lineDiscountValue: currentOptions.lineDiscountValue,
      lineDiscountType: currentOptions.lineDiscountType,
      enableDiscount: false,
      discountType: currentOptions.discountType,
      discountValue: null, // Forcer à null
      enableAdditionalFees: currentOptions.enableAdditionalFees,
      additionalFees: currentOptions.additionalFees,
      enableStorageFees: currentOptions.enableStorageFees,
      storageFeeAmount: currentOptions.storageFeeAmount,
      storageFeeType: currentOptions.storageFeeType,
      enableSelectiveItemMargins: currentOptions.enableSelectiveItemMargins,
      selectiveItemMargins: currentOptions.selectiveItemMargins,
      enableSelectiveFeeMargins: currentOptions.enableSelectiveFeeMargins,
      selectiveFeeMargins: currentOptions.selectiveFeeMargins,
    );
  }

  /// Désactive la marge globale et remet sa valeur à null
  InvoiceOptions _disableGlobalMargin(InvoiceOptions currentOptions) {
    return InvoiceOptions(
      enableLineMargin: currentOptions.enableLineMargin,
      lineMarginValue: currentOptions.lineMarginValue,
      lineMarginType: currentOptions.lineMarginType,
      enableGlobalMargin: false,
      globalMarginValue: null, // Forcer à null
      globalMarginType: currentOptions.globalMarginType,
      enableLineDiscount: currentOptions.enableLineDiscount,
      lineDiscountValue: currentOptions.lineDiscountValue,
      lineDiscountType: currentOptions.lineDiscountType,
      enableDiscount: currentOptions.enableDiscount,
      discountType: currentOptions.discountType,
      discountValue: currentOptions.discountValue,
      enableAdditionalFees: currentOptions.enableAdditionalFees,
      additionalFees: currentOptions.additionalFees,
      enableStorageFees: currentOptions.enableStorageFees,
      storageFeeAmount: currentOptions.storageFeeAmount,
      storageFeeType: currentOptions.storageFeeType,
      enableSelectiveItemMargins: currentOptions.enableSelectiveItemMargins,
      selectiveItemMargins: currentOptions.selectiveItemMargins,
      enableSelectiveFeeMargins: currentOptions.enableSelectiveFeeMargins,
      selectiveFeeMargins: currentOptions.selectiveFeeMargins,
    );
  }

  /// Désactive les frais d'entreposage et remet sa valeur à null
  InvoiceOptions _disableStorageFees(InvoiceOptions currentOptions) {
    return InvoiceOptions(
      enableLineMargin: currentOptions.enableLineMargin,
      lineMarginValue: currentOptions.lineMarginValue,
      lineMarginType: currentOptions.lineMarginType,
      enableGlobalMargin: currentOptions.enableGlobalMargin,
      globalMarginValue: currentOptions.globalMarginValue,
      globalMarginType: currentOptions.globalMarginType,
      enableLineDiscount: currentOptions.enableLineDiscount,
      lineDiscountValue: currentOptions.lineDiscountValue,
      lineDiscountType: currentOptions.lineDiscountType,
      enableDiscount: currentOptions.enableDiscount,
      discountType: currentOptions.discountType,
      discountValue: currentOptions.discountValue,
      enableAdditionalFees: currentOptions.enableAdditionalFees,
      additionalFees: currentOptions.additionalFees,
      enableStorageFees: false,
      storageFeeAmount: null, // Forcer à null
      storageFeeType: currentOptions.storageFeeType,
      enableSelectiveItemMargins: currentOptions.enableSelectiveItemMargins,
      selectiveItemMargins: currentOptions.selectiveItemMargins,
      enableSelectiveFeeMargins: currentOptions.enableSelectiveFeeMargins,
      selectiveFeeMargins: currentOptions.selectiveFeeMargins,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1E49),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Configuration des options de facturation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Personnalisez vos factures avec des marges, remises et frais',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Design conditionnel : Mobile vs Tablet
            if (isTablet) ...[
              // Design tablette (actuel)
              _buildTabletDesign(),
            ] else ...[
              // Design mobile (nouveau)
              _buildMobileDesign(),
            ],
          ],
        ),
      ),
    );
  }

  /// Design pour tablettes - garde le design actuel
  Widget _buildTabletDesign() {
    return Column(
      children: [
        // Section Marges
        _buildSectionCard(
          title: 'Marges',
          icon: Icons.trending_up,
          children: [
            // Marge par ligne
            _buildOptionTile(
              title: 'Marge par ligne',
              subtitle: 'Ajouter une marge sur chaque ligne',
              value: _options.enableLineMargin,
              onChanged: (value) async {
                if (value == true &&
                    widget.items != null &&
                    widget.items!.isNotEmpty) {
                  // Afficher le bottom sheet pour sélectionner les articles
                  final selectedItemIds = await ItemSelectionBottomSheet.show(
                    context,
                    items: widget.items!,
                    title: 'Sélectionner les articles pour la marge par ligne',
                    subtitle:
                        'Choisissez les articles sur lesquels appliquer la marge',
                    currencySymbol: widget.currencySymbol,
                  );

                  if (selectedItemIds != null && selectedItemIds.isNotEmpty) {
                    // Créer des marges sélectives pour les articles sélectionnés
                    final newMargins = <int, SelectiveItemMargin>{};
                    for (final itemId in selectedItemIds) {
                      final item = widget.items!.firstWhere(
                        (item) => item.id == itemId,
                        orElse: () => widget.items!.first,
                      );
                      if (item.id != null) {
                        newMargins[itemId] = SelectiveItemMargin(
                          itemId: itemId,
                          type: _options.lineMarginType,
                          value: _options.lineMarginValue ?? 0.0,
                          originalUnitPrice: item.unitPrice ?? 0.0,
                          originalTotalPrice: item.totalPrice ?? 0.0,
                        );
                      }
                    }
                    _updateOptions(_options.copyWith(
                      enableLineMargin: true,
                      lineMarginValue: _options.lineMarginValue,
                      enableSelectiveItemMargins: true,
                      selectiveItemMargins: {
                        ..._options.selectiveItemMargins,
                        ...newMargins,
                      },
                    ));
                  } else {
                    // L'utilisateur a annulé ou n'a rien sélectionné - ne pas activer
                    return;
                  }
                } else if (value == true &&
                    (widget.items == null || widget.items!.isEmpty)) {
                  // Pas d'items disponibles, activer simplement la marge par ligne globale
                  _updateOptions(_options.copyWith(
                    enableLineMargin: true,
                    lineMarginValue: _options.lineMarginValue,
                  ));
                } else {
                  // Quand on désactive, utiliser la méthode helper pour forcer la remise à null
                  if (value == false) {
                    _updateOptions(_disableLineMargin(_options));
                  } else {
                    _updateOptions(_options.copyWith(
                      enableLineMargin: true,
                      lineMarginValue: _options.lineMarginValue,
                    ));
                  }
                }
              },
              children: [
                if (_options.enableLineMargin) ...[
                  const SizedBox(height: 16),
                  _buildResponsiveRow([
                    DropDownCustom<MarginType>(
                      selectedItem: _options.lineMarginType,
                      items: MarginType.values.toList(),
                      itemToString: (type) => type == MarginType.percentage
                          ? 'Pourcentage'
                          : 'Montant fixe',
                      onChanged: (type) {
                        if (type != null) {
                          _updateOptions(_options.copyWith(
                            lineMarginType: type,
                            lineMarginValue: _options.lineMarginValue,
                          ));
                        }
                      },
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildTextField(
                          controller: _lineMarginController,
                          label:
                              _options.lineMarginType == MarginType.percentage
                                  ? 'Pourcentage (%)'
                                  : 'Montant (${widget.currencySymbol})',
                          icon: _options.lineMarginType == MarginType.percentage
                              ? Icons.percent
                              : Icons.attach_money,
                          keyboardType:
                              _options.lineMarginType == MarginType.percentage
                                  ? const TextInputType.numberWithOptions(
                                      decimal: true)
                                  : const TextInputType.numberWithOptions(
                                      decimal: true),
                          onChanged: (value) {
                            _handleNumericInput(
                              value: value,
                              buildOptions: (parsed) =>
                                  _options.copyWith(lineMarginValue: parsed),
                            );
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Requis';
                            final amount =
                                double.tryParse(value.replaceAll(',', '.'));
                            if (amount == null || amount < 0)
                              return 'Doit être positif';
                            if (_options.lineMarginType ==
                                    MarginType.percentage &&
                                amount > 100) {
                              return 'Doit être ≤ 100%';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ]),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Marge globale
            _buildOptionTile(
              title: 'Marge globale',
              subtitle: 'Ajouter une marge sur le total',
              value: _options.enableGlobalMargin,
              onChanged: (value) {
                // Marge globale : simple toggle, pas de sélection d'articles
                if (value == false) {
                  _updateOptions(_disableGlobalMargin(_options));
                } else {
                  _updateOptions(_options.copyWith(
                    enableGlobalMargin: true,
                    globalMarginValue: _options.globalMarginValue,
                  ));
                }
              },
              children: [
                if (_options.enableGlobalMargin) ...[
                  const SizedBox(height: 16),
                  _buildResponsiveRow([
                    DropDownCustom<MarginType>(
                      selectedItem: _options.globalMarginType,
                      items: MarginType.values.toList(),
                      itemToString: (type) => type == MarginType.percentage
                          ? 'Pourcentage'
                          : 'Montant fixe',
                      onChanged: (type) {
                        if (type != null) {
                          _updateOptions(_options.copyWith(
                            globalMarginType: type,
                            globalMarginValue: _options.globalMarginValue,
                          ));
                        }
                      },
                    ),
                    buildTextField(
                      controller: _globalMarginController,
                      label: _options.globalMarginType == MarginType.percentage
                          ? 'Pourcentage (%)'
                          : 'Montant (${widget.currencySymbol})',
                      icon: _options.globalMarginType == MarginType.percentage
                          ? Icons.percent
                          : Icons.attach_money,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        _handleNumericInput(
                          value: value,
                          buildOptions: (parsed) =>
                              _options.copyWith(globalMarginValue: parsed),
                        );
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requis';
                        final amount =
                            double.tryParse(value.replaceAll(',', '.'));
                        if (amount == null || amount < 0)
                          return 'Doit être positif';
                        if (_options.globalMarginType ==
                                MarginType.percentage &&
                            amount > 100) {
                          return 'Doit être ≤ 100%';
                        }
                        return null;
                      },
                    ),
                  ]),
                ],
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Section Remises
        _buildSectionCard(
          title: 'Remises',
          icon: Icons.discount,
          children: [
            // Remise par ligne
            _buildOptionTile(
              title: 'Remise par ligne',
              subtitle: 'Appliquer une remise sur chaque ligne',
              value: _options.enableLineDiscount,
              onChanged: (value) async {
                // Remise par ligne : même logique que la marge par ligne avec sélection d'articles
                if (value == true &&
                    widget.items != null &&
                    widget.items!.isNotEmpty) {
                  // Afficher le bottom sheet pour sélectionner les articles
                  final selectedItemIds = await ItemSelectionBottomSheet.show(
                    context,
                    items: widget.items!,
                    title: 'Sélectionner les articles pour la remise par ligne',
                    subtitle:
                        'Choisissez les articles sur lesquels appliquer la remise',
                    currencySymbol: widget.currencySymbol,
                  );

                  if (selectedItemIds != null && selectedItemIds.isNotEmpty) {
                    // Créer des remises sélectives pour les articles sélectionnés
                    final newDiscounts = <int, SelectiveLineDiscount>{};
                    for (final itemId in selectedItemIds) {
                      final item = widget.items!.firstWhere(
                        (item) => item.id == itemId,
                        orElse: () => widget.items!.first,
                      );
                      if (item.id != null) {
                        newDiscounts[itemId] = SelectiveLineDiscount(
                          itemId: itemId,
                          type: _options.lineDiscountType,
                          value: _options.lineDiscountValue ?? 0.0,
                          originalUnitPrice: item.unitPrice ?? 0.0,
                          originalTotalPrice: item.totalPrice ?? 0.0,
                        );
                      }
                    }
                    _updateOptions(_options.copyWith(
                      enableLineDiscount: true,
                      lineDiscountValue: _options.lineDiscountValue ?? 0.0,
                      enableSelectiveLineDiscounts: true,
                      selectiveLineDiscounts: {
                        ..._options.selectiveLineDiscounts,
                        ...newDiscounts,
                      },
                    ));
                  } else {
                    // L'utilisateur a annulé ou n'a rien sélectionné - ne pas activer
                    return;
                  }
                } else if (value == true &&
                    (widget.items == null || widget.items!.isEmpty)) {
                  // Pas d'items disponibles, activer simplement la remise par ligne globale
                  _updateOptions(_options.copyWith(
                    enableLineDiscount: true,
                    lineDiscountValue: _options.lineDiscountValue ?? 0.0,
                  ));
                } else {
                  // Quand on désactive, utiliser la méthode helper pour forcer la remise à null
                  if (value == false) {
                    _updateOptions(_disableLineDiscount(_options));
                  } else {
                    _updateOptions(_options.copyWith(
                      enableLineDiscount: true,
                      lineDiscountValue: _options.lineDiscountValue ?? 0.0,
                    ));
                  }
                }
              },
              children: [
                if (_options.enableLineDiscount) ...[
                  const SizedBox(height: 16),
                  _buildResponsiveRow([
                    DropDownCustom<DiscountType>(
                      selectedItem: _options.lineDiscountType,
                      items: DiscountType.values.toList(),
                      itemToString: (type) => type == DiscountType.percentage
                          ? 'Pourcentage'
                          : 'Montant fixe',
                      onChanged: (type) {
                        if (type != null) {
                          _updateOptions(_options.copyWith(
                            lineDiscountType: type,
                            lineDiscountValue: _options.lineDiscountValue,
                          ));
                        }
                      },
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildTextField(
                          controller: _lineDiscountController,
                          label: _options.lineDiscountType ==
                                  DiscountType.percentage
                              ? 'Pourcentage (%)'
                              : 'Montant (${widget.currencySymbol})',
                          icon: _options.lineDiscountType ==
                                  DiscountType.percentage
                              ? Icons.percent
                              : Icons.attach_money,
                          keyboardType: _options.lineDiscountType ==
                                  DiscountType.percentage
                              ? const TextInputType.numberWithOptions(
                                  decimal: true)
                              : const TextInputType.numberWithOptions(
                                  decimal: true),
                          onChanged: (value) {
                            _handleNumericInput(
                              value: value,
                              buildOptions: (parsed) =>
                                  _options.copyWith(lineDiscountValue: parsed),
                            );
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Requis';
                            final amount =
                                double.tryParse(value.replaceAll(',', '.'));
                            if (amount == null || amount < 0)
                              return 'Doit être positif';
                            if (_options.lineDiscountType ==
                                    DiscountType.percentage &&
                                amount > 100) {
                              return 'Doit être ≤ 100%';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ]),
                ],
              ],
            ),

            const SizedBox(height: 16),

            _buildOptionTile(
              title: 'Remise globale',
              subtitle: 'Appliquer une remise sur le total',
              value: _options.enableDiscount,
              onChanged: (value) {
                // Remise globale : simple toggle, pas de sélection d'articles (comme marge globale)
                if (value == false) {
                  _updateOptions(_disableDiscount(_options));
                } else {
                  _updateOptions(_options.copyWith(
                    enableDiscount: true,
                    discountValue: _options.discountValue,
                  ));
                }
              },
              children: [
                if (_options.enableDiscount) ...[
                  const SizedBox(height: 16),
                  _buildResponsiveRow([
                    DropDownCustom<DiscountType>(
                      selectedItem: _options.discountType,
                      items: DiscountType.values.toList(),
                      itemToString: (type) => type == DiscountType.percentage
                          ? 'Pourcentage'
                          : 'Montant fixe',
                      onChanged: (type) {
                        if (type != null) {
                          _updateOptions(_options.copyWith(
                            discountType: type,
                            discountValue: _options.discountValue,
                          ));
                        }
                      },
                    ),
                    buildTextField(
                      controller: _discountController,
                      label: _options.discountType == DiscountType.percentage
                          ? 'Pourcentage de remise (%)'
                          : 'Montant de remise (${widget.currencySymbol})',
                      icon: Icons.discount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        _handleNumericInput(
                          value: value,
                          buildOptions: (parsed) =>
                              _options.copyWith(discountValue: parsed),
                        );
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requis';
                        final discount =
                            double.tryParse(value.replaceAll(',', '.'));
                        if (discount == null || discount < 0)
                          return 'Doit être positif';
                        if (_options.discountType == DiscountType.percentage &&
                            discount > 100) {
                          return 'Doit être ≤ 100%';
                        }
                        return null;
                      },
                    ),
                  ]),
                ],
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Section Frais d'entreposage
        _buildSectionCard(
          title: 'Frais d\'entreposage',
          icon: Icons.warehouse,
          children: [
            _buildOptionTile(
              title: 'Frais d\'entreposage',
              subtitle: 'Ajouter des frais d\'entreposage',
              value: _options.enableStorageFees,
              onChanged: (value) {
                // Frais d'entreposage : simple toggle, pas de sélection d'articles
                if (value == false) {
                  _updateOptions(_disableStorageFees(_options));
                } else {
                  _updateOptions(_options.copyWith(
                    enableStorageFees: true,
                    storageFeeAmount: _options.storageFeeAmount,
                  ));
                }
              },
              children: [
                if (_options.enableStorageFees) ...[
                  const SizedBox(height: 16),
                  _buildResponsiveRow([
                    DropDownCustom<StorageFeeType>(
                      selectedItem: _options.storageFeeType,
                      items: StorageFeeType.values.toList(),
                      itemToString: (type) => type == StorageFeeType.percentage
                          ? 'Pourcentage'
                          : 'Montant fixe',
                      onChanged: (type) {
                        if (type != null) {
                          _updateOptions(_options.copyWith(
                            storageFeeType: type,
                            storageFeeAmount: _options.storageFeeAmount,
                          ));
                          _storageFeeController.text = '';
                        }
                      },
                    ),
                    buildTextField(
                      controller: _storageFeeController,
                      label:
                          _options.storageFeeType == StorageFeeType.percentage
                              ? 'Pourcentage (%)'
                              : 'Montant (${widget.currencySymbol})',
                      icon: Icons.warehouse,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        _handleNumericInput(
                          value: value,
                          buildOptions: (parsed) =>
                              _options.copyWith(storageFeeAmount: parsed),
                        );
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requis';
                        final amount =
                            double.tryParse(value.replaceAll(',', '.'));
                        if (amount == null || amount < 0)
                          return 'Doit être positif';
                        if (_options.storageFeeType ==
                                StorageFeeType.percentage &&
                            amount > 100) {
                          return 'Doit être ≤ 100%';
                        }
                        return null;
                      },
                    ),
                  ]),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Design pour mobile - complètement différent
  Widget _buildMobileDesign() {
    return Column(
      children: [
        // Cartes d'options en mode mobile
        _buildMobileOptionCard(
          title: 'Marge par ligne',
          subtitle: 'Ajouter une marge sur chaque ligne',
          icon: Icons.trending_up,
          color: Colors.blue,
          isEnabled: _options.enableLineMargin,
          onToggle: (value) async {
            if (value && widget.items != null && widget.items!.isNotEmpty) {
              // Afficher le bottom sheet pour sélectionner les articles
              final selectedItemIds = await ItemSelectionBottomSheet.show(
                context,
                items: widget.items!,
                title: 'Sélectionner les articles pour la marge par ligne',
                subtitle:
                    'Choisissez les articles sur lesquels appliquer la marge',
                currencySymbol: widget.currencySymbol,
              );

              if (selectedItemIds != null && selectedItemIds.isNotEmpty) {
                // Créer des marges sélectives pour les articles sélectionnés
                final newMargins = <int, SelectiveItemMargin>{};
                for (final itemId in selectedItemIds) {
                  final item = widget.items!.firstWhere(
                    (item) => item.id == itemId,
                    orElse: () => widget.items!.first,
                  );
                  if (item.id != null) {
                    newMargins[itemId] = SelectiveItemMargin(
                      itemId: itemId,
                      type: _options.lineMarginType,
                      value: _options.lineMarginValue ?? 0.0,
                      originalUnitPrice: item.unitPrice ?? 0.0,
                      originalTotalPrice: item.totalPrice ?? 0.0,
                    );
                  }
                }
                _updateOptions(_options.copyWith(
                  enableLineMargin: true,
                  lineMarginValue: _options.lineMarginValue ?? 0.0,
                  enableSelectiveItemMargins: true,
                  selectiveItemMargins: {
                    ..._options.selectiveItemMargins,
                    ...newMargins,
                  },
                ));
              } else {
                return;
              }
            } else if (value &&
                (widget.items == null || widget.items!.isEmpty)) {
              // Pas d'items disponibles, activer simplement la marge par ligne globale
              _updateOptions(_options.copyWith(
                enableLineMargin: true,
                lineMarginValue: _options.lineMarginValue ?? 0.0,
              ));
            } else {
              // Quand on désactive, utiliser la méthode helper pour forcer la remise à null
              if (value == false) {
                _updateOptions(_disableLineMargin(_options));
              } else {
                _updateOptions(_options.copyWith(
                  enableLineMargin: true,
                  lineMarginValue: _options.lineMarginValue ?? 0.0,
                ));
              }
            }
          },
          child:
              _options.enableLineMargin ? _buildLineMarginMobileConfig() : null,
        ),

        const SizedBox(height: 16),

        _buildMobileOptionCard(
          title: 'Marge globale',
          subtitle: 'Ajouter une marge sur le total',
          icon: Icons.trending_up,
          color: Colors.green,
          isEnabled: _options.enableGlobalMargin,
          onToggle: (value) {
            // Marge globale : simple toggle, pas de sélection d'articles
            if (value == false) {
              _updateOptions(_disableGlobalMargin(_options));
            } else {
              _updateOptions(_options.copyWith(
                enableGlobalMargin: true,
                globalMarginValue: _options.globalMarginValue ?? 0.0,
              ));
            }
          },
          child: _options.enableGlobalMargin
              ? _buildGlobalMarginMobileConfig()
              : null,
        ),

        const SizedBox(height: 16),

        _buildMobileOptionCard(
          title: 'Remise par ligne',
          subtitle: 'Appliquer une remise sur chaque ligne',
          icon: Icons.discount,
          color: Colors.blue,
          isEnabled: _options.enableLineDiscount,
          onToggle: (value) async {
            // Remise par ligne : même logique que la marge par ligne avec sélection d'articles
            if (value == true &&
                widget.items != null &&
                widget.items!.isNotEmpty) {
              // Afficher le bottom sheet pour sélectionner les articles
              final selectedItemIds = await ItemSelectionBottomSheet.show(
                context,
                items: widget.items!,
                title: 'Sélectionner les articles pour la remise par ligne',
                subtitle:
                    'Choisissez les articles sur lesquels appliquer la remise',
                currencySymbol: widget.currencySymbol,
              );

              if (selectedItemIds != null && selectedItemIds.isNotEmpty) {
                // Créer des remises sélectives pour les articles sélectionnés
                final newDiscounts = <int, SelectiveLineDiscount>{};
                for (final itemId in selectedItemIds) {
                  final item = widget.items!.firstWhere(
                    (item) => item.id == itemId,
                    orElse: () => widget.items!.first,
                  );
                  if (item.id != null) {
                    newDiscounts[itemId] = SelectiveLineDiscount(
                      itemId: itemId,
                      type: _options.lineDiscountType,
                      value: _options.lineDiscountValue ?? 0.0,
                      originalUnitPrice: item.unitPrice ?? 0.0,
                      originalTotalPrice: item.totalPrice ?? 0.0,
                    );
                  }
                }
                _updateOptions(_options.copyWith(
                  enableLineDiscount: true,
                  lineDiscountValue: _options.lineDiscountValue,
                  enableSelectiveLineDiscounts: true,
                  selectiveLineDiscounts: {
                    ..._options.selectiveLineDiscounts,
                    ...newDiscounts,
                  },
                ));
              } else {
                return;
              }
            } else if (value == true &&
                (widget.items == null || widget.items!.isEmpty)) {
              // Pas d'items disponibles, activer simplement la remise par ligne globale
              _updateOptions(_options.copyWith(
                enableLineDiscount: true,
                lineDiscountValue: _options.lineDiscountValue,
              ));
            } else {
              // Quand on désactive, utiliser la méthode helper pour forcer la remise à null
              if (value == false) {
                _updateOptions(_disableLineDiscount(_options));
              } else {
                _updateOptions(_options.copyWith(
                  enableLineDiscount: true,
                  lineDiscountValue: _options.lineDiscountValue,
                ));
              }
            }
          },
          child: _options.enableLineDiscount
              ? _buildLineDiscountMobileConfig()
              : null,
        ),

        const SizedBox(height: 16),

        _buildMobileOptionCard(
          title: 'Remise globale',
          subtitle: 'Appliquer une remise sur le total',
          icon: Icons.discount,
          color: Colors.orange,
          isEnabled: _options.enableDiscount,
          onToggle: (value) {
            // Remise globale : simple toggle, pas de sélection d'articles (comme marge globale)
            if (value == false) {
              _updateOptions(_disableDiscount(_options));
            } else {
              _updateOptions(_options.copyWith(
                enableDiscount: true,
                discountValue: _options.discountValue ?? 0.0,
              ));
            }
          },
          child: _options.enableDiscount ? _buildDiscountMobileConfig() : null,
        ),

        const SizedBox(height: 16),

        _buildMobileOptionCard(
          title: 'Frais d\'entreposage',
          subtitle: 'Ajouter des frais d\'entreposage',
          icon: Icons.warehouse,
          color: Colors.purple,
          isEnabled: _options.enableStorageFees,
          onToggle: (value) {
            // Frais d'entreposage : simple toggle, pas de sélection d'articles
            if (value == false) {
              _updateOptions(_disableStorageFees(_options));
            } else {
              _updateOptions(_options.copyWith(
                enableStorageFees: true,
                storageFeeAmount: _options.storageFeeAmount ?? 0.0,
              ));
            }
          },
          child: _options.enableStorageFees
              ? _buildStorageFeeMobileConfig()
              : null,
        ),
      ],
    );
  }

  /// Carte d'option pour mobile
  Widget _buildMobileOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required Function(bool) onToggle,
    Widget? child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? color.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? color : Colors.grey[300]!,
          width: isEnabled ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la carte
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEnabled ? color : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? color : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: isEnabled
                              ? color.withOpacity(0.8)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: onToggle,
                  activeColor: color,
                ),
              ],
            ),
          ),

          // Contenu de configuration
          if (child != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  /// Configuration marge par ligne pour mobile
  Widget _buildLineMarginMobileConfig() {
    return Column(
      children: [
        const SizedBox(height: 16),
        DropDownCustom<MarginType>(
          selectedItem: _options.lineMarginType,
          items: MarginType.values.toList(),
          itemToString: (type) =>
              type == MarginType.percentage ? 'Pourcentage' : 'Montant fixe',
          onChanged: (type) {
            if (type != null) {
              _updateOptions(_options.copyWith(
                lineMarginType: type,
                lineMarginValue: _options.lineMarginValue,
              ));
            }
          },
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: _lineMarginController,
          label: _options.lineMarginType == MarginType.percentage
              ? 'Pourcentage (%)'
              : 'Montant (${widget.currencySymbol})',
          icon: _options.lineMarginType == MarginType.percentage
              ? Icons.percent
              : Icons.attach_money,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            _handleNumericInput(
              value: value,
              buildOptions: (parsed) =>
                  _options.copyWith(lineMarginValue: parsed),
            );
          },
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requis';
            final amount = double.tryParse(value.replaceAll(',', '.'));
            if (amount == null || amount < 0) return 'Doit être positif';
            if (_options.lineMarginType == MarginType.percentage &&
                amount > 100) {
              return 'Doit être ≤ 100%';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Configuration marge globale pour mobile
  Widget _buildGlobalMarginMobileConfig() {
    return Column(
      children: [
        const SizedBox(height: 16),
        DropDownCustom<MarginType>(
          selectedItem: _options.globalMarginType,
          items: MarginType.values.toList(),
          itemToString: (type) =>
              type == MarginType.percentage ? 'Pourcentage' : 'Montant fixe',
          onChanged: (type) {
            if (type != null) {
              _updateOptions(_options.copyWith(
                globalMarginType: type,
                globalMarginValue: 0.0,
              ));
            }
          },
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: _globalMarginController,
          label: _options.globalMarginType == MarginType.percentage
              ? 'Pourcentage (%)'
              : 'Montant (${widget.currencySymbol})',
          icon: _options.globalMarginType == MarginType.percentage
              ? Icons.percent
              : Icons.attach_money,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            _handleNumericInput(
              value: value,
              buildOptions: (parsed) =>
                  _options.copyWith(globalMarginValue: parsed),
            );
          },
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requis';
            final amount = double.tryParse(value.replaceAll(',', '.'));
            if (amount == null || amount < 0) return 'Doit être positif';
            if (_options.globalMarginType == MarginType.percentage &&
                amount > 100) {
              return 'Doit être ≤ 100%';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Configuration remise par ligne pour mobile
  Widget _buildLineDiscountMobileConfig() {
    return Column(
      children: [
        const SizedBox(height: 16),
        DropDownCustom<DiscountType>(
          selectedItem: _options.lineDiscountType,
          items: DiscountType.values.toList(),
          itemToString: (type) =>
              type == DiscountType.percentage ? 'Pourcentage' : 'Montant fixe',
          onChanged: (type) {
            if (type != null) {
              _updateOptions(_options.copyWith(
                lineDiscountType: type,
                lineDiscountValue: _options.lineDiscountValue,
              ));
            }
          },
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: _lineDiscountController,
          label: _options.lineDiscountType == DiscountType.percentage
              ? 'Pourcentage (%)'
              : 'Montant (${widget.currencySymbol})',
          icon: _options.lineDiscountType == DiscountType.percentage
              ? Icons.percent
              : Icons.attach_money,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            _handleNumericInput(
              value: value,
              buildOptions: (parsed) =>
                  _options.copyWith(lineDiscountValue: parsed),
            );
          },
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requis';
            final amount = double.tryParse(value.replaceAll(',', '.'));
            if (amount == null || amount < 0) return 'Doit être positif';
            if (_options.lineDiscountType == DiscountType.percentage &&
                amount > 100) {
              return 'Doit être ≤ 100%';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Configuration remise globale pour mobile
  Widget _buildDiscountMobileConfig() {
    return Column(
      children: [
        const SizedBox(height: 16),
        DropDownCustom<DiscountType>(
          selectedItem: _options.discountType,
          items: DiscountType.values.toList(),
          itemToString: (type) =>
              type == DiscountType.percentage ? 'Pourcentage' : 'Montant fixe',
          onChanged: (type) {
            if (type != null) {
              _updateOptions(_options.copyWith(
                discountType: type,
                discountValue: _options.discountValue,
              ));
            }
          },
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: _discountController,
          label: _options.discountType == DiscountType.percentage
              ? 'Pourcentage de remise (%)'
              : 'Montant de remise (${widget.currencySymbol})',
          icon: Icons.discount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            _handleNumericInput(
              value: value,
              buildOptions: (parsed) =>
                  _options.copyWith(discountValue: parsed),
            );
          },
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requis';
            final discount = double.tryParse(value.replaceAll(',', '.'));
            if (discount == null || discount < 0) return 'Doit être positif';
            if (_options.discountType == DiscountType.percentage &&
                discount > 100) {
              return 'Doit être ≤ 100%';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Configuration frais d'entreposage pour mobile
  Widget _buildStorageFeeMobileConfig() {
    return Column(
      children: [
        const SizedBox(height: 16),
        DropDownCustom<StorageFeeType>(
          selectedItem: _options.storageFeeType,
          items: StorageFeeType.values.toList(),
          itemToString: (type) => type == StorageFeeType.percentage
              ? 'Pourcentage'
              : 'Montant fixe',
          onChanged: (type) {
            if (type != null) {
              _updateOptions(_options.copyWith(
                storageFeeType: type,
                storageFeeAmount: _options.storageFeeAmount,
              ));
              _storageFeeController.text = '';
            }
          },
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: _storageFeeController,
          label: _options.storageFeeType == StorageFeeType.percentage
              ? 'Pourcentage (%)'
              : 'Montant (${widget.currencySymbol})',
          icon: Icons.warehouse,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            _handleNumericInput(
              value: value,
              buildOptions: (parsed) =>
                  _options.copyWith(storageFeeAmount: parsed),
            );
          },
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requis';
            final amount = double.tryParse(value.replaceAll(',', '.'));
            if (amount == null || amount < 0) return 'Doit être positif';
            if (_options.storageFeeType == StorageFeeType.percentage &&
                amount > 100) {
              return 'Doit être ≤ 100%';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1E49).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF1A1E49),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1E49),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: value ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? Colors.blue[200]! : Colors.grey[200]!,
          width: value ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: value,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF1A1E49),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: value
                              ? const Color(0xFF1A1E49)
                              : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: value ? Colors.blue[600] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (value) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green[600], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Actif',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (value) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Configuration',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...children,
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds a responsive row that stacks vertically on mobile and horizontally on tablet
  Widget _buildResponsiveRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 768;

        if (isTablet) {
          // Tablet layout: horizontal row
          return Row(
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: 16),
              Expanded(child: children[1]),
            ],
          );
        } else {
          // Mobile layout: vertical column
          return Column(
            children: [
              children[0],
              const SizedBox(height: 16),
              children[1],
            ],
          );
        }
      },
    );
  }
}
