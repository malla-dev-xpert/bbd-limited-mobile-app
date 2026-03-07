import 'dart:typed_data';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/print/pdf_header.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/cashWithdrawal.dart';
import 'package:bbd_limited/core/print/print_localizations.dart';
import 'package:bbd_limited/core/services/margin_calculation_service.dart';
import 'package:bbd_limited/models/invoice_options.dart';
import 'package:bbd_limited/models/selective_margin.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/core/print/print_styles.dart';

class InvoiceService {
  static Future<Uint8List> buildVersementPdfBytes(
    Versement versement,
    List<Achat> achats,
    List<CashWithdrawal> retraits,
    PrintLocalizations printLocalizations, {
    InvoiceOptions? invoiceOptions,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
        locale: 'fr_FR', symbol: versement.deviseCode ?? 'CNY');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final Uint8List logoBytes = await rootBundle
        .load('assets/images/logo.png')
        .then((data) => data.buffer.asUint8List());
    final headerFonts = await PdfHeader.loadFonts();

    // Calcul du sous-total (avec marges sélectives si activées)
    final options = invoiceOptions ?? const InvoiceOptions();
    double sousTotal = 0;
    for (final achat in achats) {
      for (final item in (achat.items ?? [])) {
        if (options.enableSelectiveItemMargins &&
            item.id != null &&
            options.selectiveItemMargins.containsKey(item.id)) {
          // Utiliser le prix ajusté avec marge sélective
          final margin = options.selectiveItemMargins[item.id]!;
          sousTotal += margin.adjustedTotalPrice;
        } else {
          // Prix original
          sousTotal += item.totalPrice ?? 0;
        }
      }
    }

    // Calculer le total avec toutes les options (y compris marges sélectives)
    final allItems = <Items>[];
    for (final achat in achats) {
      allItems.addAll(achat.items ?? []);
    }
    final calculationResult =
        MarginCalculationService.calculateWithSelectiveMargins(
      subtotal: sousTotal,
      items: allItems,
      options: options,
      selectiveItemMargins: options.selectiveItemMargins,
      selectiveFeeMargins: options.selectiveFeeMargins,
      selectiveLineDiscounts: options.selectiveLineDiscounts,
    );
    double montantTotal = calculationResult.finalTotal;

    // Calcul du total des retraits
    double totalRetraits = retraits.fold(0.0, (sum, r) => sum + r.montant);

    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.zero,
        build: (ctx) => [
          pw.Padding(
            padding: pw.EdgeInsets.all(PrintStyles.pageMargin),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(logoBytes, headerFonts, versement, dateFormat,
                    printLocalizations, currencyFormat),
                pw.SizedBox(height: 24),
                _buildArticlesSection(achats, versement, printLocalizations,
                    currencyFormat, options,
                    sousTotal: sousTotal, montantTotal: montantTotal),
                pw.SizedBox(height: 12),
                _buildPricingSummary(sousTotal, montantTotal, options,
                    currencyFormat, printLocalizations, achats),
                if (retraits.isNotEmpty) ...[
                  pw.SizedBox(height: 24),
                  _buildWithdrawalsSection(
                      retraits, printLocalizations, currencyFormat, dateFormat),
                  pw.SizedBox(height: 8),
                  _buildWithdrawalsTotal(
                      totalRetraits, currencyFormat, printLocalizations),
                ],
              ],
            ),
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
    required PrintLocalizations printLocalizations,
    bool isProforma = false,
    InvoiceOptions? invoiceOptions,
    List<Containers>? containers,
    Versement? versement,
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

    // Calcul du sous-total sur les items filtrés (avec marges sélectives si activées)
    final options = invoiceOptions ?? const InvoiceOptions();
    double sousTotal = 0;
    for (final item in (filteredItems ?? [])) {
      if (options.enableSelectiveItemMargins &&
          item.id != null &&
          options.selectiveItemMargins.containsKey(item.id)) {
        // Utiliser le prix ajusté avec marge sélective
        final margin = options.selectiveItemMargins[item.id]!;
        sousTotal += margin.adjustedTotalPrice;
      } else {
        // Prix original
        sousTotal += item.totalPrice ?? 0;
      }
    }

    // Calculer le total avec toutes les options (y compris marges sélectives)
    final calculationResult =
        MarginCalculationService.calculateWithSelectiveMargins(
      subtotal: sousTotal,
      items: filteredItems?.cast<Items>() ?? [],
      options: options,
      selectiveItemMargins: options.selectiveItemMargins,
      selectiveFeeMargins: options.selectiveFeeMargins,
      selectiveLineDiscounts: options.selectiveLineDiscounts,
    );
    double montantTotal = calculationResult.finalTotal;

    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.zero,
        build: (ctx) => [
          pw.Padding(
            padding: pw.EdgeInsets.all(PrintStyles.pageMargin),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildAchatHeader(logoBytes, achat, dateFormat,
                    printLocalizations, isProforma),
                pw.SizedBox(height: 24),
                if (containers != null && containers.isNotEmpty) ...[
                  _buildContainerFeesSection(
                      containers, printLocalizations, currencyFormat),
                  pw.SizedBox(height: 24),
                ],
                _buildAchatArticlesSection(
                    filteredItems,
                    printLocalizations,
                    includeSupplierInfo,
                    isProforma,
                    currencyFormat,
                    options,
                    achat,
                    versement,
                    sousTotal: sousTotal,
                    montantTotal: montantTotal),
                if (versement != null) ...[
                  _buildVersementInfoSection(versement, currencyFormat,
                      dateFormat, printLocalizations)!,
                ],
                pw.SizedBox(height: 12),
                _buildAchatPricingSummary(
                    sousTotal,
                    montantTotal,
                    options,
                    currencyFormat,
                    printLocalizations,
                    isProforma,
                    filteredItems,
                    [achat]),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildContainerFeesSection(
    List<Containers> containers,
    PrintLocalizations printLocalizations,
    NumberFormat currencyFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Informations Conteneur(s)", // TODO: Add to translations if needed
          style: PrintStyles.sectionTitleStyle(),
        ),
        pw.SizedBox(height: 8),
        ...containers.map((container) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: PrintStyles.tableBorder,
              borderRadius: pw.BorderRadius.circular(4),
              color: PdfColors.white,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Conteneur: ${container.reference ?? 'N/A'}",
                  style: PrintStyles.labelStyle(),
                ),
                pw.Divider(color: PrintStyles.tableBorderColor),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (container.locationFee != null)
                            _buildFeeRow(
                                "Frais de location",
                                container.locationFee,
                                container.locationFeeCurrencyCode,
                                currencyFormat),
                          if (container.localCharge != null)
                            _buildFeeRow(
                                "Charges locales",
                                container.localCharge,
                                container.localChargeCurrencyCode,
                                currencyFormat),
                          if (container.loadingFee != null)
                            _buildFeeRow(
                                "Frais de chargement",
                                container.loadingFee,
                                container.loadingFeeCurrencyCode,
                                currencyFormat),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (container.overweightFee != null)
                            _buildFeeRow(
                                "Surpoids",
                                container.overweightFee,
                                container.overweightFeeCurrencyCode,
                                currencyFormat),
                          if (container.checkingFee != null)
                            _buildFeeRow(
                                "Inspection",
                                container.checkingFee,
                                container.checkingFeeCurrencyCode,
                                currencyFormat),
                          if (container.telxFee != null)
                            _buildFeeRow("Frais TELEX", container.telxFee,
                                container.telxFeeCurrencyCode, currencyFormat),
                          if (container.otherFees != null)
                            _buildFeeRow(
                                "Autres frais",
                                container.otherFees,
                                container.otherFeesCurrencyCode,
                                currencyFormat),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildFeeRow(
      String label, double? amount, String? currencyCode, NumberFormat format) {
    if (amount == null) return pw.SizedBox.shrink();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: PrintStyles.smallStyle()),
          pw.Text(
            "${format.format(amount)} ${currencyCode ?? 'CNY'}",
            style: pw.TextStyle(
                fontSize: PrintStyles.smallFontSize,
                fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Méthodes privées pour la construction des sections
  // Nouveau design aligné sur l'image fournie
  static pw.Widget _buildHeader(
      Uint8List logoBytes,
      PdfHeaderFonts headerFonts,
      Versement versement,
      DateFormat dateFormat,
      PrintLocalizations printLocalizations,
      NumberFormat currencyFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfHeader.build(logoBytes, headerFonts),
        pw.SizedBox(height: 20),

        // Titre de la facture (style Market Finance)
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
          ),
          child: pw.Text(
            'Payment Invoice',
            style: PrintStyles.mainTitleStyle(),
          ),
        ),
        pw.SizedBox(height: 0),

        // Informations de la facture (grille style Market Finance : libellé vert, valeur blanc, bordures)
        pw.Container(
          decoration: pw.BoxDecoration(
            border: PrintStyles.tableBorder,
          ),
          child: pw.Column(
            children: [
              _buildInfoRowPDFGrid('Invoice No.', versement.reference ?? ''),
              _buildInfoRowPDFGrid('Invoice Date',
                  dateFormat.format(versement.createdAt ?? DateTime.now())),
              _buildInfoRowPDFGrid('Currency', versement.deviseCode ?? 'CNY'),
              _buildInfoRowPDFGrid('Exchange Rate', '1.00'),
              if (versement.montantVerser != null)
                _buildInfoRowPDFGrid('Amount Paid',
                    currencyFormat.format(versement.montantVerser!)),
              if (versement.montantRestant != null)
                _buildInfoRowPDFGrid('Remaining Amount',
                    currencyFormat.format(versement.montantRestant!)),
            ],
          ),
        ),

        // Section Client et Commissionnaire
        pw.SizedBox(height: 20),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Section Client
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Client',
                    style: PrintStyles.sectionTitleStyle(),
                  ),
                  pw.SizedBox(height: 10),
                  if (versement.partnerName != null)
                    _buildClientInfoRowPDF('Nom', versement.partnerName!),
                  if (versement.partnerPhone != null)
                    _buildClientInfoRowPDF('Tél', versement.partnerPhone!),
                  if (versement.partnerId != null)
                    _buildClientInfoRowPDF(
                        'Register No.', versement.partnerId!.toString()),
                ],
              ),
            ),

            // Section Commissionnaire
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'COMISSIONNAIRE',
                    style: PrintStyles.sectionTitleStyle(),
                  ),
                  pw.SizedBox(height: 10),
                  if (versement.commissionnaireName != null)
                    _buildClientInfoRowPDF(
                        'Nom', versement.commissionnaireName!),
                  if (versement.commissionnairePhone != null)
                    _buildClientInfoRowPDF(
                        'Tél', versement.commissionnairePhone!),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Ligne info style Market Finance : cellule libellé (fond vert) | cellule valeur (fond blanc), bordures.
  static pw.Widget _buildInfoRowPDFGrid(String label, String value) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: PrintStyles.tableBorderSide,
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 140,
            padding: pw.EdgeInsets.symmetric(
                vertical: PrintStyles.cellPaddingV,
                horizontal: PrintStyles.cellPaddingH),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
            ),
            child: pw.Text(
              label,
              style: PrintStyles.labelStyle(),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: pw.EdgeInsets.symmetric(
                  vertical: PrintStyles.cellPaddingV,
                  horizontal: PrintStyles.cellPaddingH),
              color: PdfColors.white,
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  left: PrintStyles.tableBorderSide,
                ),
              ),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                value,
                style: PrintStyles.cellTextStyle(
                    fontSize: PrintStyles.labelFontSize),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildClientInfoRowPDF(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              '$label :',
              style: PrintStyles.cellTextStyle(
                  fontSize: PrintStyles.labelFontSize),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: PrintStyles.cellTextStyle(
                  fontSize: PrintStyles.labelFontSize),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildArticlesSection(
      List<Achat> achats,
      Versement? versement,
      PrintLocalizations printLocalizations,
      NumberFormat currencyFormat,
      InvoiceOptions options,
      {required double sousTotal,
      required double montantTotal}) {
    final montantRestantDisplay =
        _montantRestantDisplay(versement, currencyFormat);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(printLocalizations.translate("pdf_articles_list_label"),
            style: PrintStyles.sectionTitleStyle()),
        pw.SizedBox(height: 6),
        // Tableau avec bordures style Market Finance (grille)
        pw.Container(
          decoration: pw.BoxDecoration(
            border: PrintStyles.tableBorder,
          ),
          child: pw.Column(
            children: [
              // En-tête du tableau (vert menthe)
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PrintStyles.tableHeaderBackground,
                ),
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  children: [
                    pw.Container(
                        width: 28,
                        child: pw.Text(
                            printLocalizations.translate('pdf_table_number'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                            printLocalizations.translate('pdf_product_name'),
                            style: PrintStyles.tableHeaderStyle(),
                            maxLines: PrintStyles.maxLinesLongText)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 80,
                        child: pw.Text(
                            printLocalizations.translate('pdf_reference'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center,
                            maxLines: PrintStyles.maxLinesLongText)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 70,
                        child: pw.Text(
                            printLocalizations
                                .translate('pdf_remaining_amount_label'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center,
                            maxLines: PrintStyles.maxLinesLongText)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 30,
                        child: pw.Text(
                            printLocalizations.translate('pdf_carton'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 50,
                        child: pw.Text(
                            printLocalizations
                                .translate('pdf_quantity_per_carton'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 50,
                        child: pw.Text(
                            printLocalizations.translate('pdf_total_quantity'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 40,
                        child: pw.Text(
                            printLocalizations
                                .translate('pdf_unit_price_label'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 50,
                        child: pw.Text(
                            printLocalizations.translate('pdf_amount'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                  ],
                ),
              ),
              // Corps du tableau (padding uniforme, texte avec retours à la ligne)
              ...() {
                final rows = <(Achat, Items)>[];
                for (final achat in achats) {
                  for (final item in (achat.items ?? [])) {
                    rows.add((achat, item));
                  }
                }
                return [
                  for (var idx = 0; idx < rows.length; idx++)
                    () {
                      final (achat, item) = rows[idx];
                      final rowNumber = idx + 1;
                      // Recalcul du prix de l'article : marge puis remise sur le prix après marge
                      final margin = item.id != null &&
                              options.selectiveItemMargins.containsKey(item.id)
                          ? options.selectiveItemMargins[item.id]
                          : null;
                      final discount = item.id != null &&
                              options.selectiveLineDiscounts
                                  .containsKey(item.id)
                          ? options.selectiveLineDiscounts[item.id]
                          : null;
                      final priceResult =
                          MarginCalculationService.getItemFinalPrice(
                        item: item,
                        margin: margin,
                        discount: discount,
                      );
                      final adjustedUnitPrice = priceResult.unitPrice;
                      final adjustedTotalPrice = priceResult.totalPrice;
                      final currentMargin = margin;

                      // Calculer les valeurs pour les colonnes
                      final carton = item.carton ?? 0;
                      final unitPerCarton =
                          (item.quantityPerCarton ?? 0).toDouble();
                      final totalQuantity = (item.quantity ?? 0).toDouble();
                      // Déterminer si le prix final a été modifié (Option A)
                      final isPriceModified = currentMargin != null &&
                          currentMargin.displayMode ==
                              MarginDisplayMode.modifyFinalPrice &&
                          currentMargin.finalPrice != null;

                      return pw.Container(
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          border: pw.Border(
                            bottom: PrintStyles.tableBorderSide,
                          ),
                        ),
                        padding: pw.EdgeInsets.symmetric(
                            vertical: PrintStyles.cellPaddingV,
                            horizontal: PrintStyles.cellPaddingH),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                                width: 28,
                                child: pw.Text(rowNumber.toString(),
                                    style: PrintStyles.cellTextStyle(),
                                    textAlign: pw.TextAlign.center)),
                            pw.SizedBox(width: 4),
                            pw.Expanded(
                                flex: 3,
                                child: pw.Text(item.description ?? '',
                                    style: PrintStyles.cellTextStyle(),
                                    maxLines: PrintStyles.maxLinesLongText)),
                            pw.SizedBox(width: 4),
                            pw.Container(
                                width: 80,
                                child: pw.Text(_achatReferenceDisplay(achat),
                                    style: PrintStyles.cellTextStyle(),
                                    textAlign: pw.TextAlign.center,
                                    maxLines: PrintStyles.maxLinesLongText)),
                            pw.SizedBox(width: 4),
                            pw.Container(
                                width: 70,
                                child: pw.Text(montantRestantDisplay,
                                    style: PrintStyles.cellTextStyle(),
                                    textAlign: pw.TextAlign.center,
                                    maxLines: PrintStyles.maxLinesLongText)),
                            pw.SizedBox(width: 4),
                            pw.Container(
                                width: 30,
                                child: pw.Text(carton.toString(),
                                    style: PrintStyles.cellTextStyle(),
                                    textAlign: pw.TextAlign.center)),
                            pw.SizedBox(width: 4),
                            pw.Container(
                                width: 50,
                                child: pw.Text(unitPerCarton.toStringAsFixed(2),
                                    style: PrintStyles.cellTextStyle(),
                                    textAlign: pw.TextAlign.center)),
                            pw.SizedBox(width: 4),
                            pw.Container(
                                width: 50,
                                child: pw.Text(totalQuantity.toStringAsFixed(2),
                                    style: PrintStyles.cellTextStyle(),
                                    textAlign: pw.TextAlign.center)),
                            pw.SizedBox(width: 4),
                            pw.Container(
                                width: 40,
                                child: pw.Text(
                                    currencyFormat.format(adjustedUnitPrice),
                                    style: PrintStyles.cellTextStyle(),
                                    textAlign: pw.TextAlign.center)),
                            pw.SizedBox(width: 4),
                            pw.Container(
                                width: 50,
                                child: pw.Text(
                                    currencyFormat.format(adjustedTotalPrice),
                                    style: pw.TextStyle(
                                      fontSize: PrintStyles.tableFontSize,
                                      fontWeight: isPriceModified
                                          ? pw.FontWeight.bold
                                          : pw.FontWeight.normal,
                                      color: isPriceModified
                                          ? PrintStyles.accentColor
                                          : PrintStyles.textColor,
                                    ),
                                    textAlign: pw.TextAlign.center)),
                          ],
                        ),
                      );
                    }(),
                ];
              }(),
              // Ligne Sous-total (vert menthe, style Market Finance)
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  color: PrintStyles.subtotalRowBackground,
                ),
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      printLocalizations.translate('pdf_subtotal_label'),
                      style: PrintStyles.labelStyle(),
                    ),
                    pw.Text(
                      currencyFormat.format(sousTotal),
                      style: PrintStyles.labelStyle(),
                    ),
                  ],
                ),
              ),
              // Ligne Total (vert menthe, style Market Finance)
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  color: PrintStyles.totalRowBackground,
                ),
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      printLocalizations.translate('pdf_total_final'),
                      style: pw.TextStyle(
                        fontSize: PrintStyles.labelFontSize,
                        fontWeight: pw.FontWeight.bold,
                        color: PrintStyles.accentColor,
                      ),
                    ),
                    pw.Text(
                      currencyFormat.format(montantTotal),
                      style: pw.TextStyle(
                        fontSize: PrintStyles.labelFontSize,
                        fontWeight: pw.FontWeight.bold,
                        color: PrintStyles.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
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
      PrintLocalizations printLocalizations,
      List<Achat> achats) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Remises par ligne (sélectives) : afficher les articles concernés
          if (options.enableSelectiveLineDiscounts &&
              options.selectiveLineDiscounts.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        printLocalizations
                            .translate('pdf_line_discounts_selective'),
                        style: PrintStyles.cellTextStyle(
                            fontSize: PrintStyles.labelFontSize),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        '-${currencyFormat.format(options.selectiveLineDiscounts.values.fold<double>(0.0, (sum, d) => sum + d.discountAmount))}',
                        style: pw.TextStyle(
                          fontSize: PrintStyles.labelFontSize,
                          color: PrintStyles.textColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  ...options.selectiveLineDiscounts.values.map((discount) {
                    Items? foundItem;
                    for (final achat in achats) {
                      final items = achat.items;
                      if (items == null) continue;
                      try {
                        foundItem = items.firstWhere(
                          (item) => item.id == discount.itemId,
                        );
                        break;
                      } catch (_) {}
                    }
                    final itemLabel =
                        foundItem?.description ?? 'Article ${discount.itemId}';
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          '$itemLabel - ${discount.type == DiscountType.percentage ? '${discount.value}%' : currencyFormat.format(discount.value)} :',
                          style: PrintStyles.cellTextStyle(
                              fontSize: PrintStyles.tableFontSize),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Text(
                          '-${currencyFormat.format(discount.discountAmount)}',
                          style: pw.TextStyle(
                            fontSize: PrintStyles.tableFontSize,
                            color: PrintStyles.textColor,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
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
                      fontSize: PrintStyles.labelFontSize,
                      color: PrintStyles.textColor,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    '-${currencyFormat.format(options.discountType == DiscountType.percentage ? (sousTotal * options.discountValue! / 100) : options.discountValue!)}',
                    style: pw.TextStyle(
                      fontSize: PrintStyles.labelFontSize,
                      color: PrintStyles.textColor,
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
                      fontSize: PrintStyles.labelFontSize,
                      color: PrintStyles.textColor,
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
                      fontSize: PrintStyles.labelFontSize,
                      color: PrintStyles.textColor,
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
                      fontSize: PrintStyles.labelFontSize,
                      color: PrintStyles.textColor,
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
                      fontSize: PrintStyles.labelFontSize,
                      color: PrintStyles.textColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildWithdrawalsSection(
      List<CashWithdrawal> retraits,
      PrintLocalizations printLocalizations,
      NumberFormat currencyFormat,
      DateFormat dateFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(printLocalizations.translate("pdf_cash_withdrawals_list"),
            style: PrintStyles.sectionTitleStyle()),
        pw.SizedBox(height: 8),
        // En-tête du tableau (style Market Finance)
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PrintStyles.tableHeaderBackground,
          ),
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: pw.Row(
            children: [
              pw.Container(
                  width: 100,
                  child: pw.Text(
                      printLocalizations.translate('pdf_withdrawal_date'),
                      style: PrintStyles.tableHeaderStyle(),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 100,
                  child: pw.Text(
                      printLocalizations.translate('pdf_withdrawal_amount'),
                      style: PrintStyles.tableHeaderStyle(),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Expanded(
                  child: pw.Text(
                      printLocalizations.translate('pdf_withdrawal_reason'),
                      style: PrintStyles.tableHeaderStyle(),
                      textAlign: pw.TextAlign.left)),
            ],
          ),
        ),
        // Corps du tableau avec le même style que les produits
        ...retraits.map((r) => pw.Container(
              color: PdfColors.white,
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: pw.Row(
                children: [
                  pw.Container(
                      width: 100,
                      child: pw.Text(
                        r.dateRetrait != null
                            ? dateFormat.format(r.dateRetrait!)
                            : printLocalizations.translate('pdf_unknown_date'),
                        style: PrintStyles.smallStyle(),
                        textAlign: pw.TextAlign.center,
                      )),
                  pw.SizedBox(width: 3),
                  pw.Container(
                      width: 100,
                      child: pw.Text(
                        currencyFormat.format(r.montant),
                        style: PrintStyles.smallStyle(),
                        textAlign: pw.TextAlign.center,
                      )),
                  pw.SizedBox(width: 3),
                  pw.Expanded(
                      child: pw.Text(
                    r.note ?? '',
                    style: PrintStyles.smallStyle(),
                    maxLines: 2,
                    textAlign: pw.TextAlign.left,
                  )),
                ],
              ),
            )),
      ],
    );
  }

  static pw.Widget _buildWithdrawalsTotal(double totalRetraits,
      NumberFormat currencyFormat, PrintLocalizations printLocalizations) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
            '${printLocalizations.translate('pdf_total_withdrawals')} : ${currencyFormat.format(totalRetraits)}',
            style: PrintStyles.labelStyle()),
      ],
    );
  }

  static pw.Widget _buildAchatHeader(
      Uint8List logoBytes,
      Achat achat,
      DateFormat dateFormat,
      PrintLocalizations printLocalizations,
      bool isProforma) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // En-tête avec design de carte de visite
        pw.Container(
          decoration: pw.BoxDecoration(
            border: PrintStyles.tableBorder,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                        PdfColors.white, // Bleu très clair
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
                          color: PrintStyles.accentColor,
                          letterSpacing: 1.2,
                          fontStyle: pw.FontStyle.italic,
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
                        ),
                      ),
                      pw.Text(
                        '中国 浙江省义乌市赵宅3区10栋1单元102',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.red700,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),

                      // Ligne séparatrice (couleur unifiée)
                      pw.SizedBox(height: 10),
                      pw.Container(
                        height: PrintStyles.tableBorderWidth,
                        color: PrintStyles.tableBorderColor,
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
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  '0086 18678859834',
                                  style: const pw.TextStyle(fontSize: 8),
                                ),
                                pw.Text(
                                  '0086 13503032311',
                                  style: const pw.TextStyle(fontSize: 8),
                                ),
                                pw.Text(
                                  '0086 (579)85568522',
                                  style: const pw.TextStyle(fontSize: 8),
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
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  'bbd@bbdcompany.com',
                                  style: const pw.TextStyle(fontSize: 8),
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

              // Ligne verticale séparatrice (couleur unifiée)
              pw.Container(
                width: PrintStyles.tableBorderWidth,
                color: PrintStyles.tableBorderColor,
              ),

              // Section droite avec logo sur fond blanc
              pw.Padding(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  width: 70,
                  height: 70,
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Titre de la facture (style Market Finance)
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
          ),
          child: pw.Text(
            isProforma
                ? printLocalizations.translate('pdf_proforma')
                : 'Market Finance Invoice',
            style: PrintStyles.mainTitleStyle(),
          ),
        ),
        pw.SizedBox(height: 0),

        // Tableau Référence et Date (style Market Finance, en-tête vert)
        pw.Container(
          decoration: pw.BoxDecoration(
            border: PrintStyles.tableBorder,
          ),
          child: pw.Column(
            children: [
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PrintStyles.tableHeaderBackground,
                ),
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        printLocalizations.translate('pdf_reference_label'),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: PrintStyles.tableFontSize,
                          color: PrintStyles.accentColor,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        printLocalizations.translate('pdf_date_label'),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: PrintStyles.tableFontSize,
                          color: PrintStyles.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                color: PdfColors.white,
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'ACH-${achat.id}',
                        style: PrintStyles.cellTextStyle(),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        dateFormat.format(achat.createdAt ?? DateTime.now()),
                        style: PrintStyles.cellTextStyle(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _achatReferenceDisplay(Achat achat) {
    if (achat.referenceVersement != null &&
        achat.referenceVersement!.isNotEmpty) {
      return achat.referenceVersement!;
    }
    return achat.isDebt == true ? 'Dette' : '-';
  }

  static String _montantRestantDisplay(
      Versement? versement, NumberFormat currencyFormat) {
    if (versement != null && versement.montantRestant != null) {
      return currencyFormat.format(versement.montantRestant!);
    }
    return '-';
  }

  /// Section "Informations du versement" en tableau (après le tableau des items).
  static pw.Widget? _buildVersementInfoSection(
    Versement? versement,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
    PrintLocalizations printLocalizations,
  ) {
    if (versement == null) return null;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.SizedBox(height: 12),
        pw.Text(
          printLocalizations.translate('pdf_versement_info_section'),
          style: PrintStyles.sectionTitleStyle(),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: PrintStyles.tableBorder,
          ),
          child: pw.Column(
            children: [
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PrintStyles.tableHeaderBackground,
                ),
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        printLocalizations.translate('pdf_amount_paid_label'),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: PrintStyles.tableFontSize,
                          color: PrintStyles.accentColor,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        printLocalizations
                            .translate('pdf_remaining_amount_label'),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: PrintStyles.tableFontSize,
                          color: PrintStyles.accentColor,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        printLocalizations.translate('pdf_versement_date'),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: PrintStyles.tableFontSize,
                          color: PrintStyles.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                color: PdfColors.white,
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        currencyFormat.format(versement.montantVerser ?? 0),
                        style: PrintStyles.cellTextStyle(),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        currencyFormat.format(versement.montantRestant ?? 0),
                        style: PrintStyles.cellTextStyle(),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        versement.createdAt != null
                            ? dateFormat.format(versement.createdAt!)
                            : '-',
                        style: PrintStyles.cellTextStyle(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildAchatArticlesSection(
      List<Items>? filteredItems,
      PrintLocalizations printLocalizations,
      bool includeSupplierInfo,
      bool isProforma,
      NumberFormat currencyFormat,
      InvoiceOptions options,
      Achat achat,
      Versement? versement,
      {required double sousTotal,
      required double montantTotal}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(printLocalizations.translate("pdf_articles_list_label"),
            style: PrintStyles.sectionTitleStyle()),
        pw.SizedBox(height: 6),
        // Tableau avec bordures style Market Finance (grille)
        pw.Container(
          decoration: pw.BoxDecoration(
            border: PrintStyles.tableBorder,
          ),
          child: pw.Column(
            children: [
              // En-tête du tableau (vert menthe)
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PrintStyles.tableHeaderBackground,
                ),
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  children: [
                    pw.Container(
                        width: 28,
                        child: pw.Text(
                            printLocalizations.translate('pdf_table_number'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                            printLocalizations.translate('pdf_product_name'),
                            style: PrintStyles.tableHeaderStyle(),
                            maxLines: PrintStyles.maxLinesLongText)),
                    pw.SizedBox(width: 4),
                    if (includeSupplierInfo) ...[
                      pw.Container(
                          width: 60,
                          child: pw.Text(
                              printLocalizations.translate('pdf_supplier_name'),
                              style: PrintStyles.tableHeaderStyle(),
                              textAlign: pw.TextAlign.center,
                              maxLines: 2)),
                      pw.SizedBox(width: 3),
                      pw.Container(
                          width: 50,
                          child: pw.Text(
                              printLocalizations
                                  .translate('pdf_supplier_phone'),
                              style: PrintStyles.tableHeaderStyle(),
                              textAlign: pw.TextAlign.center,
                              maxLines: 2)),
                      pw.SizedBox(width: 3),
                    ],
                    pw.Container(
                        width: 30,
                        child: pw.Text(
                            printLocalizations.translate('pdf_carton'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 3),
                    pw.Container(
                        width: 50,
                        child: pw.Text(
                            printLocalizations
                                .translate('pdf_quantity_per_carton'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 3),
                    pw.Container(
                        width: 50,
                        child: pw.Text(
                            printLocalizations.translate('pdf_total_quantity'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 3),
                    pw.Container(
                        width: 40,
                        child: pw.Text(
                            printLocalizations
                                .translate('pdf_unit_price_label'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 3),
                    pw.Container(
                        width: 50,
                        child: pw.Text(
                            printLocalizations.translate('pdf_amount'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    if (isProforma) ...[
                      pw.SizedBox(width: 3),
                      pw.Container(
                          width: 60,
                          child: pw.Text(
                              printLocalizations.translate('pdf_status'),
                              style: PrintStyles.tableHeaderStyle(),
                              textAlign: pw.TextAlign.center)),
                    ],
                  ],
                ),
              ),
              ...() {
                final itemsToShow = (filteredItems ?? []).toList();
                return [
                  for (var idx = 0; idx < itemsToShow.length; idx++)
                    () {
                      final item = itemsToShow[idx];
                      final rowNumber = idx + 1;
                      // Recalcul du prix de l'article : marge puis remise sur le prix après marge
                      final margin = item.id != null &&
                              options.selectiveItemMargins.containsKey(item.id)
                          ? options.selectiveItemMargins[item.id]
                          : null;
                      final discount = item.id != null &&
                              options.selectiveLineDiscounts
                                  .containsKey(item.id)
                          ? options.selectiveLineDiscounts[item.id]
                          : null;
                      final priceResult =
                          MarginCalculationService.getItemFinalPrice(
                        item: item,
                        margin: margin,
                        discount: discount,
                      );
                      final adjustedUnitPrice = priceResult.unitPrice;
                      final adjustedTotalPrice = priceResult.totalPrice;
                      final currentMargin = margin;

                      // Calculer les valeurs pour les colonnes
                      final carton = item.carton ?? 0;
                      final unitPerCarton =
                          (item.quantityPerCarton ?? 0).toDouble();
                      final totalQuantity = (item.quantity ?? 0).toDouble();

                      // Déterminer si le prix final a été modifié (Option A)
                      final isPriceModified = currentMargin != null &&
                          currentMargin.displayMode ==
                              MarginDisplayMode.modifyFinalPrice &&
                          currentMargin.finalPrice != null;

                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Ligne principale de l'article (style Market Finance, bordure bas)
                          pw.Container(
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              border: pw.Border(
                                bottom: PrintStyles.tableBorderSide,
                              ),
                            ),
                            padding: pw.EdgeInsets.symmetric(
                                vertical: PrintStyles.cellPaddingV,
                                horizontal: PrintStyles.cellPaddingH),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                    width: 28,
                                    child: pw.Text(rowNumber.toString(),
                                        style: PrintStyles.cellTextStyle(),
                                        textAlign: pw.TextAlign.center)),
                                pw.SizedBox(width: 4),
                                pw.Expanded(
                                    flex: 3,
                                    child: pw.Text(item.description ?? '',
                                        style: PrintStyles.cellTextStyle(),
                                        maxLines:
                                            PrintStyles.maxLinesLongText)),
                                pw.SizedBox(width: 4),
                                if (includeSupplierInfo) ...[
                                  pw.Container(
                                      width: 60,
                                      child: pw.Text(item.supplierName ?? '-',
                                          style: PrintStyles.cellTextStyle(),
                                          textAlign: pw.TextAlign.center,
                                          maxLines:
                                              PrintStyles.maxLinesLongText)),
                                  pw.SizedBox(width: 4),
                                  pw.Container(
                                      width: 50,
                                      child: pw.Text(item.supplierPhone ?? '-',
                                          style: PrintStyles.cellTextStyle(),
                                          textAlign: pw.TextAlign.center,
                                          maxLines:
                                              PrintStyles.maxLinesLongText)),
                                  pw.SizedBox(width: 4),
                                ],
                                pw.Container(
                                    width: 30,
                                    child: pw.Text(carton.toString(),
                                        style: PrintStyles.cellTextStyle(),
                                        textAlign: pw.TextAlign.center)),
                                pw.SizedBox(width: 4),
                                pw.Container(
                                    width: 50,
                                    child: pw.Text(
                                        unitPerCarton.toStringAsFixed(2),
                                        style: PrintStyles.cellTextStyle(),
                                        textAlign: pw.TextAlign.center)),
                                pw.SizedBox(width: 4),
                                pw.Container(
                                    width: 50,
                                    child: pw.Text(
                                        totalQuantity.toStringAsFixed(2),
                                        style: PrintStyles.cellTextStyle(),
                                        textAlign: pw.TextAlign.center)),
                                pw.SizedBox(width: 4),
                                pw.Container(
                                    width: 40,
                                    child: pw.Text(
                                        currencyFormat
                                            .format(adjustedUnitPrice),
                                        style: PrintStyles.cellTextStyle(),
                                        textAlign: pw.TextAlign.center)),
                                pw.SizedBox(width: 4),
                                pw.Container(
                                    width: 50,
                                    child: pw.Text(
                                        currencyFormat
                                            .format(adjustedTotalPrice),
                                        style: pw.TextStyle(
                                          fontSize: PrintStyles.tableFontSize,
                                          fontWeight: isPriceModified
                                              ? pw.FontWeight.bold
                                              : pw.FontWeight.normal,
                                          color: isPriceModified
                                              ? PrintStyles.accentColor
                                              : PrintStyles.textColor,
                                        ),
                                        textAlign: pw.TextAlign.center)),
                                if (isProforma) ...[
                                  pw.SizedBox(width: 4),
                                  pw.Container(
                                      width: 60,
                                      child: pw.Text(
                                          printLocalizations
                                              .translateStatus(item.status),
                                          style: PrintStyles.cellTextStyle(),
                                          textAlign: pw.TextAlign.center)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    }(),
                ];
              }(),
              // Ligne Sous-total (vert menthe, style Market Finance)
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  color: PrintStyles.subtotalRowBackground,
                ),
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      printLocalizations.translate('pdf_subtotal_label'),
                      style: PrintStyles.labelStyle(),
                    ),
                    pw.Text(
                      currencyFormat.format(sousTotal),
                      style: PrintStyles.labelStyle(),
                    ),
                  ],
                ),
              ),
              // Ligne Total (vert menthe, style Market Finance)
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  color: PrintStyles.totalRowBackground,
                ),
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      printLocalizations.translate('pdf_total_final'),
                      style: pw.TextStyle(
                        fontSize: PrintStyles.labelFontSize,
                        fontWeight: pw.FontWeight.bold,
                        color: PrintStyles.accentColor,
                      ),
                    ),
                    pw.Text(
                      currencyFormat.format(montantTotal),
                      style: pw.TextStyle(
                        fontSize: PrintStyles.labelFontSize,
                        fontWeight: pw.FontWeight.bold,
                        color: PrintStyles.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
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
      PrintLocalizations printLocalizations,
      bool isProforma,
      List<Items>? filteredItems,
      List<Achat> achats) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Remises par ligne (sélectives) : afficher les articles concernés
          if (options.enableSelectiveLineDiscounts &&
              options.selectiveLineDiscounts.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        printLocalizations
                            .translate('pdf_line_discounts_selective'),
                        style: PrintStyles.cellTextStyle(
                            fontSize: PrintStyles.labelFontSize),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        '-${currencyFormat.format(options.selectiveLineDiscounts.values.fold<double>(0.0, (sum, d) => sum + d.discountAmount))}',
                        style: pw.TextStyle(
                          fontSize: PrintStyles.labelFontSize,
                          color: PrintStyles.textColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  ...options.selectiveLineDiscounts.values.map((discount) {
                    Items? foundItem;
                    if (filteredItems != null && filteredItems.isNotEmpty) {
                      try {
                        foundItem = filteredItems.firstWhere(
                          (item) => item.id == discount.itemId,
                        );
                      } catch (_) {}
                    }
                    if (foundItem == null) {
                      for (final achat in achats) {
                        final items = achat.items;
                        if (items == null) continue;
                        try {
                          foundItem = items.firstWhere(
                            (item) => item.id == discount.itemId,
                          );
                          break;
                        } catch (_) {}
                      }
                    }
                    final itemLabel =
                        foundItem?.description ?? 'Article ${discount.itemId}';
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          '$itemLabel - ${discount.type == DiscountType.percentage ? '${discount.value}%' : currencyFormat.format(discount.value)} :',
                          style: PrintStyles.cellTextStyle(
                              fontSize: PrintStyles.tableFontSize),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Text(
                          '-${currencyFormat.format(discount.discountAmount)}',
                          style: pw.TextStyle(
                            fontSize: PrintStyles.tableFontSize,
                            color: PrintStyles.textColor,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
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
                      fontSize: PrintStyles.labelFontSize,
                      color: PrintStyles.textColor,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    '-${currencyFormat.format(options.discountType == DiscountType.percentage ? (sousTotal * options.discountValue! / 100) : options.discountValue!)}',
                    style: pw.TextStyle(
                      fontSize: PrintStyles.labelFontSize,
                      color: PrintStyles.textColor,
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
                      fontSize: PrintStyles.labelFontSize,
                      color: PrintStyles.textColor,
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
                      fontSize: PrintStyles.labelFontSize,
                      color: PrintStyles.textColor,
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
                      fontSize: PrintStyles.labelFontSize,
                      color: PrintStyles.textColor,
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
                      fontSize: PrintStyles.labelFontSize,
                      color: PrintStyles.textColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isProforma) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              printLocalizations.translate('pdf_estimated_amount'),
              style: pw.TextStyle(
                fontSize: PrintStyles.labelFontSize,
                color: PrintStyles.textColor,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
