import 'dart:typed_data';
import 'package:bbd_limited/core/enums/status.dart';
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

    // Calcul du sous-total (avec marges sélectives si activées)
    final options = invoiceOptions ?? const InvoiceOptions();
    double sousTotal = 0;
    for (final achat in achats) {
      for (final item in (achat.items ?? [])) {
        // Si marges sélectives activées, ne considérer que les articles sélectionnés
        if (options.enableSelectiveItemMargins &&
            options.selectiveItemMargins.isNotEmpty) {
          if (item.id == null ||
              !options.selectiveItemMargins.containsKey(item.id)) {
            continue; // Ignorer les articles non sélectionnés
          }
        }

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
    );
    double montantTotal = calculationResult.finalTotal;

    // Calcul du total des retraits
    double totalRetraits = retraits.fold(0.0, (sum, r) => sum + r.montant);

    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.zero,
        build: (ctx) => [
          pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(logoBytes, versement, dateFormat,
                    printLocalizations, currencyFormat),
                pw.SizedBox(height: 24),
                _buildArticlesSection(
                    achats, printLocalizations, currencyFormat, options),
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
      // Si marges sélectives activées, ne considérer que les articles sélectionnés
      if (options.enableSelectiveItemMargins &&
          options.selectiveItemMargins.isNotEmpty) {
        if (item.id == null ||
            !options.selectiveItemMargins.containsKey(item.id)) {
          continue; // Ignorer les articles non sélectionnés
        }
      }

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
    );
    double montantTotal = calculationResult.finalTotal;

    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.zero,
        build: (ctx) => [
          pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildAchatHeader(logoBytes, achat, dateFormat,
                    printLocalizations, isProforma),
                pw.SizedBox(height: 24),
                _buildAchatArticlesSection(filteredItems, printLocalizations,
                    includeSupplierInfo, isProforma, currencyFormat, options),
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

  // Méthodes privées pour la construction des sections
  // Nouveau design aligné sur l'image fournie
  static pw.Widget _buildHeader(
      Uint8List logoBytes,
      Versement versement,
      DateFormat dateFormat,
      PrintLocalizations printLocalizations,
      NumberFormat currencyFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // En-tête avec design de carte de visite
        pw.Container(
          decoration: pw.BoxDecoration(
            border:
                pw.Border.all(color: PdfColor.fromHex('#1A1E49'), width: 1.5),
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
                    borderRadius: const pw.BorderRadius.only(
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

        // Titre de la facture (Payment Invoice pour les versements)
        pw.Text(
          'Payment Invoice',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1A1E49'),
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 16),

        // Informations de la facture dans un tableau
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            children: [
              _buildInfoRowPDF('Invoice No.', versement.reference ?? ''),
              _buildInfoRowPDF('Invoice Date',
                  dateFormat.format(versement.createdAt ?? DateTime.now())),
              _buildInfoRowPDF('Currency', versement.deviseCode ?? 'CNY'),
              _buildInfoRowPDF('Exchange Rate', '1.00'),
              if (versement.montantVerser != null)
                _buildInfoRowPDF('Amount Paid',
                    currencyFormat.format(versement.montantVerser!)),
              if (versement.montantRestant != null)
                _buildInfoRowPDF('Remaining Amount',
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
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1A1E49'),
                    ),
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
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1A1E49'),
                    ),
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

  static pw.Widget _buildInfoRowPDF(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
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
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildArticlesSection(
      List<Achat> achats,
      PrintLocalizations printLocalizations,
      NumberFormat currencyFormat,
      InvoiceOptions options) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(printLocalizations.translate("pdf_articles_list_label"),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1E49'),
              font: printLocalizations.language.code == 'zh'
                  ? pw.Font.courier()
                  : pw.Font.helvetica(),
              fontFallback: [pw.Font.times(), pw.Font.courier()],
            )),
        pw.SizedBox(height: 8),
        // En-tête du tableau avec toutes les colonnes du design
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
                  width: 40,
                  child: pw.Text('Total CBM',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 40,
                  child: pw.Text('Total Weight',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 30,
                  child: pw.Text('Carton',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 50,
                  child: pw.Text('Unit / Carton',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 50,
                  child: pw.Text('Total Quantity',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 40,
                  child: pw.Text('Price',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 50,
                  child: pw.Text('Amount',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
            ],
          ),
        ),
        // Corps du tableau
        for (final achat in achats)
          for (final item in (achat.items ?? []))
            () {
              // Si marges sélectives activées, ne montrer que les articles sélectionnés
              if (options.enableSelectiveItemMargins &&
                  options.selectiveItemMargins.isNotEmpty) {
                if (item.id == null ||
                    !options.selectiveItemMargins.containsKey(item.id)) {
                  return pw.SizedBox.shrink();
                }
              }

              // Calculer le prix ajusté si marge sélective activée
              double adjustedUnitPrice = item.unitPrice ?? 0;
              double adjustedTotalPrice = item.totalPrice ?? 0;

              if (options.enableSelectiveItemMargins &&
                  item.id != null &&
                  options.selectiveItemMargins.containsKey(item.id)) {
                final margin = options.selectiveItemMargins[item.id]!;
                adjustedUnitPrice = margin.adjustedUnitPrice;
                adjustedTotalPrice = margin.adjustedTotalPrice;
              }

              // Calculer les valeurs pour les colonnes
              final carton = item.carton ?? 0;
              final unitPerCarton = (item.quantityPerCarton ?? 0).toDouble();
              final totalQuantity = (item.quantity ?? 0).toDouble();
              final totalCBM =
                  0.0; // Par défaut, peut être calculé si disponible
              final totalWeight =
                  0.0; // Par défaut, peut être calculé si disponible

              return pw.Container(
                color: PdfColors.white,
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                        flex: 3,
                        child: pw.Text(item.description ?? '',
                            style: const pw.TextStyle(fontSize: 8),
                            maxLines: 2)),
                    pw.SizedBox(width: 3),
                    pw.Container(
                        width: 40,
                        child: pw.Text(totalCBM.toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 3),
                    pw.Container(
                        width: 40,
                        child: pw.Text(totalWeight.toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 3),
                    pw.Container(
                        width: 30,
                        child: pw.Text(carton.toString(),
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 3),
                    pw.Container(
                        width: 50,
                        child: pw.Text(unitPerCarton.toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 3),
                    pw.Container(
                        width: 50,
                        child: pw.Text(totalQuantity.toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 3),
                    pw.Container(
                        width: 40,
                        child: pw.Text(currencyFormat.format(adjustedUnitPrice),
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 3),
                    pw.Container(
                        width: 50,
                        child: pw.Text(
                            currencyFormat.format(adjustedTotalPrice),
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center)),
                  ],
                ),
              );
            }(),
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
          // Sous-total
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  printLocalizations.translate('pdf_subtotal_label'),
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
          // Marge par ligne globale (seulement si aucune marge sélective n'est activée)
          if (options.enableLineMargin &&
              options.lineMarginValue != null &&
              !options.enableSelectiveItemMargins) ...[
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

          // Remise par ligne
          if (options.enableLineDiscount &&
              options.lineDiscountValue != null) ...[
            pw.SizedBox(height: 8),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    options.lineDiscountType == DiscountType.percentage
                        ? 'Remise par ligne ({value}%)'.replaceAll(
                            '{value}', '${options.lineDiscountValue}')
                        : 'Remise par ligne (${options.lineDiscountValue} ${currencyFormat.currencySymbol})',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    '-${currencyFormat.format(options.lineDiscountType == DiscountType.percentage ? (() {
                        // Calculer le total après la marge par ligne
                        double totalAfterLineMargin = sousTotal;
                        if (options.enableLineMargin &&
                            options.lineMarginValue != null &&
                            !options.enableSelectiveItemMargins) {
                          if (options.lineMarginType == MarginType.percentage) {
                            totalAfterLineMargin +=
                                (sousTotal * options.lineMarginValue! / 100);
                          } else {
                            totalAfterLineMargin += options.lineMarginValue!;
                          }
                        }
                        return totalAfterLineMargin *
                            options.lineDiscountValue! /
                            100;
                      })() : options.lineDiscountValue!)}',
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
                        ? printLocalizations
                            .translate('pdf_discount_percentage')
                            .replaceAll('{value}', '${options.discountValue}')
                        : printLocalizations.translate('pdf_discount_fixed'),
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
                        ? printLocalizations
                            .translate('pdf_storage_fees_percentage')
                            .replaceAll(
                                '{value}', '${options.storageFeeAmount}')
                        : printLocalizations
                            .translate('pdf_storage_fees_fixed'),
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
                        ? printLocalizations
                            .translate('pdf_global_margin_percentage')
                            .replaceAll(
                                '{value}', '${options.globalMarginValue}')
                        : printLocalizations
                            .translate('pdf_global_margin_fixed')
                            .replaceAll(
                                '{value}', '${options.globalMarginValue}'),
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
      PrintLocalizations printLocalizations,
      NumberFormat currencyFormat,
      DateFormat dateFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(printLocalizations.translate("pdf_cash_withdrawals_list"),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1E49'),
              font: printLocalizations.language.code == 'zh'
                  ? pw.Font.courier()
                  : pw.Font.helvetica(),
              fontFallback: [pw.Font.times(), pw.Font.courier()],
            )),
        pw.SizedBox(height: 8),
        // En-tête du tableau avec le même style que les produits
        pw.Container(
          color: PdfColor.fromHex('#E3F2FD'), // Bleu clair comme dans l'image
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: pw.Row(
            children: [
              pw.Container(
                  width: 100,
                  child: pw.Text(
                      printLocalizations.translate('pdf_withdrawal_date'),
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 100,
                  child: pw.Text(
                      printLocalizations.translate('pdf_withdrawal_amount'),
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Expanded(
                  child: pw.Text(
                      printLocalizations.translate('pdf_withdrawal_reason'),
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
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
                        style: const pw.TextStyle(fontSize: 8),
                        textAlign: pw.TextAlign.center,
                      )),
                  pw.SizedBox(width: 3),
                  pw.Container(
                      width: 100,
                      child: pw.Text(
                        currencyFormat.format(r.montant),
                        style: const pw.TextStyle(fontSize: 8),
                        textAlign: pw.TextAlign.center,
                      )),
                  pw.SizedBox(width: 3),
                  pw.Expanded(
                      child: pw.Text(
                    r.note ?? '',
                    style: const pw.TextStyle(fontSize: 8),
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
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1E49'),
              font: printLocalizations.language.code == 'zh'
                  ? pw.Font.courier()
                  : pw.Font.helvetica(),
              fontFallback: [pw.Font.times(), pw.Font.courier()],
            )),
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
            border:
                pw.Border.all(color: PdfColor.fromHex('#1A1E49'), width: 1.5),
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
                          color: PdfColor.fromHex('#1A1E49'),
                          letterSpacing: 1.2,
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

        // Titre de la facture (Market Finance Invoice pour les achats)
        pw.Text(
          isProforma
              ? printLocalizations.translate('pdf_proforma')
              : 'Market Finance Invoice',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1A1E49'),
            letterSpacing: 1.2,
            font: printLocalizations.language.code == 'zh'
                ? pw.Font.courier()
                : pw.Font.helvetica(),
            fontFallback: [pw.Font.times(), pw.Font.courier()],
          ),
        ),
        pw.SizedBox(height: 16),

        // Informations de la facture
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            children: [
              _buildInfoRowPDF(
                  printLocalizations.translate('pdf_reference_label'),
                  'ACH-${achat.id}'),
              _buildInfoRowPDF(printLocalizations.translate('pdf_date_label'),
                  dateFormat.format(achat.createdAt ?? DateTime.now())),
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
      InvoiceOptions options) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(printLocalizations.translate("pdf_articles_list_label"),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1E49'),
              font: printLocalizations.language.code == 'zh'
                  ? pw.Font.courier()
                  : pw.Font.helvetica(),
              fontFallback: [pw.Font.times(), pw.Font.courier()],
            )),
        pw.SizedBox(height: 8),
        // En-tête du tableau avec toutes les colonnes du design
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
              if (includeSupplierInfo) ...[
                pw.Container(
                    width: 60,
                    child: pw.Text('Supplier Name',
                        style: pw.TextStyle(
                            color: PdfColor.fromHex('#1A1E49'),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8),
                        textAlign: pw.TextAlign.center,
                        maxLines: 2)),
                pw.SizedBox(width: 3),
                pw.Container(
                    width: 50,
                    child: pw.Text('Supplier Phone',
                        style: pw.TextStyle(
                            color: PdfColor.fromHex('#1A1E49'),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8),
                        textAlign: pw.TextAlign.center,
                        maxLines: 2)),
                pw.SizedBox(width: 3),
              ],
              pw.Container(
                  width: 40,
                  child: pw.Text('Total CBM',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 40,
                  child: pw.Text('Total Weight',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 30,
                  child: pw.Text('Carton',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 50,
                  child: pw.Text('Unit / Carton',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 50,
                  child: pw.Text('Total Quantity',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 40,
                  child: pw.Text('Price',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 50,
                  child: pw.Text('Amount',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center)),
              if (isProforma) ...[
                pw.SizedBox(width: 3),
                pw.Container(
                    width: 60,
                    child: pw.Text(printLocalizations.translate('pdf_status'),
                        style: pw.TextStyle(
                            color: PdfColor.fromHex('#1A1E49'),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8),
                        textAlign: pw.TextAlign.center)),
              ],
            ],
          ),
        ),
        for (final item in (filteredItems ?? []))
          () {
            // Si marges sélectives activées, ne montrer que les articles sélectionnés
            if (options.enableSelectiveItemMargins &&
                options.selectiveItemMargins.isNotEmpty) {
              if (item.id == null ||
                  !options.selectiveItemMargins.containsKey(item.id)) {
                return pw.SizedBox.shrink();
              }
            }

            // Calculer le prix ajusté si marge sélective activée
            double adjustedUnitPrice = item.unitPrice ?? 0;
            double adjustedTotalPrice = item.totalPrice ?? 0;

            if (options.enableSelectiveItemMargins &&
                item.id != null &&
                options.selectiveItemMargins.containsKey(item.id)) {
              final margin = options.selectiveItemMargins[item.id]!;
              adjustedUnitPrice = margin.adjustedUnitPrice;
              adjustedTotalPrice = margin.adjustedTotalPrice;
            }

            // Calculer les valeurs pour les colonnes
            final carton = item.carton ?? 0;
            final unitPerCarton = (item.quantityPerCarton ?? 0).toDouble();
            final totalQuantity = (item.quantity ?? 0).toDouble();
            final totalCBM = 0.0; // Par défaut, peut être calculé si disponible
            final totalWeight =
                0.0; // Par défaut, peut être calculé si disponible

            return pw.Container(
              color: PdfColors.white,
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: pw.Row(
                children: [
                  pw.Expanded(
                      flex: 3,
                      child: pw.Text(item.description ?? '',
                          style: const pw.TextStyle(fontSize: 8), maxLines: 2)),
                  pw.SizedBox(width: 3),
                  if (includeSupplierInfo) ...[
                    pw.Container(
                        width: 60,
                        child: pw.Text(item.supplierName ?? '-',
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center,
                            maxLines: 2)),
                    pw.SizedBox(width: 3),
                    pw.Container(
                        width: 50,
                        child: pw.Text(item.supplierPhone ?? '-',
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center,
                            maxLines: 2)),
                    pw.SizedBox(width: 3),
                  ],
                  pw.Container(
                      width: 40,
                      child: pw.Text(totalCBM.toStringAsFixed(2),
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center)),
                  pw.SizedBox(width: 3),
                  pw.Container(
                      width: 40,
                      child: pw.Text(totalWeight.toStringAsFixed(2),
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center)),
                  pw.SizedBox(width: 3),
                  pw.Container(
                      width: 30,
                      child: pw.Text(carton.toString(),
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center)),
                  pw.SizedBox(width: 3),
                  pw.Container(
                      width: 50,
                      child: pw.Text(unitPerCarton.toStringAsFixed(2),
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center)),
                  pw.SizedBox(width: 3),
                  pw.Container(
                      width: 50,
                      child: pw.Text(totalQuantity.toStringAsFixed(2),
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center)),
                  pw.SizedBox(width: 3),
                  pw.Container(
                      width: 40,
                      child: pw.Text(currencyFormat.format(adjustedUnitPrice),
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center)),
                  pw.SizedBox(width: 3),
                  pw.Container(
                      width: 50,
                      child: pw.Text(currencyFormat.format(adjustedTotalPrice),
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center)),
                  if (isProforma) ...[
                    pw.SizedBox(width: 3),
                    pw.Container(
                        width: 60,
                        child: pw.Text(
                            printLocalizations.translateStatus(item.status),
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center)),
                  ],
                ],
              ),
            );
          }(),
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
          // Sous-total
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  printLocalizations.translate('pdf_subtotal_label'),
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
          // Marge par ligne globale (seulement si aucune marge sélective n'est activée)
          if (options.enableLineMargin &&
              options.lineMarginValue != null &&
              !options.enableSelectiveItemMargins) ...[
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

          // Remise par ligne
          if (options.enableLineDiscount &&
              options.lineDiscountValue != null) ...[
            pw.SizedBox(height: 8),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    options.lineDiscountType == DiscountType.percentage
                        ? 'Remise par ligne ({value}%)'.replaceAll(
                            '{value}', '${options.lineDiscountValue}')
                        : 'Remise par ligne (${options.lineDiscountValue} ${currencyFormat.currencySymbol})',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    '-${currencyFormat.format(options.lineDiscountType == DiscountType.percentage ? (() {
                        // Calculer le total après la marge par ligne
                        double totalAfterLineMargin = sousTotal;
                        if (options.enableLineMargin &&
                            options.lineMarginValue != null &&
                            !options.enableSelectiveItemMargins) {
                          if (options.lineMarginType == MarginType.percentage) {
                            totalAfterLineMargin +=
                                (sousTotal * options.lineMarginValue! / 100);
                          } else {
                            totalAfterLineMargin += options.lineMarginValue!;
                          }
                        }
                        return totalAfterLineMargin *
                            options.lineDiscountValue! /
                            100;
                      })() : options.lineDiscountValue!)}',
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
                        ? printLocalizations
                            .translate('pdf_discount_percentage')
                            .replaceAll('{value}', '${options.discountValue}')
                        : printLocalizations.translate('pdf_discount_fixed'),
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
                        ? printLocalizations
                            .translate('pdf_storage_fees_percentage')
                            .replaceAll(
                                '{value}', '${options.storageFeeAmount}')
                        : printLocalizations
                            .translate('pdf_storage_fees_fixed'),
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
                        ? printLocalizations
                            .translate('pdf_global_margin_percentage')
                            .replaceAll(
                                '{value}', '${options.globalMarginValue}')
                        : printLocalizations
                            .translate('pdf_global_margin_fixed')
                            .replaceAll(
                                '{value}', '${options.globalMarginValue}'),
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

          // Afficher les marges sélectives sur articles si activées
          if (options.enableSelectiveItemMargins &&
              options.selectiveItemMargins.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: options.selectiveItemMargins.values.map((margin) {
                  // Chercher l'item dans filteredItems d'abord, sinon dans achats
                  Items? foundItem;
                  if (filteredItems != null && filteredItems.isNotEmpty) {
                    try {
                      foundItem = filteredItems.firstWhere(
                        (item) => item.id == margin.itemId,
                      );
                    } catch (e) {
                      // Item not found in filteredItems, try achats
                    }
                  }
                  if (foundItem == null) {
                    for (final achat in achats) {
                      final items = achat.items;
                      if (items != null && items.isNotEmpty) {
                        try {
                          foundItem = items.firstWhere(
                            (item) => item.id == margin.itemId,
                          );
                          break;
                        } catch (e) {
                          // Item not found, continue
                        }
                      }
                    }
                  }
                  final item = foundItem;
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        '${item?.description ?? ''} - ${margin.type == MarginType.percentage ? '${margin.value}%' : currencyFormat.format(margin.value)} :',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        currencyFormat.format(margin.marginAmount),
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],

          // Afficher les marges sélectives sur frais si activées
          if (options.enableSelectiveFeeMargins &&
              options.selectiveFeeMargins.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: options.selectiveFeeMargins.values.map((margin) {
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        '${margin.feeName} - ${margin.type == MarginType.percentage ? '${margin.value}%' : currencyFormat.format(margin.value)} :',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        currencyFormat.format(margin.marginAmount),
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],

          pw.SizedBox(height: 16),

          // Total final
          pw.Text(
            '${printLocalizations.translate('pdf_total_final')} : ${currencyFormat.format(montantTotal)}',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A1E49'),
            ),
          ),

          if (isProforma) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              printLocalizations.translate('pdf_estimated_amount'),
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
