import 'dart:typed_data';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/cashWithdrawal.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/models/invoice_options.dart';

class VersementPrintService {
  static Future<Uint8List> buildVersementPdfBytes(
    Versement versement,
    List<Achat> achats,
    List<CashWithdrawal> retraits,
    AppLocalizations localizations, {
    InvoiceOptions? invoiceOptions,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
        locale: 'fr_FR', symbol: versement.deviseCode ?? 'CNY');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final Uint8List logoBytes = await rootBundle
        .load('assets/images/logo.png')
        .then((data) => data.buffer.asUint8List());

    // Calcul du sous-total
    double sousTotal = 0;
    for (final achat in achats) {
      for (final item in (achat.items ?? [])) {
        sousTotal += item.totalPrice ?? 0;
      }
    }

    // Application des options de facturation
    final options = invoiceOptions ?? const InvoiceOptions();
    double montantTotal = options.calculateTotal(sousTotal);

    // Calcul du total des retraits
    double totalRetraits = retraits.fold(0, (sum, r) => sum + (r.montant ?? 0));

    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.zero,
        build: (ctx) => [
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
                      _buildHeader(logoBytes, versement, dateFormat,
                          localizations, currencyFormat),
                      pw.SizedBox(height: 24),
                      _buildClientInfo(versement, localizations),
                      pw.SizedBox(height: 24),
                      _buildArticlesSection(
                          achats, localizations, currencyFormat, options),
                      pw.SizedBox(height: 12),
                      _buildPricingSummary(sousTotal, montantTotal, options,
                          currencyFormat, localizations),
                      if (retraits.isNotEmpty) ...[
                        pw.SizedBox(height: 24),
                        _buildWithdrawalsSection(retraits, localizations,
                            currencyFormat, dateFormat),
                        pw.SizedBox(height: 8),
                        _buildWithdrawalsTotal(
                            totalRetraits, currencyFormat, localizations),
                      ],
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

  static Future<Uint8List> buildAchatPdfBytes(
    Achat achat, {
    required bool includeSupplierInfo,
    required NumberFormat currencyFormat,
    required AppLocalizations localizations,
    bool isProforma = false,
    InvoiceOptions? invoiceOptions,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final Uint8List logoBytes = await rootBundle
        .load('assets/images/logo.png')
        .then((data) => data.buffer.asUint8List());

    // Filtrer les items selon le type de document
    final filteredItems = isProforma
        ? achat.items // Pour pro-forma, on prend tous les items
        : achat.items
            ?.where((item) => item.status == Status.RECEIVED)
            .toList(); // Pour facture réelle, seulement les reçus

    // Calcul du sous-total sur les items filtrés
    double sousTotal =
        filteredItems?.fold(0, (sum, item) => sum! + (item.totalPrice ?? 0)) ??
            0;

    // Application des options de facturation
    final options = invoiceOptions ?? const InvoiceOptions();
    double montantTotal = options.calculateTotal(sousTotal);

    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.zero,
        build: (ctx) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 20,
                height: 800,
                color: isProforma
                    ? PdfColors.grey400
                    : PdfColor.fromHex('#1A1E49'),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(24),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildAchatHeader(logoBytes, achat, dateFormat,
                          localizations, isProforma),
                      pw.SizedBox(height: 24),
                      _buildAchatArticlesSection(filteredItems, localizations,
                          includeSupplierInfo, isProforma, currencyFormat),
                      pw.SizedBox(height: 12),
                      _buildAchatPricingSummary(sousTotal, montantTotal,
                          options, currencyFormat, localizations, isProforma),
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

  // Méthodes privées pour la construction des sections
  static pw.Widget _buildHeader(
      Uint8List logoBytes,
      Versement versement,
      DateFormat dateFormat,
      AppLocalizations localizations,
      NumberFormat currencyFormat) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Image(pw.MemoryImage(logoBytes), width: 100),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(localizations.translate('pdf_invoice'),
                style: pw.TextStyle(
                    fontSize: 32,
                    color: PdfColor.fromHex('#1A1E49'),
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 4,
                    font: localizations.locale.languageCode == 'zh'
                        ? pw.Font.courier()
                        : pw.Font.helvetica(),
                    fontFallback: [pw.Font.times(), pw.Font.courier()])),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(localizations.translate('pdf_versement_reference'),
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      )),
                  pw.Text(
                    versement.reference ?? '',
                    style: pw.TextStyle(
                      fontSize: 15,
                      color: PdfColor.fromHex('#1A1E49'),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(localizations.translate('pdf_versement_date'),
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      )),
                  pw.Text(
                    dateFormat.format(versement.createdAt ?? DateTime.now()),
                    style: pw.TextStyle(
                      fontSize: 15,
                      color: PdfColor.fromHex('#1A1E49'),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ]),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(localizations.translate('pdf_amount_paid_label'),
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      )),
                  pw.Text(
                    currencyFormat.format(versement.montantVerser),
                    style: pw.TextStyle(
                      fontSize: 15,
                      color: PdfColor.fromHex('#1A1E49'),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(localizations.translate('pdf_remaining_amount_label'),
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      )),
                  pw.Text(
                    currencyFormat.format(versement.montantRestant),
                    style: pw.TextStyle(
                      fontSize: 15,
                      color: PdfColor.fromHex('#1A1E49'),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ]),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildClientInfo(
      Versement versement, AppLocalizations localizations) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(children: [
                pw.Text(versement.partnerName ?? '',
                    style: pw.TextStyle(
                        fontSize: 20,
                        color: PdfColor.fromHex('#1A1E49'),
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 10),
                if (versement.partnerPhone != null)
                  pw.Text('(${versement.partnerPhone!})',
                      style: pw.TextStyle(
                          fontSize: 20,
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold)),
              ]),
              if (versement.note != null && versement.note!.isNotEmpty)
                pw.Text(versement.note!,
                    style: const pw.TextStyle(fontSize: 16)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(localizations.translate('pdf_commissionnaire'),
                  style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColor.fromHex('#1A1E49'),
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                      font: localizations.locale.languageCode == 'zh'
                          ? pw.Font.courier()
                          : pw.Font.helvetica(),
                      fontFallback: [pw.Font.times(), pw.Font.courier()])),
              pw.Text(
                  '${localizations.translate('pdf_commissionnaire_name')} : ${versement.commissionnaireName}',
                  style: pw.TextStyle(fontSize: 16)),
              pw.Text(
                  '${localizations.translate('pdf_commissionnaire_phone')} : ${versement.commissionnairePhone}',
                  style: pw.TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildArticlesSection(
      List<Achat> achats,
      AppLocalizations localizations,
      NumberFormat currencyFormat,
      InvoiceOptions options) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(localizations.translate("pdf_articles_list"),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1E49'),
              font: localizations.locale.languageCode == 'zh'
                  ? pw.Font.courier()
                  : pw.Font.helvetica(),
              fontFallback: [pw.Font.times(), pw.Font.courier()],
            )),
        pw.SizedBox(height: 8),
        pw.Container(
          color: PdfColor.fromHex('#1A1E49'),
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: pw.Row(
            children: [
              pw.Container(
                  width: 120,
                  child: pw.Text(localizations.translate('pdf_designation'),
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8))),
              pw.Container(
                  width: 40,
                  child: pw.Text(localizations.translate('pdf_carton'),
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8))),
              pw.Container(
                  width: 50,
                  child: pw.Text(
                      localizations.translate('pdf_quantity_per_carton'),
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8))),
              pw.Container(
                  width: 60,
                  child: pw.Text(localizations.translate('pdf_purchase_rate'),
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8))),
              pw.Container(
                  width: 80,
                  child: pw.Text(
                      localizations.translate('pdf_unit_price_short'),
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8))),
              pw.Container(
                  width: 80,
                  child: pw.Text(localizations.translate('pdf_total'),
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8))),
            ],
          ),
        ),
        for (final achat in achats)
          for (final item in (achat.items ?? []))
            pw.Container(
              color: PdfColors.grey200,
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: pw.Row(
                children: [
                  pw.Container(
                      width: 120,
                      child: pw.Text(item.description ?? '',
                          style: const pw.TextStyle(fontSize: 16))),
                  pw.Container(
                      width: 40,
                      child: pw.Text('${item.carton ?? ''}',
                          style: const pw.TextStyle(fontSize: 16))),
                  pw.Container(
                      width: 50,
                      child: pw.Text('${item.quantityPerCarton ?? ''}',
                          style: const pw.TextStyle(fontSize: 16))),
                  pw.Container(
                      width: 60,
                      child: pw.Text('${item.salesRate ?? ''}',
                          style: const pw.TextStyle(fontSize: 16))),
                  pw.Container(
                      width: 80,
                      child: pw.Text(currencyFormat.format(item.unitPrice ?? 0),
                          style: const pw.TextStyle(fontSize: 16))),
                  pw.Container(
                      width: 80,
                      child: pw.Text(
                          currencyFormat.format(item.totalPrice ?? 0),
                          style: const pw.TextStyle(fontSize: 16))),
                ],
              ),
            ),
      ],
    );
  }

  static pw.Widget _buildPricingSummary(
      double sousTotal,
      double montantTotal,
      InvoiceOptions options,
      NumberFormat currencyFormat,
      AppLocalizations localizations) {
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
                  'Sous-total :',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Text(
                  currencyFormat.format(sousTotal),
                  style: pw.TextStyle(
                    fontSize: 16,
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
                        ? 'Marge par ligne (${options.lineMarginValue}%) :'
                        : 'Marge par ligne (${options.lineMarginValue}) :',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    currencyFormat.format(
                        options.lineMarginType == MarginType.percentage
                            ? (sousTotal * options.lineMarginValue! / 100)
                            : options.lineMarginValue!),
                    style: pw.TextStyle(
                      fontSize: 16,
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
                        ? 'Remise (${options.discountValue}%) :'
                        : 'Remise :',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    '-${currencyFormat.format(options.discountType == DiscountType.percentage ? (sousTotal * options.discountValue! / 100) : options.discountValue!)}',
                    style: pw.TextStyle(
                      fontSize: 16,
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
                        ? 'Frais d\'entreposage (${options.storageFeeAmount}%) :'
                        : 'Frais d\'entreposage :',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    currencyFormat.format(
                        options.storageFeeType == StorageFeeType.percentage
                            ? (sousTotal * options.storageFeeAmount! / 100)
                            : options.storageFeeAmount!),
                    style: pw.TextStyle(
                      fontSize: 16,
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
                        ? 'Marge globale (${options.globalMarginValue}%) :'
                        : 'Marge globale (${options.globalMarginValue}) :',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    currencyFormat.format(
                        options.globalMarginType == MarginType.percentage
                            ? (montantTotal * options.globalMarginValue! / 100)
                            : options.globalMarginValue!),
                    style: pw.TextStyle(
                      fontSize: 16,
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
            'TOTAL FINAL : ${currencyFormat.format(montantTotal)}',
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

  static pw.Widget _buildWithdrawalsSection(
      List<CashWithdrawal> retraits,
      AppLocalizations localizations,
      NumberFormat currencyFormat,
      DateFormat dateFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(localizations.translate("pdf_cash_withdrawals_list"),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1E49'),
            )),
        pw.SizedBox(height: 8),
        pw.Container(
          color: PdfColor.fromHex('#1A1E49'),
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: pw.Row(
            children: [
              pw.Container(
                  width: 100,
                  child: pw.Text(localizations.translate('pdf_withdrawal_date'),
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold))),
              pw.Container(
                  width: 100,
                  child: pw.Text(
                      localizations.translate('pdf_withdrawal_amount'),
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold))),
              pw.Expanded(
                  child: pw.Text(
                      localizations.translate('pdf_withdrawal_reason'),
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold))),
            ],
          ),
        ),
        ...retraits.map((r) => pw.Container(
              color: PdfColors.grey200,
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 100,
                    child: pw.Text(
                      r.dateRetrait != null
                          ? dateFormat.format(r.dateRetrait!)
                          : localizations.translate('pdf_unknown_date'),
                    ),
                  ),
                  pw.Container(
                      width: 100,
                      child: pw.Text(currencyFormat.format(r.montant))),
                  pw.Expanded(child: pw.Text(r.note ?? '')),
                ],
              ),
            )),
      ],
    );
  }

  static pw.Widget _buildWithdrawalsTotal(double totalRetraits,
      NumberFormat currencyFormat, AppLocalizations localizations) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
            '${localizations.translate('pdf_total_withdrawals')} : ${currencyFormat.format(totalRetraits)}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildAchatHeader(Uint8List logoBytes, Achat achat,
      DateFormat dateFormat, AppLocalizations localizations, bool isProforma) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Image(pw.MemoryImage(logoBytes), width: 100),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
                isProforma
                    ? localizations.translate('pdf_proforma')
                    : localizations.translate('pdf_purchase_invoice'),
                style: pw.TextStyle(
                    fontSize: 32,
                    color: PdfColor.fromHex('#1A1E49'),
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 4,
                    font: localizations.locale.languageCode == 'zh'
                        ? pw.Font.courier()
                        : pw.Font.helvetica(),
                    fontFallback: [pw.Font.times(), pw.Font.courier()])),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(localizations.translate('pdf_reference_label'),
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      )),
                  pw.Text(
                    'ACH-${achat.id}',
                    style: pw.TextStyle(
                      fontSize: 15,
                      color: PdfColor.fromHex('#1A1E49'),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(localizations.translate('pdf_date_label'),
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      )),
                  pw.Text(
                    dateFormat.format(achat.createdAt ?? DateTime.now()),
                    style: pw.TextStyle(
                      fontSize: 15,
                      color: PdfColor.fromHex('#1A1E49'),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ]),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildAchatArticlesSection(
      List<dynamic>? filteredItems,
      AppLocalizations localizations,
      bool includeSupplierInfo,
      bool isProforma,
      NumberFormat currencyFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(localizations.translate("pdf_articles_list_label"),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1E49'),
              font: localizations.locale.languageCode == 'zh'
                  ? pw.Font.courier()
                  : pw.Font.helvetica(),
              fontFallback: [pw.Font.times(), pw.Font.courier()],
            )),
        pw.SizedBox(height: 8),
        pw.Container(
          color: isProforma ? PdfColors.grey100 : PdfColor.fromHex('#1A1E49'),
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: pw.Row(
            children: [
              pw.Expanded(
                  child: pw.Text(
                      localizations.translate('pdf_designation_label'),
                      style: pw.TextStyle(
                          color:
                              isProforma ? PdfColors.grey500 : PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold))),
              if (isProforma) // Colonne statut seulement pour pro-forma
                pw.Container(
                    width: 60,
                    child: pw.Text(localizations.translate('pdf_status_label'),
                        style: pw.TextStyle(
                            color: isProforma
                                ? PdfColors.grey500
                                : PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold))),
              if (includeSupplierInfo &&
                  filteredItems?.isNotEmpty == true &&
                  filteredItems?.first.supplierName != null)
                pw.Container(
                    width: 80,
                    child: pw.Text(localizations.translate('pdf_supplier'),
                        style: pw.TextStyle(
                            color: isProforma
                                ? PdfColors.grey500
                                : PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold))),
              pw.Container(
                  width: 40,
                  child: pw.Text(localizations.translate('pdf_carton'),
                      style: pw.TextStyle(
                          color:
                              isProforma ? PdfColors.grey500 : PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold))),
              pw.Container(
                  width: 50,
                  child: pw.Text(
                      localizations.translate('pdf_quantity_per_carton'),
                      style: pw.TextStyle(
                          color:
                              isProforma ? PdfColors.grey500 : PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold))),
              pw.Container(
                  width: 60,
                  child: pw.Text(localizations.translate('pdf_rate'),
                      style: pw.TextStyle(
                          color:
                              isProforma ? PdfColors.grey500 : PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold))),
              pw.Container(
                  width: 80,
                  child: pw.Text(
                      localizations.translate('pdf_unit_price_label'),
                      style: pw.TextStyle(
                          color:
                              isProforma ? PdfColors.grey500 : PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold))),
              pw.Container(
                  width: 80,
                  child: pw.Text(localizations.translate('pdf_total'),
                      style: pw.TextStyle(
                          color:
                              isProforma ? PdfColors.grey500 : PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold))),
            ],
          ),
        ),
        for (final item in (filteredItems ?? []))
          pw.Container(
            color: PdfColors.grey200,
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: pw.Row(
              children: [
                pw.Expanded(
                    child: pw.Text(item.description ?? '',
                        style: const pw.TextStyle(fontSize: 16))),
                if (isProforma) // Colonne statut seulement pour pro-forma
                  pw.Container(
                    width: 60,
                    child: pw.Text(
                      item.status == Status.RECEIVED
                          ? localizations.translate('pdf_received')
                          : localizations.translate('pdf_pending'),
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: item.status == Status.RECEIVED
                            ? PdfColors.green
                            : PdfColors.orange,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                if (includeSupplierInfo &&
                    filteredItems?.isNotEmpty == true &&
                    item.supplierName != null)
                  pw.Container(
                    width: 80,
                    child: pw.Text(item.supplierName ?? '',
                        style: const pw.TextStyle(fontSize: 16)),
                  ),
                pw.Container(
                    width: 40,
                    child: pw.Text('${item.carton ?? ''}',
                        style: const pw.TextStyle(fontSize: 16))),
                pw.Container(
                    width: 50,
                    child: pw.Text('${item.quantityPerCarton ?? ''}',
                        style: const pw.TextStyle(fontSize: 16))),
                pw.Container(
                    width: 60,
                    child: pw.Text('${item.salesRate ?? ''}',
                        style: const pw.TextStyle(fontSize: 16))),
                pw.Container(
                    width: 80,
                    child: pw.Text(currencyFormat.format(item.unitPrice ?? 0),
                        style: const pw.TextStyle(fontSize: 16))),
                pw.Container(
                    width: 80,
                    child: pw.Text(currencyFormat.format(item.totalPrice ?? 0),
                        style: const pw.TextStyle(fontSize: 16))),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _buildAchatPricingSummary(
      double sousTotal,
      double montantTotal,
      InvoiceOptions options,
      NumberFormat currencyFormat,
      AppLocalizations localizations,
      bool isProforma) {
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
                  'Sous-total :',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Text(
                  currencyFormat.format(sousTotal),
                  style: pw.TextStyle(
                    fontSize: 16,
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
                        ? 'Marge par ligne (${options.lineMarginValue}%) :'
                        : 'Marge par ligne (${options.lineMarginValue}) :',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    currencyFormat.format(
                        options.lineMarginType == MarginType.percentage
                            ? (sousTotal * options.lineMarginValue! / 100)
                            : options.lineMarginValue!),
                    style: pw.TextStyle(
                      fontSize: 16,
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
                        ? 'Remise (${options.discountValue}%) :'
                        : 'Remise :',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    '-${currencyFormat.format(options.discountType == DiscountType.percentage ? (sousTotal * options.discountValue! / 100) : options.discountValue!)}',
                    style: pw.TextStyle(
                      fontSize: 16,
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
                        ? 'Frais d\'entreposage (${options.storageFeeAmount}%) :'
                        : 'Frais d\'entreposage :',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    currencyFormat.format(
                        options.storageFeeType == StorageFeeType.percentage
                            ? (sousTotal * options.storageFeeAmount! / 100)
                            : options.storageFeeAmount!),
                    style: pw.TextStyle(
                      fontSize: 16,
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
                        ? 'Marge globale (${options.globalMarginValue}%) :'
                        : 'Marge globale (${options.globalMarginValue}) :',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    currencyFormat.format(
                        options.globalMarginType == MarginType.percentage
                            ? (montantTotal * options.globalMarginValue! / 100)
                            : options.globalMarginValue!),
                    style: pw.TextStyle(
                      fontSize: 16,
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
            'TOTAL FINAL : ${currencyFormat.format(montantTotal)}',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1E49'),
            ),
          ),

          if (isProforma) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              localizations.translate('pdf_estimated_amount'),
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
