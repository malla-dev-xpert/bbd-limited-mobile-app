import 'dart:typed_data';
import 'package:bbd_limited/core/services/cbm_pricing_services.dart';
import 'package:bbd_limited/core/services/container_summary_service.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/container_client_summary.dart';
import 'package:bbd_limited/core/print/print_localizations.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Référence du conteneur uniquement (partie rouge du PDF).
String _pdfContainerReference(Containers c) {
  return c.reference?.trim() ?? '';
}

/// Date de chargement ; si nulle, date de création du conteneur.
String _formatLoadingDate(Containers c, DateFormat dateFormat) {
  final date = c.loadingDate ?? c.createdAt;
  return date != null ? dateFormat.format(date) : '';
}

/// Formate un montant CFA avec séparateur de milliers (ex. 1 000 000, 35 000).
String _formatCfaAmount(double value) {
  final n = value.round().abs();
  final s = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(s[i]);
  }
  return value.round() < 0 ? '-${buffer}' : buffer.toString();
}

/// Service pour générer un PDF du résumé du conteneur
/// au format facture BBD LIMITED avec support multi-langue
class ContainerPdfService {
  /// Génère un PDF du résumé du conteneur au format BBD LIMITED
  ///
  /// [container] Le conteneur à exporter
  /// [printLocalizations] Les traductions pour la langue choisie
  ///
  /// Retourne les bytes du PDF généré
  static Future<Uint8List> generateContainerSummaryPdf(
    Containers container,
    PrintLocalizations printLocalizations,
  ) async {
    final pdf = pw.Document();
    final cbmService = CbmPricingServices();
    final summaries = await ContainerSummaryService.generateSummaryWithShipping(
      container,
      cbmService,
    );

    // Charger le logo
    final Uint8List logoBytes = await rootBundle
        .load('assets/images/logo.png')
        .then((data) => data.buffer.asUint8List());

    // Formats de dates
    final dateFormat = DateFormat('yyyy.MM.dd');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête avec logo et titre
              _buildHeader(logoBytes, printLocalizations),
              pw.SizedBox(height: 10),

              // Adresse et email
              _buildCompanyInfo(),
              pw.SizedBox(height: 15),

              // Ligne de séparation
              pw.Container(
                height: 2,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 10),

              // Informations du conteneur (DESTINATION, LOADING DATE, etc.)
              _buildContainerInfo(container, dateFormat, printLocalizations),
              pw.SizedBox(height: 10),

              // Ligne de séparation
              pw.Container(
                height: 2,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 15),

              // Tableau du résumé (CTNS, T.CBM, CFA, TELEPHONE=carrier, KGS)
              _buildSummaryTable(summaries, container, printLocalizations),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Construit l'en-tête avec le logo et le titre BBD LIMITED
  static pw.Widget _buildHeader(
    Uint8List logoBytes,
    PrintLocalizations printLocalizations,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Logo BBD LIMITED
        pw.Image(
          pw.MemoryImage(logoBytes),
          width: 80,
          height: 80,
        ),

        // Titre BBD LIMITED
        pw.Text(
          'BBD LIMITED',
          style: pw.TextStyle(
            fontSize: 32,
            fontWeight: pw.FontWeight.bold,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// Construit les informations de l'entreprise (adresse et email)
  static pw.Widget _buildCompanyInfo() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'Room 102,Building,No. 10,Zhao zhai 3 District Choucheng Yiwu China',
          style: const pw.TextStyle(fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'EMAIL: bbd.g@hotmail.com/doubailimited@hotmail.com',
          style: pw.TextStyle(
            fontSize: 10,
            fontStyle: pw.FontStyle.italic,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  /// Construit les informations du conteneur
  static pw.Widget _buildContainerInfo(
    Containers container,
    DateFormat dateFormat,
    PrintLocalizations printLocalizations,
  ) {
    return pw.Column(
      children: [
        // Première ligne: DESTINATION (port d'arrivée), GRP NO: -, référence (rouge)
        pw.Row(
          children: [
            // DESTINATION = port d'arrivée du conteneur
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      '${printLocalizations.translate('pdf_destination')}: ',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      container.arrivalHarborName ?? container.arrivalHarborLocation ?? '',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),
            // GRP NO: - pour le moment
            pw.Expanded(
              flex: 1,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Text(
                  '${printLocalizations.translate('pdf_grp_no')}: -',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Référence du conteneur uniquement (partie rouge)
            pw.Expanded(
              flex: 1,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                  color: PdfColors.red50,
                ),
                child: pw.Center(
                  child: pw.Text(
                    _pdfContainerReference(container),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Deuxième ligne: LOADING DATE (date de chargement, sinon date de création) et DATE ARRIVAL
        pw.Row(
          children: [
            // LOADING DATE = date de chargement; si nulle, date de création du conteneur
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${printLocalizations.translate('pdf_loading_date')}: ',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _formatLoadingDate(container, dateFormat),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ),
            // DATE ARRIVAL
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${printLocalizations.translate('pdf_date_arrival')}: ',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      container.arrivalDate != null
                          ? dateFormat.format(container.arrivalDate!)
                          : '',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.red900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Troisième ligne: CONTAINER NUMBER et MARK (carrier)
        pw.Row(
          children: [
            // CONTAINER NUMBER
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${printLocalizations.translate('pdf_container_number')}: ',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      container.containerNumber ?? container.reference ?? '',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ),
            // MARK = nom du carrier lié au conteneur
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${printLocalizations.translate('pdf_mark')}: ',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      container.carrierName ?? '',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construit le tableau du résumé.
  /// CTNS = total cartons du client, T.CBM = total CBM, CFA = total shipping price du client,
  /// TELEPHONE = téléphone du carrier du conteneur, KGS = total poids du client.
  static pw.Widget _buildSummaryTable(
    List<ContainerClientSummary> summaries,
    Containers container,
    PrintLocalizations printLocalizations,
  ) {
    final carrierPhone = container.carrierContact?.trim();
    final telephoneDisplay = (carrierPhone != null && carrierPhone.isNotEmpty)
        ? carrierPhone
        : '-';

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: {
        0: const pw.FixedColumnWidth(30), // N
        1: const pw.FlexColumnWidth(3), // MARK
        2: const pw.FixedColumnWidth(50), // CTNS
        3: const pw.FixedColumnWidth(60), // T.CBM
        4: const pw.FixedColumnWidth(80), // CFA
        5: const pw.FixedColumnWidth(90), // TELEPHONE
        6: const pw.FixedColumnWidth(50), // KGS
      },
      children: [
        // En-tête du tableau
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _buildTableHeader('N'),
            _buildTableHeader(printLocalizations.translate('pdf_mark')),
            _buildTableHeader(printLocalizations.translate('pdf_ctns')),
            _buildTableHeader(printLocalizations.translate('pdf_tcbm')),
            _buildTableHeader(printLocalizations.translate('pdf_cfa')),
            _buildTableHeader(printLocalizations.translate('pdf_telephone')),
            _buildTableHeader(printLocalizations.translate('pdf_kgs')),
          ],
        ),

        // Lignes de données
        ...summaries.asMap().entries.map((entry) {
          final index = entry.key;
          final summary = entry.value;
          final isEven = index % 2 == 0;
          final cfaDisplay = summary.totalShippingPrice > 0
              ? _formatCfaAmount(summary.totalShippingPrice)
              : '-';

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : PdfColors.grey100,
            ),
            children: [
              _buildTableCell('${index + 1}', alignment: pw.Alignment.center),
              _buildTableCell(summary.clientName),
              _buildTableCell(
                '${summary.totalCartons}',
                alignment: pw.Alignment.center,
              ),
              _buildTableCell(
                summary.totalCbm.toStringAsFixed(3),
                alignment: pw.Alignment.center,
              ),
              _buildTableCell(cfaDisplay, alignment: pw.Alignment.center),
              _buildTableCell(telephoneDisplay, alignment: pw.Alignment.center),
              _buildTableCell(
                '${summary.totalWeight.round()}',
                alignment: pw.Alignment.center,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Construit une cellule d'en-tête du tableau
  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// Construit une cellule de données du tableau
  static pw.Widget _buildTableCell(
    String text, {
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: alignment,
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }
}
