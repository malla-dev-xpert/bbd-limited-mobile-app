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
import 'package:bbd_limited/models/selective_margin.dart';
import 'package:bbd_limited/models/container.dart';

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
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(logoBytes, versement, dateFormat,
                    printLocalizations, currencyFormat),
                pw.SizedBox(height: 24),
                _buildArticlesSection(
                    achats, versement, printLocalizations, currencyFormat, options),
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
      selectiveLineDiscounts: options.selectiveLineDiscounts,
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
                if (containers != null && containers.isNotEmpty) ...[
                  _buildContainerFeesSection(
                      containers, printLocalizations, currencyFormat),
                  pw.SizedBox(height: 24),
                ],
                _buildAchatArticlesSection(filteredItems, printLocalizations,
                    includeSupplierInfo, isProforma, currencyFormat, options,
                    achat, versement),
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
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1A1E49'),
          ),
        ),
        pw.SizedBox(height: 8),
        ...containers.map((container) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Conteneur: ${container.reference ?? 'N/A'}",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
                pw.Divider(color: PdfColors.grey300),
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
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.Text(
            "${format.format(amount)} ${currencyCode ?? 'CNY'}",
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
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
      Versement? versement,
      PrintLocalizations printLocalizations,
      NumberFormat currencyFormat,
      InvoiceOptions options) {
    final montantRestantDisplay =
        _montantRestantDisplay(versement, currencyFormat);
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
                  width: 80,
                  child: pw.Text(
                      printLocalizations.translate('pdf_reference'),
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center,
                      maxLines: 2)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 70,
                  child: pw.Text(
                      printLocalizations.translate('pdf_remaining_amount_label'),
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center,
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

              // Recalcul du prix de l'article : marge puis remise sur le prix après marge
              final margin = item.id != null &&
                      options.selectiveItemMargins.containsKey(item.id)
                  ? options.selectiveItemMargins[item.id]
                  : null;
              final discount = item.id != null &&
                      options.selectiveLineDiscounts.containsKey(item.id)
                  ? options.selectiveLineDiscounts[item.id]
                  : null;
              final priceResult = MarginCalculationService.getItemFinalPrice(
                item: item,
                margin: margin,
                discount: discount,
              );
              final adjustedUnitPrice = priceResult.unitPrice;
              final adjustedTotalPrice = priceResult.totalPrice;
              final currentMargin = margin;

              // Calculer les valeurs pour les colonnes
              final carton = item.carton ?? 0;
              final unitPerCarton = (item.quantityPerCarton ?? 0).toDouble();
              final totalQuantity = (item.quantity ?? 0).toDouble();
              final totalCBM =
                  0.0; // Par défaut, peut être calculé si disponible
              final totalWeight =
                  0.0; // Par défaut, peut être calculé si disponible

              // Déterminer si le prix final a été modifié (Option A)
              final isPriceModified = currentMargin != null &&
                  currentMargin.displayMode ==
                      MarginDisplayMode.modifyFinalPrice &&
                  currentMargin.finalPrice != null;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Ligne principale de l'article
                  pw.Container(
                    color: PdfColors.white,
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 4, horizontal: 4),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                            flex: 3,
                            child: pw.Text(item.description ?? '',
                                style: const pw.TextStyle(fontSize: 8),
                                maxLines: 2)),
                        pw.SizedBox(width: 3),
                        pw.Container(
                            width: 80,
                            child: pw.Text(
                                _achatReferenceDisplay(achat),
                                style: const pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.center,
                                maxLines: 2)),
                        pw.SizedBox(width: 3),
                        pw.Container(
                            width: 70,
                            child: pw.Text(montantRestantDisplay,
                                style: const pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.center,
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
                            child: pw.Text(
                                currencyFormat.format(adjustedUnitPrice),
                                style: const pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.center)),
                        pw.SizedBox(width: 3),
                        pw.Container(
                            width: 50,
                            child: pw.Text(
                                currencyFormat.format(adjustedTotalPrice),
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: isPriceModified
                                      ? pw.FontWeight.bold
                                      : pw.FontWeight.normal,
                                  color: isPriceModified
                                      ? PdfColor.fromHex('#1A1E49')
                                      : PdfColors.black,
                                ),
                                textAlign: pw.TextAlign.center)),
                      ],
                    ),
                  ),
                ],
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

  static pw.Widget _buildAchatArticlesSection(
      List<Items>? filteredItems,
      PrintLocalizations printLocalizations,
      bool includeSupplierInfo,
      bool isProforma,
      NumberFormat currencyFormat,
      InvoiceOptions options,
      Achat achat,
      Versement? versement) {
    final refDisplay = _achatReferenceDisplay(achat);
    final montantRestantDisplay =
        _montantRestantDisplay(versement, currencyFormat);
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
                  width: 80,
                  child: pw.Text(
                      printLocalizations.translate('pdf_reference'),
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center,
                      maxLines: 2)),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 70,
                  child: pw.Text(
                      printLocalizations.translate('pdf_remaining_amount_label'),
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#1A1E49'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8),
                      textAlign: pw.TextAlign.center,
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

            // Recalcul du prix de l'article : marge puis remise sur le prix après marge
            final margin = item.id != null &&
                    options.selectiveItemMargins.containsKey(item.id)
                ? options.selectiveItemMargins[item.id]
                : null;
            final discount = item.id != null &&
                    options.selectiveLineDiscounts.containsKey(item.id)
                ? options.selectiveLineDiscounts[item.id]
                : null;
            final priceResult = MarginCalculationService.getItemFinalPrice(
              item: item,
              margin: margin,
              discount: discount,
            );
            final adjustedUnitPrice = priceResult.unitPrice;
            final adjustedTotalPrice = priceResult.totalPrice;
            final currentMargin = margin;

            // Calculer les valeurs pour les colonnes
            final carton = item.carton ?? 0;
            final unitPerCarton = (item.quantityPerCarton ?? 0).toDouble();
            final totalQuantity = (item.quantity ?? 0).toDouble();
            final totalCBM = 0.0; // Par défaut, peut être calculé si disponible
            final totalWeight =
                0.0; // Par défaut, peut être calculé si disponible

            // Déterminer si le prix final a été modifié (Option A)
            final isPriceModified = currentMargin != null &&
                currentMargin.displayMode ==
                    MarginDisplayMode.modifyFinalPrice &&
                currentMargin.finalPrice != null;

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Ligne principale de l'article
                pw.Container(
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
                          width: 80,
                          child: pw.Text(refDisplay,
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.center,
                              maxLines: 2)),
                      pw.SizedBox(width: 3),
                      pw.Container(
                          width: 70,
                          child: pw.Text(montantRestantDisplay,
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.center,
                              maxLines: 2)),
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
                          child: pw.Text(
                              currencyFormat.format(adjustedUnitPrice),
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.center)),
                      pw.SizedBox(width: 3),
                      pw.Container(
                          width: 50,
                          child:
                              pw.Text(currencyFormat.format(adjustedTotalPrice),
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: isPriceModified
                                        ? pw.FontWeight.bold
                                        : pw.FontWeight.normal,
                                    color: isPriceModified
                                        ? PdfColor.fromHex('#1A1E49')
                                        : PdfColors.black,
                                  ),
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
                ),
              ],
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
