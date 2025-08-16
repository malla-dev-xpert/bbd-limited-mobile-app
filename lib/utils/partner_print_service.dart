import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:pdf/widgets.dart' as pw;

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
    required AppLocalizations localizations,
  }) async {
    final pdf = pw.Document();

    // Utiliser une police qui supporte les caractères chinois
    final font = pw.Font.helvetica();
    final chineseFont = pw.Font
        .courier(); // Courier supporte mieux les caractères internationaux
    final fallbackFonts = [
      pw.Font.times(),
      pw.Font.courier()
    ]; // Polices de secours pour les caractères spéciaux

    final logoBytes = await rootBundle
        .load('assets/images/logo.png')
        .then((data) => data.buffer.asUint8List());

    final filteredVersements = _filterVersements(partner.versements, dateRange);
    final filteredPackages = _filterPackages(partner.packages, dateRange);

    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.zero,
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 20,
                height: 800,
                color: PdfColor.fromHex('#1A1E49'),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(24),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildHeader(logoBytes, dateRange, localizations),
                      _buildClientInfoSection(partner, localizations),
                      _buildSummarySection(
                        filteredVersements,
                        filteredPackages,
                        localizations,
                      ),
                      if (filteredVersements.isNotEmpty)
                        _buildVersementsSection(
                            filteredVersements, localizations),
                      if (filteredPackages.isNotEmpty)
                        _buildPackagesSection(filteredPackages, localizations),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
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
      AppLocalizations localizations) {
    final font = localizations.locale.languageCode == 'zh'
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
            pw.Text(localizations.translate('pdf_client_status'),
                style: pw.TextStyle(
                    fontSize: 32,
                    color: PdfColor.fromHex('#1A1E49'),
                    fontWeight: pw.FontWeight.bold,
                    font: font,
                    fontFallback: fallbackFonts)),
            pw.SizedBox(height: 8),
            pw.Text(
                dateRange == null
                    ? localizations.translate('pdf_all_periods')
                    : localizations
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
      Partner partner, AppLocalizations localizations) {
    final font = localizations.locale.languageCode == 'zh'
        ? pw.Font.courier()
        : pw.Font.helvetica();
    final fallbackFonts = [pw.Font.times(), pw.Font.courier()];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(localizations.translate('pdf_client_information'),
            style: pw.TextStyle(
                fontSize: 18,
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
                _infoRow(localizations.translate('pdf_name'),
                    '${partner.firstName} ${partner.lastName}'),
                if (partner.phoneNumber != null &&
                    partner.phoneNumber!.isNotEmpty)
                  _infoRow(localizations.translate('pdf_phone'),
                      partner.phoneNumber),
                if (partner.email != null && partner.email!.isNotEmpty)
                  _infoRow(localizations.translate('pdf_email'), partner.email),
              ],
            ),
            pw.SizedBox(width: 40),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (partner.adresse != null && partner.adresse!.isNotEmpty)
                  _infoRow(
                      localizations.translate('pdf_address'), partner.adresse),
                _infoRow(localizations.translate('pdf_account_type'),
                    partner.accountType),
                _infoRow(localizations.translate('pdf_balance'),
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
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.Text(value ?? '-', style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(width: 20),
      ],
    );
  }

  static pw.Widget _buildSummarySection(
    List<Versement> versements,
    List<Packages> packages,
    AppLocalizations localizations,
  ) {
    final font = localizations.locale.languageCode == 'zh'
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
        pw.Text(localizations.translate('pdf_summary'),
            style: pw.TextStyle(
                fontSize: 18,
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
                  child: pw.Text(localizations.translate('pdf_category'),
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold))),
              pw.Expanded(
                  child: pw.Text(localizations.translate('pdf_amount'),
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
                  child:
                      pw.Text(localizations.translate('pdf_total_versements'))),
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
                  child:
                      pw.Text(localizations.translate('pdf_total_retraits'))),
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
                  child:
                      pw.Text(localizations.translate('pdf_packages_count'))),
              pw.Expanded(child: pw.Text('${packages.length}')),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildVersementsSection(
      List<Versement> versements, AppLocalizations localizations) {
    final font = localizations.locale.languageCode == 'zh'
        ? pw.Font.courier()
        : pw.Font.helvetica();
    final fallbackFonts = [pw.Font.times(), pw.Font.courier()];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(localizations.translate('pdf_versements'),
            style: pw.TextStyle(
                fontSize: 18,
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
            localizations.translate('pdf_date'),
            localizations.translate('pdf_reference'),
            localizations.translate('pdf_amount_paid'),
            localizations.translate('pdf_type'),
            localizations.translate('pdf_remaining_amount')
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
      List<Packages> packages, AppLocalizations localizations) {
    final font = localizations.locale.languageCode == 'zh'
        ? pw.Font.courier()
        : pw.Font.helvetica();
    final fallbackFonts = [pw.Font.times(), pw.Font.courier()];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(localizations.translate('pdf_packages'),
            style: pw.TextStyle(
                fontSize: 18,
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
                        '${localizations.translate('pdf_from')}: ${package.startCountry}'),
                    pw.SizedBox(width: 10),
                    pw.Text(
                        '${localizations.translate('pdf_to')}: ${package.destinationCountry}'),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                    '${localizations.translate('pdf_status')}: ${package.status?.name ?? '-'}'),
                pw.SizedBox(height: 8),
                if (package.items != null && package.items!.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    context: null,
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headerDecoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    headers: [
                      localizations.translate('pdf_article'),
                      localizations.translate('pdf_quantity'),
                      localizations.translate('pdf_unit_price'),
                      localizations.translate('pdf_exchange_rate'),
                      localizations.translate('pdf_total')
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
}
