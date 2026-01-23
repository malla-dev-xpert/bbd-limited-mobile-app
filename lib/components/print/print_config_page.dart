import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bbd_limited/components/invoice_options_config.dart';
import 'package:bbd_limited/components/selective_fee_margin_config.dart';
import 'package:bbd_limited/components/selective_margin_config.dart';
import 'package:bbd_limited/models/invoice_options.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/print/print_language.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class PrintConfigResult {
  final DateTimeRange? dateRange;
  final bool? includeSupplierInfo;
  final bool? isProforma;
  final InvoiceOptions options;
  final PrintLanguage printLanguage;

  const PrintConfigResult({
    required this.options,
    this.dateRange,
    this.includeSupplierInfo,
    this.isProforma,
    this.printLanguage = PrintLanguage.french,
  });
}

class PrintConfigPage extends StatefulWidget {
  final String title;
  final String previewButtonLabel;
  final InvoiceOptions initialOptions;
  final String currencySymbol;
  final ValueChanged<InvoiceOptions> onOptionsChanged;
  final ValueChanged<PrintConfigResult> onPreview;

  // Date range section
  final bool showDateRange;
  final DateTimeRange? initialDateRange;
  final String dateSectionTitle;
  final String allDataLabel;
  final String filterByDateLabel;
  final String selectPeriodPlaceholder;

  // Supplier / proforma toggles
  final bool showSupplierToggle;
  final bool initialIncludeSupplier;
  final String includeSupplierLabel;
  final bool showProformaToggle;
  final bool initialIsProforma;
  final String proformaLabel;

  // Billing options strings
  final String printOptionsTitle;
  final String billingOptionsTitle;
  final String appliedOptionsLabel;

  // Items for selective margins (optional)
  final List<Items>? items;
  final double? subtotal;

  // Show billing options section
  final bool showBillingOptions;

  const PrintConfigPage({
    Key? key,
    required this.title,
    required this.previewButtonLabel,
    required this.initialOptions,
    required this.currencySymbol,
    required this.onOptionsChanged,
    required this.onPreview,
    required this.printOptionsTitle,
    required this.billingOptionsTitle,
    required this.appliedOptionsLabel,
    this.showDateRange = false,
    this.initialDateRange,
    this.dateSectionTitle = '',
    this.allDataLabel = '',
    this.filterByDateLabel = '',
    this.selectPeriodPlaceholder = '',
    this.showSupplierToggle = false,
    this.initialIncludeSupplier = false,
    this.includeSupplierLabel = '',
    this.showProformaToggle = false,
    this.initialIsProforma = false,
    this.proformaLabel = '',
    this.items,
    this.subtotal,
    this.showBillingOptions = true,
  }) : super(key: key);

  @override
  State<PrintConfigPage> createState() => _PrintConfigPageState();
}

class _PrintConfigPageState extends State<PrintConfigPage> {
  late InvoiceOptions _options;
  DateTimeRange? _selectedDateRange;
  bool _printAll = true;
  bool _includeSupplierInfo = false;
  bool _isProforma = false;
  PrintLanguage _printLanguage = PrintLanguage.french;

  bool get _hasActiveOptions {
    return _options.enableLineMargin ||
        _options.enableLineDiscount ||
        _options.enableGlobalMargin ||
        _options.enableDiscount ||
        _options.enableStorageFees ||
        _options.enableSelectiveFeeMargins;
  }

  @override
  void initState() {
    super.initState();
    _options = widget.initialOptions;
    _selectedDateRange = widget.initialDateRange;
    _printAll = widget.initialDateRange == null;
    _includeSupplierInfo = widget.initialIncludeSupplier;
    _isProforma = widget.initialIsProforma;
  }

  void _handleOptionsChanged(InvoiceOptions options) {
    setState(() {
      _options = options;
    });
    widget.onOptionsChanged(options);
  }

  void _handlePreview() {
    widget.onPreview(
      PrintConfigResult(
        options: _options,
        dateRange:
            widget.showDateRange && !_printAll ? _selectedDateRange : null,
        includeSupplierInfo:
            widget.showSupplierToggle ? _includeSupplierInfo : null,
        isProforma: widget.showProformaToggle ? _isProforma : null,
        printLanguage: _printLanguage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;

    return Scaffold(
      appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.left,
          ),
          backgroundColor: const Color(0xFF1A1E49),
          iconTheme: const IconThemeData(color: Colors.white)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPrintOptionsCard(isMobile),
                    if (widget.showBillingOptions) ...[
                      const SizedBox(height: 16),
                      _buildBillingOptionsCard(isMobile),
                      // Marges sélectives par article (uniquement si items disponibles)
                      if (widget.items != null && widget.items!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SelectiveMarginConfig(
                          items: widget.items!,
                          options: _options,
                          onOptionsChanged: _handleOptionsChanged,
                          currencySymbol: widget.currencySymbol,
                        ),
                      ],
                      const SizedBox(height: 16),
                      SelectiveFeeMarginConfig(
                        options: _options,
                        onOptionsChanged: _handleOptionsChanged,
                        currencySymbol: widget.currencySymbol,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handlePreview,
                icon: const Icon(Icons.visibility),
                label: Text(widget.previewButtonLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1E49),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintOptionsCard(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.printOptionsTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPrintLanguageSection(),
          if (widget.showDateRange) ...[
            const SizedBox(height: 16),
            _buildDateRangeSection(isMobile),
          ],
          if (widget.showSupplierToggle || widget.showProformaToggle) ...[
            const SizedBox(height: 16),
            _buildToggleSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildDateRangeSection(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.dateSectionTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: _printAll,
                onChanged: (value) {
                  setState(() {
                    _printAll = value ?? true;
                    if (_printAll) _selectedDateRange = null;
                  });
                },
              ),
              Expanded(child: Text(widget.allDataLabel)),
            ],
          ),
          Row(
            children: [
              Radio<bool>(
                value: false,
                groupValue: _printAll,
                onChanged: (value) {
                  setState(() {
                    _printAll = value ?? false;
                  });
                },
              ),
              Expanded(child: Text(widget.filterByDateLabel)),
            ],
          ),
          if (!_printAll) ...[
            const SizedBox(height: 16),
            _buildDatePicker(),
          ],
        ],
      );
    }

    // Tablet / desktop
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.dateSectionTitle),
            const SizedBox(width: 20),
            Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: _printAll,
                  onChanged: (value) {
                    setState(() {
                      _printAll = value ?? true;
                      if (_printAll) _selectedDateRange = null;
                    });
                  },
                ),
                Text(widget.allDataLabel),
              ],
            ),
            const SizedBox(width: 20),
            Row(
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: _printAll,
                  onChanged: (value) {
                    setState(() {
                      _printAll = value ?? false;
                    });
                  },
                ),
                Text(widget.filterByDateLabel),
              ],
            ),
          ],
        ),
        if (!_printAll) ...[
          const SizedBox(height: 16),
          _buildDatePicker(),
        ],
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          currentDate: DateTime.now(),
          initialDateRange: _selectedDateRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                dialogTheme: DialogThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                colorScheme: ColorScheme.fromSwatch(
                  primarySwatch: Colors.blue,
                ).copyWith(
                  surface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (range != null && mounted) {
          setState(() => _selectedDateRange = range);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedDateRange == null
                    ? widget.selectPeriodPlaceholder
                    : "${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}",
                style: TextStyle(
                  color: _selectedDateRange == null
                      ? Colors.grey[600]
                      : Colors.black,
                ),
              ),
            ),
            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintLanguageSection() {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('print_language'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<PrintLanguage>(
            value: _printLanguage,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: const Icon(Icons.language, color: Color(0xFF1A1E49)),
            ),
            selectedItemBuilder: (BuildContext context) {
              return PrintLanguage.values.map((language) {
                String displayName;
                switch (language) {
                  case PrintLanguage.french:
                    displayName =
                        localizations.translate('print_language_french');
                    break;
                  case PrintLanguage.english:
                    displayName =
                        localizations.translate('print_language_english');
                    break;
                  case PrintLanguage.chinese:
                    displayName =
                        localizations.translate('print_language_chinese');
                    break;
                }
                return Row(
                  children: [
                    Text(
                      language.flag,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                );
              }).toList();
            },
            items: PrintLanguage.values.map((language) {
              String displayName;
              switch (language) {
                case PrintLanguage.french:
                  displayName =
                      localizations.translate('print_language_french');
                  break;
                case PrintLanguage.english:
                  displayName =
                      localizations.translate('print_language_english');
                  break;
                case PrintLanguage.chinese:
                  displayName =
                      localizations.translate('print_language_chinese');
                  break;
              }
              return DropdownMenuItem<PrintLanguage>(
                value: language,
                child: Row(
                  children: [
                    Text(
                      language.flag,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _printLanguage = value;
                });
              }
            },
            icon:
                const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1A1E49)),
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showSupplierToggle)
          Row(
            children: [
              Checkbox(
                value: _includeSupplierInfo,
                onChanged: (value) {
                  setState(() {
                    _includeSupplierInfo = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Text(
                  widget.includeSupplierLabel,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        if (widget.showProformaToggle)
          Row(
            children: [
              Checkbox(
                value: _isProforma,
                onChanged: (value) {
                  setState(() {
                    _isProforma = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Text(
                  widget.proformaLabel,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBillingOptionsCard(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, size: 20, color: Color(0xFF1A1E49)),
              const SizedBox(width: 8),
              Text(
                widget.billingOptionsTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_hasActiveOptions) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.appliedOptionsLabel,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 11 : 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          InvoiceOptionsConfig(
            options: _options,
            onOptionsChanged: _handleOptionsChanged,
            currencySymbol: widget.currencySymbol,
            items: widget.items,
          ),
        ],
      ),
    );
  }
}
