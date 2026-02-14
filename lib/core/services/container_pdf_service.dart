import 'dart:typed_data';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/container_client_summary.dart';
import 'package:bbd_limited/core/services/container_summary_service.dart';
import 'package:bbd_limited/core/print/print_localizations.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

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
    final summaries = ContainerSummaryService.generateSummary(container);

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

              // Tableau du résumé
              _buildSummaryTable(summaries, printLocalizations),
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
        // Première ligne: DESTINATION, GRP NO, etc.
        pw.Row(
          children: [
            // DESTINATION
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
                      '${printLocalizations.translate('pdf_destination')}（目的地）: ',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // GRP NO
            pw.Expanded(
              flex: 1,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Text(
                  '${printLocalizations.translate('pdf_grp_no')}（柜推号码）',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Numéro GRP
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
                    container.reference ?? '',
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

        // Deuxième ligne: LOADING DATE et DATE ARRIVAL
        pw.Row(
          children: [
            // LOADING DATE
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
                      '${printLocalizations.translate('pdf_loading_date')}（装柜日期）: ',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      container.departureDate != null
                          ? dateFormat.format(container.departureDate!)
                          : '',
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
                      '${printLocalizations.translate('pdf_date_arrival')}（到货日期）: ',
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

        // Troisième ligne: CONTAINER NUMBER et TRANS
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
                      '${printLocalizations.translate('pdf_container_number')}（柜号）: ',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      container.reference ?? '',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ),
            // TRANS
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
                      '${printLocalizations.translate('pdf_trans')}（客货）: ',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      container.userName ?? '',
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

  /// Construit le tableau du résumé
  static pw.Widget _buildSummaryTable(
    List<ContainerClientSummary> summaries,
    PrintLocalizations printLocalizations,
  ) {
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
              _buildTableCell('-', alignment: pw.Alignment.center),
              _buildTableCell('-', alignment: pw.Alignment.center),
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
