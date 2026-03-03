import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/models/invoice_options.dart';
import 'package:bbd_limited/models/selective_margin.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:intl/intl.dart';

/// Widget pour configurer les marges sélectives par frais
class SelectiveFeeMarginConfig extends StatefulWidget {
  final InvoiceOptions options;
  final ValueChanged<InvoiceOptions> onOptionsChanged;
  final String currencySymbol;

  const SelectiveFeeMarginConfig({
    Key? key,
    required this.options,
    required this.onOptionsChanged,
    this.currencySymbol = '¥',
  }) : super(key: key);

  @override
  State<SelectiveFeeMarginConfig> createState() =>
      _SelectiveFeeMarginConfigState();
}

class _SelectiveFeeMarginConfigState extends State<SelectiveFeeMarginConfig> {
  late InvoiceOptions _options;
  final Map<String, bool> _selectedFees = {};
  final Map<String, TextEditingController> _marginControllers = {};
  final Map<String, MarginType> _marginTypes = {};
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '');

  @override
  void initState() {
    super.initState();
    _options = widget.options;
    _initializeSelectedFees();
  }

  double? _parseAmount(String? value) {
    if (value == null) return null;
    final normalized = value.replaceAll(RegExp(r'[\s\u00A0]'), '');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized.replaceAll(',', '.'));
  }

  void _initializeSelectedFees() {
    // Frais d'entreposage
    if (_options.enableStorageFees && _options.storageFeeAmount != null) {
      _selectedFees['storage_fees'] =
          _options.selectiveFeeMargins.containsKey('storage_fees');
      _marginTypes['storage_fees'] =
          _options.selectiveFeeMargins['storage_fees']?.type ??
              MarginType.fixed;
      _marginControllers['storage_fees'] = TextEditingController(
        text: _options.selectiveFeeMargins['storage_fees']?.value
                .toStringAsFixed(2) ??
            (_options.storageFeeAmount?.toStringAsFixed(2) ?? '0.00'),
      );
    }

    // Frais additionnels
    for (final fee in _options.additionalFees) {
      if (fee.isActive) {
        final feeId = 'fee_${fee.name}';
        _selectedFees[feeId] = _options.selectiveFeeMargins.containsKey(feeId);
        final feeType = fee.type == FeeType.percentage
            ? MarginType.percentage
            : MarginType.fixed;
        _marginTypes[feeId] =
            _options.selectiveFeeMargins[feeId]?.type ?? feeType;
        _marginControllers[feeId] = TextEditingController(
          text: _options.selectiveFeeMargins[feeId]?.value.toStringAsFixed(2) ??
              fee.amount.toStringAsFixed(2),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _marginControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateOptions() {
    final Map<String, SelectiveFeeMargin> newMargins = {};

    for (final entry in _selectedFees.entries) {
      if (entry.value) {
        final controller = _marginControllers[entry.key];
        final type = _marginTypes[entry.key] ?? MarginType.percentage;

        if (controller != null) {
          final value = _parseAmount(controller.text);
          if (value != null && value >= 0) {
            String feeName;
            double originalAmount;

            if (entry.key == 'storage_fees') {
              feeName = 'Frais d\'entreposage';
              originalAmount = _options.storageFeeAmount ?? 0.0;
            } else {
              // Frais additionnel
              final feeNameFromId = entry.key.replaceFirst('fee_', '');
              final fee = _options.additionalFees.firstWhere(
                (f) => f.name == feeNameFromId,
                orElse: () => _options.additionalFees.first,
              );
              feeName = fee.name;
              originalAmount = fee.amount;
            }

            newMargins[entry.key] = SelectiveFeeMargin(
              feeId: entry.key,
              feeName: feeName,
              type: type,
              value: value,
              originalAmount: originalAmount,
            );
          }
        }
      }
    }

    final newOptions = _options.copyWith(
      enableSelectiveFeeMargins: newMargins.isNotEmpty,
      selectiveFeeMargins: newMargins,
    );

    setState(() {
      _options = newOptions;
    });

    widget.onOptionsChanged(newOptions);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // Liste des frais disponibles
    final List<Map<String, dynamic>> availableFees = [];

    if (_options.enableStorageFees && _options.storageFeeAmount != null) {
      availableFees.add({
        'id': 'storage_fees',
        'name': localizations.translate('storage_fees'),
        'amount': _options.storageFeeAmount!,
      });
    }

    for (final fee in _options.additionalFees) {
      if (fee.isActive) {
        availableFees.add({
          'id': 'fee_${fee.name}',
          'name': fee.name,
          'amount': fee.amount,
        });
      }
    }

    if (availableFees.isEmpty) {
      return const SizedBox.shrink();
    }

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
              color: Colors.purple[700],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizations.translate('selective_fee_margin_title'),
                    style: AppTextSize.titleStyle(context,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: _options.enableSelectiveFeeMargins,
                  onChanged: (value) {
                    if (!value) {
                      for (final key in _selectedFees.keys.toList()) {
                        _selectedFees[key] = false;
                      }
                    }
                    _updateOptions();
                  },
                  activeColor: Colors.white,
                ),
              ],
            ),
          ),

          if (_options.enableSelectiveFeeMargins) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('selective_fee_margin_description'),
                    style: AppTextSize.bodyStyle(context,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Liste des frais
                  ...availableFees.map((fee) {
                    final feeId = fee['id'] as String;
                    final isSelected = _selectedFees[feeId] ?? false;
                    final feeAmount = fee['amount'] as double;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.purple[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.purple[300]!
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  _selectedFees[feeId] = value ?? false;
                                  if (value == false) {
                                    _marginControllers[feeId]?.text =
                                        feeAmount.toStringAsFixed(2);
                                    _marginTypes[feeId] = MarginType.fixed;
                                  }
                                });
                                _updateOptions();
                              },
                              activeColor: Colors.purple[700],
                            ),
                            title: Text(
                              fee['name'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.purple[700]
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              '${localizations.translate('original_amount')}: ${_currencyFormat.format(feeAmount)} ${widget.currencySymbol}',
                              style: AppTextSize.captionStyle(context,
                                  color: Colors.grey[600]),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle,
                                    color: Colors.green[600])
                                : null,
                          ),
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

                                  DropDownCustom<MarginType>(
                                    selectedItem:
                                        _marginTypes[feeId] ?? MarginType.fixed,
                                    items: MarginType.values.toList(),
                                    itemToString: (type) => type ==
                                            MarginType.percentage
                                        ? localizations.translate('percentage')
                                        : localizations
                                            .translate('fixed_amount'),
                                    onChanged: (type) {
                                      if (type != null) {
                                        setState(() {
                                          _marginTypes[feeId] = type;
                                          if (type == MarginType.percentage) {
                                            _marginControllers[feeId]?.text =
                                                '10';
                                          } else {
                                            _marginControllers[feeId]?.text =
                                                feeAmount.toStringAsFixed(2);
                                          }
                                        });
                                        _updateOptions();
                                      }
                                    },
                                  ),

                                  const SizedBox(height: 12),

                                  buildTextField(
                                    controller: _marginControllers[feeId]!,
                                    label: _marginTypes[feeId] ==
                                            MarginType.percentage
                                        ? '${localizations.translate('margin_percentage')} (%)'
                                        : '${localizations.translate('margin_amount')} (${widget.currencySymbol})',
                                    icon: _marginTypes[feeId] ==
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
                                      final amount = _parseAmount(value);
                                      if (amount == null || amount < 0) {
                                        return localizations
                                            .translate('invalid_amount');
                                      }
                                      if (_marginTypes[feeId] ==
                                              MarginType.percentage &&
                                          amount > 100) {
                                        return localizations
                                            .translate('percentage_max_100');
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 8),

                                  // Aperçu
                                  if (_marginControllers[feeId]
                                          ?.text
                                          .isNotEmpty ==
                                      true) ...[
                                    Builder(
                                      builder: (context) {
                                        final value = _parseAmount(
                                            _marginControllers[feeId]!.text);
                                        if (value == null)
                                          return const SizedBox.shrink();

                                        final margin = SelectiveFeeMargin(
                                          feeId: feeId,
                                          feeName: fee['name'] as String,
                                          type: _marginTypes[feeId] ??
                                              MarginType.fixed,
                                          value: value,
                                          originalAmount: feeAmount,
                                        );

                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.purple[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.purple[200]!),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.info_outline,
                                                      color: Colors.purple[700],
                                                      size: 16),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    localizations.translate(
                                                        'margin_preview'),
                                                    style: AppTextSize.captionStyle(context,
                                                      color: Colors.purple[700],
                                                    ).copyWith(fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              _buildPreviewRow(
                                                context,
                                                localizations.translate(
                                                    'original_amount'),
                                                '${_currencyFormat.format(feeAmount)} ${widget.currencySymbol}',
                                              ),
                                              _buildPreviewRow(
                                                context,
                                                localizations
                                                    .translate('margin_amount'),
                                                '+${_currencyFormat.format(margin.marginAmount)} ${widget.currencySymbol}',
                                              ),
                                              const Divider(height: 16),
                                              _buildPreviewRow(
                                                context,
                                                localizations.translate(
                                                    'adjusted_amount'),
                                                '${_currencyFormat.format(margin.adjustedAmount)} ${widget.currencySymbol}',
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
              color: isBold ? Colors.purple[700]! : Colors.black87,
            ).copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}
