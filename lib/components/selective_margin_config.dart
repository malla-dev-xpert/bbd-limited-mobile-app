import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/models/invoice_options.dart';
import 'package:bbd_limited/models/selective_margin.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:intl/intl.dart';

/// Widget pour configurer les marges sélectives par article
class SelectiveMarginConfig extends StatefulWidget {
  final List<Items> items;
  final InvoiceOptions options;
  final ValueChanged<InvoiceOptions> onOptionsChanged;
  final String currencySymbol;

  const SelectiveMarginConfig({
    Key? key,
    required this.items,
    required this.options,
    required this.onOptionsChanged,
    this.currencySymbol = '¥',
  }) : super(key: key);

  @override
  State<SelectiveMarginConfig> createState() => _SelectiveMarginConfigState();
}

class _SelectiveMarginConfigState extends State<SelectiveMarginConfig> {
  late InvoiceOptions _options;
  final Map<int, bool> _selectedItems = {};
  final Map<int, TextEditingController> _marginControllers = {};
  final Map<int, TextEditingController> _observationControllers = {};
  final Map<int, TextEditingController> _finalPriceControllers = {};
  final Map<int, MarginType> _marginTypes = {};
  final Map<int, MarginDisplayMode> _displayModes = {};
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '');

  @override
  void initState() {
    super.initState();
    _options = widget.options;
    _initializeSelectedItems();
  }

  void _initializeSelectedItems() {
    // Initialiser les articles sélectionnés depuis les marges existantes
    for (final item in widget.items) {
      if (item.id != null) {
        _selectedItems[item.id!] =
            _options.selectiveItemMargins.containsKey(item.id!);
        if (_selectedItems[item.id!] == true) {
          final margin = _options.selectiveItemMargins[item.id!]!;
          _marginTypes[item.id!] = margin.type;
          _displayModes[item.id!] = margin.displayMode;
          _marginControllers[item.id!] = TextEditingController(
            text: margin.value.toStringAsFixed(2),
          );
          _observationControllers[item.id!] = TextEditingController(
            text: margin.observation ?? '',
          );
          _finalPriceControllers[item.id!] = TextEditingController(
            text: margin.finalPrice?.toStringAsFixed(2) ?? '',
          );
        } else {
          _marginTypes[item.id!] = MarginType.percentage;
          _displayModes[item.id!] = MarginDisplayMode.displayMarginOnly;
          _marginControllers[item.id!] = TextEditingController(text: '10');
          _observationControllers[item.id!] = TextEditingController(text: '');
          _finalPriceControllers[item.id!] = TextEditingController(text: '');
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _marginControllers.values) {
      controller.dispose();
    }
    for (final controller in _observationControllers.values) {
      controller.dispose();
    }
    for (final controller in _finalPriceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateOptions() {
    final Map<int, SelectiveItemMargin> newMargins = {};

    for (final entry in _selectedItems.entries) {
      if (entry.value && widget.items.any((item) => item.id == entry.key)) {
        final item = widget.items.firstWhere((item) => item.id == entry.key);
        final controller = _marginControllers[entry.key];
        final type = _marginTypes[entry.key] ?? MarginType.percentage;
        final displayMode =
            _displayModes[entry.key] ?? MarginDisplayMode.displayMarginOnly;
        final observationController = _observationControllers[entry.key];
        final finalPriceController = _finalPriceControllers[entry.key];

        if (controller != null) {
          final value = double.tryParse(controller.text);
          if (value != null && value >= 0) {
            // Récupérer l'observation
            final observation = observationController?.text.trim();

            // Récupérer le prix final si Option A
            double? finalPrice;
            if (displayMode == MarginDisplayMode.modifyFinalPrice &&
                finalPriceController != null &&
                finalPriceController.text.trim().isNotEmpty) {
              finalPrice = double.tryParse(finalPriceController.text);
            }

            newMargins[entry.key] = SelectiveItemMargin(
              itemId: entry.key,
              type: type,
              value: value,
              originalUnitPrice: item.unitPrice ?? 0.0,
              originalTotalPrice: item.totalPrice ?? 0.0,
              observation: observation?.isEmpty == true ? null : observation,
              finalPrice: finalPrice,
              displayMode: displayMode,
            );
          }
        }
      }
    }

    final newOptions = _options.copyWith(
      enableSelectiveItemMargins: newMargins.isNotEmpty,
      selectiveItemMargins: newMargins,
    );

    setState(() {
      _options = newOptions;
    });

    widget.onOptionsChanged(newOptions);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1E49),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizations.translate('selective_margin_title'),
                    style: AppTextSize.titleStyle(context,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: _options.enableSelectiveItemMargins,
                  onChanged: (value) {
                    if (!value) {
                      // Désactiver toutes les sélections
                      for (final key in _selectedItems.keys.toList()) {
                        _selectedItems[key] = false;
                      }
                    }
                    _updateOptions();
                  },
                  activeColor: Colors.white,
                ),
              ],
            ),
          ),

          if (_options.enableSelectiveItemMargins) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('selective_margin_description'),
                    style: AppTextSize.bodyStyle(context,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Liste des articles
                  ...widget.items.map((item) {
                    if (item.id == null) return const SizedBox.shrink();
                    final itemId = item.id!;
                    final isSelected = _selectedItems[itemId] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue[300]!
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // En-tête de l'article
                          ListTile(
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  _selectedItems[itemId] = value ?? false;
                                  if (value == false) {
                                    _marginControllers[itemId]?.text = '10';
                                    _marginTypes[itemId] =
                                        MarginType.percentage;
                                  }
                                });
                                _updateOptions();
                              },
                              activeColor: const Color(0xFF1A1E49),
                            ),
                            title: Text(
                              item.description ??
                                  localizations.translate('unnamed_item'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? const Color(0xFF1A1E49)
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              '${localizations.translate('quantity')}: ${item.quantity ?? 0} | '
                              '${localizations.translate('unit_price')}: ${_currencyFormat.format(item.unitPrice ?? 0)} ${widget.currencySymbol} | '
                              '${localizations.translate('total')}: ${_currencyFormat.format(item.totalPrice ?? 0)} ${widget.currencySymbol}',
                              style: AppTextSize.captionStyle(context,
                                  color: Colors.grey[600]),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle,
                                    color: Colors.green[600])
                                : null,
                          ),

                          // Configuration de la marge (si sélectionné)
                          if (isSelected) ...[
                            Divider(height: 1, color: Colors.grey[300]),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localizations
                                        .translate('margin_configuration'),
                                    style: AppTextSize.bodyStyle(context,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Type de marge
                                  DropDownCustom<MarginType>(
                                    selectedItem: _marginTypes[itemId] ??
                                        MarginType.percentage,
                                    items: MarginType.values.toList(),
                                    itemToString: (type) => type ==
                                            MarginType.percentage
                                        ? localizations.translate('percentage')
                                        : localizations
                                            .translate('fixed_amount'),
                                    onChanged: (type) {
                                      if (type != null) {
                                        setState(() {
                                          _marginTypes[itemId] = type;
                                          // Réinitialiser la valeur selon le type
                                          if (type == MarginType.percentage) {
                                            _marginControllers[itemId]?.text =
                                                '10';
                                          } else {
                                            _marginControllers[itemId]?.text =
                                                '5';
                                          }
                                        });
                                        _updateOptions();
                                      }
                                    },
                                  ),

                                  const SizedBox(height: 12),

                                  // Valeur de la marge
                                  buildTextField(
                                    controller: _marginControllers[itemId]!,
                                    label: _marginTypes[itemId] ==
                                            MarginType.percentage
                                        ? '${localizations.translate('margin_percentage')} (%)'
                                        : '${localizations.translate('margin_amount')} (${widget.currencySymbol})',
                                    icon: _marginTypes[itemId] ==
                                            MarginType.percentage
                                        ? Icons.percent
                                        : Icons.attach_money,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    onChanged: (_) => _updateOptions(),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return localizations
                                            .translate('required_field');
                                      }
                                      final amount = double.tryParse(value);
                                      if (amount == null || amount < 0) {
                                        return localizations
                                            .translate('invalid_amount');
                                      }
                                      if (_marginTypes[itemId] ==
                                              MarginType.percentage &&
                                          amount > 100) {
                                        return localizations
                                            .translate('percentage_max_100');
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 12),

                                  // Mode d'affichage
                                  Text(
                                    'Mode d\'affichage',
                                    style: AppTextSize.captionStyle(context,
                                      color: Colors.grey[700],
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  DropDownCustom<MarginDisplayMode>(
                                    selectedItem: _displayModes[itemId] ??
                                        MarginDisplayMode.displayMarginOnly,
                                    items: MarginDisplayMode.values.toList(),
                                    itemToString: (mode) => mode ==
                                            MarginDisplayMode.modifyFinalPrice
                                        ? 'Option A : Modifier le prix final'
                                        : 'Option B : Afficher la marge',
                                    onChanged: (mode) {
                                      if (mode != null) {
                                        setState(() {
                                          _displayModes[itemId] = mode;
                                          // Réinitialiser le prix final si on passe en Option B
                                          if (mode ==
                                              MarginDisplayMode
                                                  .displayMarginOnly) {
                                            _finalPriceControllers[itemId]
                                                ?.text = '';
                                          }
                                        });
                                        _updateOptions();
                                      }
                                    },
                                  ),

                                  // Prix final modifié (Option A uniquement)
                                  if (_displayModes[itemId] ==
                                      MarginDisplayMode.modifyFinalPrice) ...[
                                    const SizedBox(height: 12),
                                    buildTextField(
                                      controller:
                                          _finalPriceControllers[itemId]!,
                                      label:
                                          'Prix final modifié (${widget.currencySymbol})',
                                      icon: Icons.edit,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      onChanged: (_) => _updateOptions(),
                                      validator: (value) {
                                        if (value != null && value.isNotEmpty) {
                                          final amount = double.tryParse(value);
                                          if (amount == null || amount < 0) {
                                            return localizations
                                                .translate('invalid_amount');
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                  ],

                                  const SizedBox(height: 12),

                                  // Observation
                                  TextFormField(
                                    controller:
                                        _observationControllers[itemId]!,
                                    keyboardType: TextInputType.multiline,
                                    maxLines: 3,
                                    onChanged: (_) => _updateOptions(),
                                    decoration: InputDecoration(
                                      labelText: 'Observation (optionnel)',
                                      prefixIcon:
                                          Icon(Icons.note, color: Colors.black),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Aperçu du calcul
                                  if (_marginControllers[itemId]
                                          ?.text
                                          .isNotEmpty ==
                                      true) ...[
                                    Builder(
                                      builder: (context) {
                                        final value = double.tryParse(
                                            _marginControllers[itemId]!.text);
                                        if (value == null)
                                          return const SizedBox.shrink();

                                        final displayMode =
                                            _displayModes[itemId] ??
                                                MarginDisplayMode
                                                    .displayMarginOnly;
                                        final finalPriceText =
                                            _finalPriceControllers[itemId]
                                                ?.text
                                                .trim();
                                        final double? finalPrice =
                                            finalPriceText?.isNotEmpty == true
                                                ? double.tryParse(
                                                    finalPriceText!)
                                                : null;

                                        final margin = SelectiveItemMargin(
                                          itemId: itemId,
                                          type: _marginTypes[itemId] ??
                                              MarginType.percentage,
                                          value: value,
                                          originalUnitPrice:
                                              item.unitPrice ?? 0.0,
                                          originalTotalPrice:
                                              item.totalPrice ?? 0.0,
                                          finalPrice: finalPrice,
                                          displayMode: displayMode,
                                        );

                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.blue[200]!),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.info_outline,
                                                      color: Colors.blue[700],
                                                      size: 16),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    localizations.translate(
                                                        'margin_preview'),
                                                    style: AppTextSize.captionStyle(context,
                                                      color: Colors.blue[700],
                                                    ).copyWith(fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              _buildPreviewRow(
                                                context,
                                                localizations.translate(
                                                    'original_total'),
                                                '${_currencyFormat.format(item.totalPrice ?? 0)} ${widget.currencySymbol}',
                                              ),
                                              if (displayMode ==
                                                  MarginDisplayMode
                                                      .displayMarginOnly) ...[
                                                _buildPreviewRow(
                                                  context,
                                                  localizations.translate(
                                                      'margin_amount'),
                                                  '+${_currencyFormat.format(margin.marginAmount)} ${widget.currencySymbol}',
                                                ),
                                                _buildPreviewRow(
                                                  context,
                                                  'Pourcentage',
                                                  '${margin.realMarginPercentage.toStringAsFixed(2)}%',
                                                ),
                                              ] else if (finalPrice !=
                                                  null) ...[
                                                _buildPreviewRow(
                                                  context,
                                                  'Marge réelle',
                                                  '+${_currencyFormat.format(margin.marginAmount)} ${widget.currencySymbol}',
                                                ),
                                                _buildPreviewRow(
                                                  context,
                                                  'Pourcentage réel',
                                                  '${margin.realMarginPercentage.toStringAsFixed(2)}%',
                                                ),
                                              ],
                                              const Divider(height: 16),
                                              _buildPreviewRow(
                                                context,
                                                localizations.translate(
                                                    'adjusted_total'),
                                                '${_currencyFormat.format(margin.adjustedTotalPrice)} ${widget.currencySymbol}',
                                                isBold: true,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewRow(BuildContext context, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextSize.captionStyle(context,
              color: Colors.grey[700],
            ).copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: AppTextSize.captionStyle(context,
              color: isBold ? const Color(0xFF1A1E49) : Colors.black87,
            ).copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}
