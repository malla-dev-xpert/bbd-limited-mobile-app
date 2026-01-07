import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/core/print/print_localizations.dart';
import 'package:bbd_limited/models/invoice_options.dart';

class PartnerPrintService {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'zh_CN', // Locale chinois
    symbol: '¥ ',
    decimalDigits: 2,
  );

  static Future<Uint8List> buildClientReportPdfBytes(
    Partner partner, {
    DateTimeRange? dateRange,
    required PrintLocalizations printLocalizations,
    InvoiceOptions? invoiceOptions,
  }) async {
    final pdf = pw.Document();

    // Les polices sont déterminées dans chaque méthode selon la langue

    final logoBytes = await rootBundle
        .load('assets/images/logo.png')
        .then((data) => data.buffer.asUint8List());

    final filteredVersements = _filterVersements(partner.versements, dateRange);
    final filteredPackages = _filterPackages(partner.packages, dateRange);

    // Calcul du sous-total des versements
    double sousTotal =
        filteredVersements.fold(0, (sum, v) => sum + (v.montantVerser ?? 0));

    // Application des options de facturation
    final options = invoiceOptions ?? const InvoiceOptions();
    double montantTotal = options.calculateTotal(sousTotal);

    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.zero,
        build: (context) => [
          pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(logoBytes, dateRange, printLocalizations),
                _buildClientInfoSection(partner, printLocalizations),
                _buildSummarySection(
                  filteredVersements,
                  filteredPackages,
                  printLocalizations,
                ),
                if (filteredVersements.isNotEmpty)
                  _buildVersementsSection(
                      filteredVersements, printLocalizations),
                if (filteredPackages.isNotEmpty)
                  _buildPackagesSection(filteredPackages, printLocalizations),
                if (_hasActiveOptions(options)) ...[
                  pw.SizedBox(height: 24),
                  _buildPricingSummary(
                      sousTotal, montantTotal, options, printLocalizations),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // Vérifier si des options de facturation sont actives
  static bool _hasActiveOptions(InvoiceOptions options) {
    return options.enableLineMargin ||
        options.enableGlobalMargin ||
        options.enableDiscount ||
        options.enableStorageFees;
  }

  static List<Versement> _filterVersements(
      List<Versement>? versements, DateTimeRange? range) {
    if (versements == null) return [];
    if (range == null) return versements;
    return versements.where((v) {
      final date = v.createdAt ?? DateTime(1900);
      return date.isAfter(range.start) && date.isBefore(range.end);
    }).toList();
  }

  static List<Packages> _filterPackages(
      List<Packages>? packages, DateTimeRange? range) {
    if (packages == null) return [];
    if (range == null) return packages;
    return packages.where((p) {
      final date = p.startDate ?? DateTime(1900);
      return date.isAfter(range.start) && date.isBefore(range.end);
    }).toList();
  }

  static pw.Widget _buildHeader(Uint8List logoBytes, DateTimeRange? dateRange,
      PrintLocalizations printLocalizations) {
    final font = printLocalizations.language.code == 'zh'
        ? pw.Font.courier()
        : pw.Font.helvetica();
    final fallbackFonts = [pw.Font.times(), pw.Font.courier()];
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Image(pw.MemoryImage(logoBytes), width: 100),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(printLocalizations.translate('pdf_client_status'),
                style: pw.TextStyle(
                    fontSize: 32,
                    color: PdfColor.fromHex('#1A1E49'),
                    fontWeight: pw.FontWeight.bold,
                    font: font,
                    fontFallback: fallbackFonts)),
            pw.SizedBox(height: 8),
            pw.Text(
                dateRange == null
                    ? printLocalizations.translate('pdf_all_periods')
                    : printLocalizations
                        .translate('pdf_from_to')
                        .replaceAll(
                            '{start}', _dateFormat.format(dateRange.start))
                        .replaceAll('{end}', _dateFormat.format(dateRange.end)),
                style: pw.TextStyle(
                    fontSize: 12, font: font, fontFallback: fallbackFonts)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildClientInfoSection(
      Partner partner, PrintLocalizations printLocalizations) {
    final font = printLocalizations.language.code == 'zh'
        ? pw.Font.courier()
        : pw.Font.helvetica();
    final fallbackFonts = [pw.Font.times(), pw.Font.courier()];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(printLocalizations.translate('pdf_client_information'),
            style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1A1E49'),
                font: font,
                fontFallback: fallbackFonts)),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _infoRow(printLocalizations.translate('pdf_name'),
                    '${partner.firstName} ${partner.lastName}'),
                if (partner.phoneNumber.isNotEmpty)
                  _infoRow(printLocalizations.translate('pdf_phone'),
                      partner.phoneNumber),
                if (partner.email.isNotEmpty)
                  _infoRow(
                      printLocalizations.translate('pdf_email'), partner.email),
              ],
            ),
            pw.SizedBox(width: 40),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (partner.adresse.isNotEmpty)
                  _infoRow(printLocalizations.translate('pdf_address'),
                      partner.adresse),
                _infoRow(printLocalizations.translate('pdf_account_type'),
                    partner.accountType),
                _infoRow(printLocalizations.translate('pdf_balance'),
                    '${partner.balance?.toStringAsFixed(2) ?? '0.00'}'),
              ],
            ),
            pw.SizedBox(height: 40),
          ],
        ),
      ],
    );
  }

  static pw.Widget _infoRow(String label, String? value) {
    return pw.Row(
      children: [
        pw.Text('$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
        pw.Text(value ?? '-', style: const pw.TextStyle(fontSize: 16)),
        pw.SizedBox(width: 20),
      ],
    );
  }

  static pw.Widget _buildSummarySection(
    List<Versement> versements,
    List<Packages> packages,
    PrintLocalizations printLocalizations,
  ) {
    final font = printLocalizations.language.code == 'zh'
        ? pw.Font.courier()
        : pw.Font.helvetica();
    final fallbackFonts = [pw.Font.times(), pw.Font.courier()];
    final totalVersements =
        versements.fold<double>(0, (sum, v) => sum + (v.montantVerser ?? 0));
    final totalRetraits = versements
        .expand((v) => v.cashWithdrawalDtoList ?? [])
        .fold<double>(0, (sum, r) => sum + (r.amount ?? 0));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(printLocalizations.translate('pdf_summary'),
            style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1A1E49'),
                font: font,
                fontFallback: fallbackFonts)),
        pw.SizedBox(height: 8),
        pw.Container(
          color: PdfColor.fromHex('#1A1E49'),
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: pw.Row(
            children: [
              pw.Expanded(
                  child: pw.Text(printLocalizations.translate('pdf_category'),
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold))),
              pw.Expanded(
                  child: pw.Text(printLocalizations.translate('pdf_amount'),
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold))),
            ],
          ),
        ),
        pw.Container(
          color: PdfColors.grey200,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: pw.Row(
            children: [
              pw.Expanded(
                  child: pw.Text(
                      printLocalizations.translate('pdf_total_versements'))),
              pw.Expanded(
                  child: pw.Text(_currencyFormat.format(totalVersements))),
            ],
          ),
        ),
        pw.Container(
          color: PdfColors.grey100,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: pw.Row(
            children: [
              pw.Expanded(
                  child: pw.Text(
                      printLocalizations.translate('pdf_total_retraits'))),
              pw.Expanded(
                  child: pw.Text(_currencyFormat.format(totalRetraits))),
            ],
          ),
        ),
        pw.Container(
          color: PdfColors.grey200,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: pw.Row(
            children: [
              pw.Expanded(
                  child: pw.Text(
                      printLocalizations.translate('pdf_packages_count'))),
              pw.Expanded(child: pw.Text('${packages.length}')),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildVersementsSection(
      List<Versement> versements, PrintLocalizations printLocalizations) {
    final font = printLocalizations.language.code == 'zh'
        ? pw.Font.courier()
        : pw.Font.helvetica();
    final fallbackFonts = [pw.Font.times(), pw.Font.courier()];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(printLocalizations.translate('pdf_versements'),
            style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1A1E49'),
                font: font,
                fontFallback: fallbackFonts)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          context: null,
          border: pw.TableBorder.all(color: PdfColors.grey300),
          headerStyle: pw.TextStyle(
              color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          headerDecoration:
              pw.BoxDecoration(color: PdfColor.fromHex('#1A1E49')),
          headers: [
            printLocalizations.translate('pdf_date'),
            printLocalizations.translate('pdf_reference'),
            printLocalizations.translate('pdf_amount_paid'),
            printLocalizations.translate('pdf_type'),
            printLocalizations.translate('pdf_remaining_amount')
          ],
          data: versements
              .map((v) => [
                    _dateFormat.format(v.createdAt ?? DateTime.now()),
                    v.reference ?? '-',
                    _currencyFormat.format(v.montantVerser ?? 0),
                    v.type ?? '-',
                    _currencyFormat.format(v.montantRestant ?? 0),
                  ])
              .toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildPackagesSection(
      List<Packages> packages, PrintLocalizations printLocalizations) {
    final font = printLocalizations.language.code == 'zh'
        ? pw.Font.courier()
        : pw.Font.helvetica();
    final fallbackFonts = [pw.Font.times(), pw.Font.courier()];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(printLocalizations.translate('pdf_packages'),
            style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1A1E49'),
                font: font,
                fontFallback: fallbackFonts)),
        pw.SizedBox(height: 8),
        for (final package in packages) ...[
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text('${package.ref}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 10),
                    pw.Text(
                        '(${_dateFormat.format(package.startDate ?? DateTime.now())})'),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text(
                        '${printLocalizations.translate('pdf_from')}: ${package.startCountry}'),
                    pw.SizedBox(width: 10),
                    pw.Text(
                        '${printLocalizations.translate('pdf_to')}: ${package.destinationCountry}'),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                    '${printLocalizations.translate('pdf_status')}: ${package.status?.name ?? '-'}'),
                pw.SizedBox(height: 8),
                if (package.items != null && package.items!.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    context: null,
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headerDecoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    headers: [
                      printLocalizations.translate('pdf_article'),
                      printLocalizations.translate('pdf_quantity'),
                      printLocalizations.translate('pdf_unit_price'),
                      printLocalizations.translate('pdf_exchange_rate'),
                      printLocalizations.translate('pdf_total')
                    ],
                    data: package.items!
                        .map((item) => [
                              item.description ?? '-',
                              '${item.quantity}',
                              _currencyFormat.format(item.unitPrice ?? 0),
                              _currencyFormat.format(item.salesRate ?? 0),
                              _currencyFormat.format(item.totalPrice ?? 0),
                            ])
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildPricingSummary(
    double sousTotal,
    double montantTotal,
    InvoiceOptions options,
    PrintLocalizations printLocalizations,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Sous-total
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  printLocalizations.translate('pdf_subtotal_label'),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Text(
                  _currencyFormat.format(sousTotal),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Détail des options appliquées
          if (options.enableLineMargin && options.lineMarginValue != null) ...[
            pw.SizedBox(height: 8),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    options.lineMarginType == MarginType.percentage
                        ? printLocalizations
                            .translate('pdf_line_margin_percentage')
                            .replaceAll('{value}', '${options.lineMarginValue}')
                        : printLocalizations
                            .translate('pdf_line_margin_fixed')
                            .replaceAll(
                                '{value}', '${options.lineMarginValue}'),
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    _currencyFormat.format(
                        options.lineMarginType == MarginType.percentage
                            ? (sousTotal * options.lineMarginValue! / 100)
                            : options.lineMarginValue!),
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (options.enableDiscount && options.discountValue != null) ...[
            pw.SizedBox(height: 8),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    options.discountType == DiscountType.percentage
                        ? printLocalizations
                            .translate('pdf_discount_percentage')
                            .replaceAll('{value}', '${options.discountValue}')
                        : printLocalizations.translate('pdf_discount_fixed'),
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    '-${_currencyFormat.format(options.discountType == DiscountType.percentage ? (sousTotal * options.discountValue! / 100) : options.discountValue!)}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (options.enableStorageFees &&
              options.storageFeeAmount != null) ...[
            pw.SizedBox(height: 8),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    options.storageFeeType == StorageFeeType.percentage
                        ? printLocalizations
                            .translate('pdf_storage_fees_percentage')
                            .replaceAll(
                                '{value}', '${options.storageFeeAmount}')
                        : printLocalizations
                            .translate('pdf_storage_fees_fixed'),
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    _currencyFormat.format(
                        options.storageFeeType == StorageFeeType.percentage
                            ? (sousTotal * options.storageFeeAmount! / 100)
                            : options.storageFeeAmount!),
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (options.enableGlobalMargin &&
              options.globalMarginValue != null) ...[
            pw.SizedBox(height: 8),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    options.globalMarginType == MarginType.percentage
                        ? printLocalizations
                            .translate('pdf_global_margin_percentage')
                            .replaceAll(
                                '{value}', '${options.globalMarginValue}')
                        : printLocalizations
                            .translate('pdf_global_margin_fixed')
                            .replaceAll(
                                '{value}', '${options.globalMarginValue}'),
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    _currencyFormat.format(
                        options.globalMarginType == MarginType.percentage
                            ? (montantTotal * options.globalMarginValue! / 100)
                            : options.globalMarginValue!),
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          pw.SizedBox(height: 16),

          // Total final
          pw.Text(
            '${printLocalizations.translate('pdf_total_final')} : ${_currencyFormat.format(montantTotal)}',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1E49'),
            ),
          ),
        ],
      ),
    );
  }
}
