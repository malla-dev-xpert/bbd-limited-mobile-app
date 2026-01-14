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
import 'package:bbd_limited/models/achats/achat.dart';

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
                if (filteredVersements.isNotEmpty) ...[
                  _buildVersementsSection(
                      filteredVersements, printLocalizations),
                  pw.SizedBox(height: 24),
                  _buildPurchasedItemsSection(
                      filteredVersements, printLocalizations),
                ],
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

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // En-tête avec gradient et logo circulaire (même style que les factures)
        pw.Container(
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(2.5),
            border:
                pw.Border.all(color: PdfColor.fromHex('#1A1E49'), width: 1.5),
          ),
          child: pw.Row(
            children: [
              // Section gauche avec fond dégradé bleu clair
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: const pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      begin: pw.Alignment.centerLeft,
                      end: pw.Alignment.centerRight,
                      colors: [
                        PdfColors.blue100, // Bleu clair
                        PdfColors.white, // Blanc
                      ],
                    ),
                    borderRadius: pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(2.5),
                      bottomLeft: pw.Radius.circular(2.5),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Nom de l'entreprise
                      pw.Text(
                        'BBD LIMITED',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1A1E49'),
                          letterSpacing: 1.2,
                          font: font,
                          fontFallback: fallbackFonts,
                        ),
                      ),
                      pw.SizedBox(height: 10),

                      // Adresse en rouge
                      pw.Text(
                        '1Floor, Building 10,Room 102, Zhao Zhai san qu, Yiwu, Zhejiang, China',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.red700,
                          fontWeight: pw.FontWeight.normal,
                          font: font,
                          fontFallback: fallbackFonts,
                        ),
                      ),
                      pw.Text(
                        '中国 浙江省义乌市赵宅3区10栋1单元102',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.red700,
                          fontWeight: pw.FontWeight.normal,
                          font: font,
                          fontFallback: fallbackFonts,
                        ),
                      ),

                      // Ligne séparatrice bleu foncé
                      pw.SizedBox(height: 10),
                      pw.Container(
                        height: 1.5,
                        color: PdfColor.fromHex('#1A1E49'),
                      ),
                      pw.SizedBox(height: 10),

                      // Informations de contact
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Téléphones à gauche
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Contact :',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.black,
                                    font: font,
                                    fontFallback: fallbackFonts,
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  '0086 18678859834',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    font: font,
                                    fontFallback: fallbackFonts,
                                  ),
                                ),
                                pw.Text(
                                  '0086 13503032311',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    font: font,
                                    fontFallback: fallbackFonts,
                                  ),
                                ),
                                pw.Text(
                                  '0086 (579)85568522',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    font: font,
                                    fontFallback: fallbackFonts,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Email à droite
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'EMail :',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.black,
                                    font: font,
                                    fontFallback: fallbackFonts,
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  'bbd@bbdcompany.com',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    font: font,
                                    fontFallback: fallbackFonts,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Ligne verticale séparatrice
              pw.Container(
                width: 1.5,
                color: PdfColor.fromHex('#1A1E49'),
              ),

              // Section droite avec logo sur fond blanc
              pw.Container(
                width: 100,
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.only(
                    topRight: pw.Radius.circular(2.5),
                    bottomRight: pw.Radius.circular(2.5),
                  ),
                ),
                child: pw.Center(
                  child: pw.Container(
                    width: 75,
                    height: 75,
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#1A1E49'),
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Image(
                        pw.MemoryImage(logoBytes),
                        width: 70,
                        height: 70,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Titre du rapport
        pw.Text(
          printLocalizations.translate('pdf_client_status'),
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1A1E49'),
            letterSpacing: 1.2,
            font: font,
            fontFallback: fallbackFonts,
          ),
        ),
        pw.SizedBox(height: 8),

        // Période
        pw.Text(
          dateRange == null
              ? printLocalizations.translate('pdf_all_periods')
              : printLocalizations
                  .translate('pdf_from_to')
                  .replaceAll('{start}', _dateFormat.format(dateRange.start))
                  .replaceAll('{end}', _dateFormat.format(dateRange.end)),
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.black,
            font: font,
            fontFallback: fallbackFonts,
          ),
        ),
        pw.SizedBox(height: 16),
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
        // Informations client dans un conteneur avec le même style que les factures
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            children: [
              _buildInfoRowPDF(printLocalizations.translate('pdf_name'),
                  '${partner.firstName} ${partner.lastName}'),
              if (partner.phoneNumber.isNotEmpty)
                _buildInfoRowPDF(printLocalizations.translate('pdf_phone'),
                    partner.phoneNumber),
              if (partner.email.isNotEmpty)
                _buildInfoRowPDF(
                    printLocalizations.translate('pdf_email'), partner.email),
              if (partner.adresse.isNotEmpty)
                _buildInfoRowPDF(printLocalizations.translate('pdf_address'),
                    partner.adresse),
              _buildInfoRowPDF(printLocalizations.translate('pdf_account_type'),
                  partner.accountType),
              _buildInfoRowPDF(printLocalizations.translate('pdf_balance'),
                  partner.balance?.toStringAsFixed(2) ?? '0.00'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRowPDF(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
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
        .fold<double>(0, (sum, r) => sum + r.montant);

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
        // En-tête du tableau avec le même style que les produits
        pw.Container(
          color: PdfColor.fromHex('#E3F2FD'), // Bleu clair comme dans l'image
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: pw.Row(
            children: [
              pw.Expanded(
                  child: pw.Text(printLocalizations.translate('pdf_category'),
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Expanded(
                  child: pw.Text(printLocalizations.translate('pdf_amount'),
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
            ],
          ),
        ),
        // Corps du tableau avec le même style que les produits
        pw.Container(
          color: PdfColors.white,
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: pw.Row(
            children: [
              pw.Expanded(
                  child: pw.Text(
                      printLocalizations.translate('pdf_total_versements'),
                      style: pw.TextStyle(
                        fontSize: 8,
                        font: font,
                        fontFallback: fallbackFonts,
                      ),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Expanded(
                  child: pw.Text(_currencyFormat.format(totalVersements),
                      style: pw.TextStyle(
                        fontSize: 8,
                        font: font,
                        fontFallback: fallbackFonts,
                      ),
                      textAlign: pw.TextAlign.center)),
            ],
          ),
        ),
        pw.Container(
          color: PdfColors.white,
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: pw.Row(
            children: [
              pw.Expanded(
                  child: pw.Text(
                      printLocalizations.translate('pdf_total_retraits'),
                      style: pw.TextStyle(
                        fontSize: 8,
                        font: font,
                        fontFallback: fallbackFonts,
                      ),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Expanded(
                  child: pw.Text(_currencyFormat.format(totalRetraits),
                      style: pw.TextStyle(
                        fontSize: 8,
                        font: font,
                        fontFallback: fallbackFonts,
                      ),
                      textAlign: pw.TextAlign.center)),
            ],
          ),
        ),
        pw.Container(
          color: PdfColors.white,
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: pw.Row(
            children: [
              pw.Expanded(
                  child: pw.Text(
                      printLocalizations.translate('pdf_packages_count'),
                      style: pw.TextStyle(
                        fontSize: 8,
                        font: font,
                        fontFallback: fallbackFonts,
                      ),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Expanded(
                  child: pw.Text('${packages.length}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        font: font,
                        fontFallback: fallbackFonts,
                      ),
                      textAlign: pw.TextAlign.center)),
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
        // En-tête du tableau avec le même style que les produits
        pw.Container(
          color: PdfColor.fromHex('#E3F2FD'), // Bleu clair comme dans l'image
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: pw.Row(
            children: [
              pw.Container(
                  width: 80,
                  child: pw.Text(printLocalizations.translate('pdf_date'),
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 80,
                  child: pw.Text(printLocalizations.translate('pdf_reference'),
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 80,
                  child: pw.Text(
                      printLocalizations.translate('pdf_amount_paid'),
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 60,
                  child: pw.Text('Currency',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 60,
                  child: pw.Text(
                      printLocalizations.translate('pdf_exchange_rate'),
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 60,
                  child: pw.Text(printLocalizations.translate('pdf_type'),
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Expanded(
                  child: pw.Text(
                      printLocalizations.translate('pdf_remaining_amount'),
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
            ],
          ),
        ),
        // Corps du tableau avec le même style que les produits
        for (final v in versements)
          pw.Container(
            color: PdfColors.white,
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: pw.Row(
              children: [
                pw.Container(
                    width: 80,
                    child: pw.Text(
                      _dateFormat.format(v.createdAt ?? DateTime.now()),
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    )),
                pw.SizedBox(width: 3),
                pw.Container(
                    width: 80,
                    child: pw.Text(
                      v.reference ?? '-',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                      maxLines: 2,
                    )),
                pw.SizedBox(width: 3),
                pw.Container(
                    width: 80,
                    child: pw.Text(
                      _currencyFormat.format(v.montantVerser ?? 0),
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    )),
                pw.SizedBox(width: 3),
                pw.Container(
                    width: 60,
                    child: pw.Text(
                      v.deviseCode ?? '-',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    )),
                pw.SizedBox(width: 3),
                pw.Container(
                    width: 60,
                    child: pw.Text(
                      v.tauxUtilise?.toStringAsFixed(2) ?? '-',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    )),
                pw.SizedBox(width: 3),
                pw.Container(
                    width: 60,
                    child: pw.Text(
                      v.type ?? '-',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                      maxLines: 2,
                    )),
                pw.SizedBox(width: 3),
                pw.Expanded(
                    child: pw.Text(
                  _currencyFormat.format(v.montantRestant ?? 0),
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                )),
              ],
            ),
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
                    '${printLocalizations.translate('pdf_status')}: ${printLocalizations.translateStatus(package.status)}'),
                pw.SizedBox(height: 8),
                if (package.items != null && package.items!.isNotEmpty) ...[
                  // En-tête du tableau avec le même style que les produits
                  pw.Container(
                    color: PdfColor.fromHex(
                        '#E3F2FD'), // Bleu clair comme dans l'image
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 6, horizontal: 4),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                                printLocalizations.translate('pdf_article'),
                                style: pw.TextStyle(
                                    color: PdfColor.fromHex('#1A1E49'),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8),
                                maxLines: 2)),
                        pw.SizedBox(width: 3),
                        pw.Container(
                            width: 60,
                            child: pw.Text(
                                printLocalizations.translate('pdf_quantity'),
                                style: pw.TextStyle(
                                    color: PdfColor.fromHex('#1A1E49'),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8),
                                textAlign: pw.TextAlign.center)),
                        pw.SizedBox(width: 3),
                        pw.Container(
                            width: 70,
                            child: pw.Text(
                                printLocalizations.translate('pdf_unit_price'),
                                style: pw.TextStyle(
                                    color: PdfColor.fromHex('#1A1E49'),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8),
                                textAlign: pw.TextAlign.center)),
                        pw.SizedBox(width: 3),
                        pw.Container(
                            width: 70,
                            child: pw.Text(
                                printLocalizations
                                    .translate('pdf_exchange_rate'),
                                style: pw.TextStyle(
                                    color: PdfColor.fromHex('#1A1E49'),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8),
                                textAlign: pw.TextAlign.center)),
                        pw.SizedBox(width: 3),
                        pw.Container(
                            width: 70,
                            child: pw.Text(
                                printLocalizations.translate('pdf_total'),
                                style: pw.TextStyle(
                                    color: PdfColor.fromHex('#1A1E49'),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8),
                                textAlign: pw.TextAlign.center)),
                      ],
                    ),
                  ),
                  // Corps du tableau avec le même style que les produits
                  for (final item in package.items!)
                    pw.Container(
                      color: PdfColors.white,
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 4, horizontal: 4),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                item.description ?? '-',
                                style: const pw.TextStyle(fontSize: 8),
                                maxLines: 2,
                              )),
                          pw.SizedBox(width: 3),
                          pw.Container(
                              width: 60,
                              child: pw.Text(
                                '${item.quantity}',
                                style: const pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.center,
                              )),
                          pw.SizedBox(width: 3),
                          pw.Container(
                              width: 70,
                              child: pw.Text(
                                _currencyFormat.format(item.unitPrice ?? 0),
                                style: const pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.center,
                              )),
                          pw.SizedBox(width: 3),
                          pw.Container(
                              width: 70,
                              child: pw.Text(
                                _currencyFormat.format(item.salesRate ?? 0),
                                style: const pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.center,
                              )),
                          pw.SizedBox(width: 3),
                          pw.Container(
                              width: 70,
                              child: pw.Text(
                                _currencyFormat.format(item.totalPrice ?? 0),
                                style: const pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.center,
                              )),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildPurchasedItemsSection(
      List<Versement> versements, PrintLocalizations printLocalizations) {
    final font = printLocalizations.language.code == 'zh'
        ? pw.Font.courier()
        : pw.Font.helvetica();
    final fallbackFonts = [pw.Font.times(), pw.Font.courier()];

    // Collecter tous les articles de tous les achats
    final List<({Items item, String versementRef})> allItems = [];
    for (final versement in versements) {
      for (final achat in (versement.achats ?? [])) {
        for (final item in (achat.items ?? [])) {
          // Déterminer la référence du versement ou "Dette"
          final versementRef = (achat.isDebt == true ||
                  achat.referenceVersement == null ||
                  achat.referenceVersement!.isEmpty)
              ? 'Dette'
              : achat.referenceVersement!;
          allItems.add((item: item, versementRef: versementRef));
        }
      }
    }

    if (allItems.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(printLocalizations.translate("pdf_articles_list_label"),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1E49'),
              font: font,
              fontFallback: fallbackFonts,
            )),
        pw.SizedBox(height: 8),
        // En-tête du tableau avec le même style que les produits
        pw.Container(
          color: PdfColor.fromHex('#E3F2FD'), // Bleu clair comme dans l'image
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: pw.Row(
            children: [
              pw.Expanded(
                  flex: 3,
                  child: pw.Text('Product Name',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      maxLines: 2)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 100,
                  child: pw.Text('Versement Ref.',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 50,
                  child: pw.Text('Quantity',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 70,
                  child: pw.Text('Unit Price',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 70,
                  child: pw.Text('Total',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
            ],
          ),
        ),
        // Calcul du total avant de générer les widgets
        _buildPurchasedItemsTable(
            allItems, font, fallbackFonts, printLocalizations),
      ],
    );
  }

  static pw.Widget _buildPurchasedItemsTable(
      List<({Items item, String versementRef})> allItems,
      pw.Font font,
      List<pw.Font> fallbackFonts,
      PrintLocalizations printLocalizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Corps du tableau avec le même style que les produits
        ...allItems.map((entry) => pw.Container(
              color: PdfColors.white,
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: pw.Row(
                children: [
                  pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        entry.item.description ?? '-',
                        style: pw.TextStyle(
                          fontSize: 8,
                          font: font,
                          fontFallback: fallbackFonts,
                        ),
                        maxLines: 2,
                      )),
                  pw.SizedBox(width: 3),
                  pw.Container(
                      width: 100,
                      child: pw.Text(
                        entry.versementRef,
                        style: pw.TextStyle(
                          fontSize: 8,
                          font: font,
                          fontFallback: fallbackFonts,
                        ),
                        textAlign: pw.TextAlign.center,
                        maxLines: 2,
                      )),
                  pw.SizedBox(width: 3),
                  pw.Container(
                      width: 50,
                      child: pw.Text(
                        '${entry.item.quantity ?? 0}',
                        style: pw.TextStyle(
                          fontSize: 8,
                          font: font,
                          fontFallback: fallbackFonts,
                        ),
                        textAlign: pw.TextAlign.center,
                      )),
                  pw.SizedBox(width: 3),
                  pw.Container(
                      width: 70,
                      child: pw.Text(
                        _currencyFormat.format(entry.item.unitPrice ?? 0),
                        style: pw.TextStyle(
                          fontSize: 8,
                          font: font,
                          fontFallback: fallbackFonts,
                        ),
                        textAlign: pw.TextAlign.center,
                      )),
                  pw.SizedBox(width: 3),
                  pw.Container(
                      width: 70,
                      child: pw.Text(
                        _currencyFormat.format(entry.item.totalPrice ?? 0),
                        style: pw.TextStyle(
                          fontSize: 8,
                          font: font,
                          fontFallback: fallbackFonts,
                        ),
                        textAlign: pw.TextAlign.center,
                      )),
                ],
              ),
            )),
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
