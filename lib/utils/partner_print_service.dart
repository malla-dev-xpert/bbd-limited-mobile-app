import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/models/packages.dart';

class PartnerPrintService {
  final NumberFormat currencyFormat;
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  PartnerPrintService({required this.currencyFormat});

  Future<Uint8List> buildClientReportPdfBytes(
    Partner partner, {
    DateTimeRange? dateRange,
  }) async {
    final pdf = pw.Document();
    final logoBytes = await rootBundle
        .load('assets/images/logo.png')
        .then((data) => data.buffer.asUint8List());

    // Convertir les Iterable en List explicitement
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
                      _buildHeader(logoBytes, dateRange),
                      _buildClientInfoSection(partner),
                      _buildSummarySection(
                        filteredVersements,
                        filteredPackages,
                      ),
                      if (filteredVersements.isNotEmpty)
                        _buildVersementsSection(filteredVersements),
                      if (filteredPackages.isNotEmpty)
                        _buildPackagesSection(filteredPackages),
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

  List<Versement> _filterVersements(
      List<Versement>? versements, DateTimeRange? dateRange) {
    if (versements == null) return [];
    if (dateRange == null) return versements;

    return versements
        .where((v) =>
            v.createdAt != null &&
            v.createdAt!.isAfter(dateRange.start) &&
            v.createdAt!.isBefore(dateRange.end.add(const Duration(days: 1))))
        .toList(); // Conversion explicite en List
  }

  List<Packages> _filterPackages(
      List<Packages>? packages, DateTimeRange? dateRange) {
    if (packages == null) return [];
    if (dateRange == null) return packages;

    return packages
        .where((p) =>
            p.startDate != null &&
            p.startDate!.isAfter(dateRange.start) &&
            p.startDate!.isBefore(dateRange.end.add(const Duration(days: 1))))
        .toList(); // Conversion explicite en List
  }

  pw.Widget _buildHeader(Uint8List logoBytes, DateTimeRange? dateRange) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Image(pw.MemoryImage(logoBytes), width: 100),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('ÉTAT DU CLIENT',
                style: pw.TextStyle(
                    fontSize: 32,
                    color: PdfColor.fromHex('#1A1E49'),
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(
                dateRange == null
                    ? 'Toutes périodes'
                    : 'Du ${dateFormat.format(dateRange.start)} au ${dateFormat.format(dateRange.end)}',
                style: pw.TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildClientInfoSection(Partner partner) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('INFORMATIONS CLIENT',
            style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1A1E49'))),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _infoRow('Nom', '${partner.firstName} ${partner.lastName}'),
                _infoRow('Téléphone', partner.phoneNumber),
                _infoRow('Email', partner.email),
              ],
            ),
            pw.SizedBox(width: 40),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _infoRow('Adresse', partner.adresse),
                _infoRow('Type de compte', partner.accountType),
                _infoRow('Solde',
                    '${partner.balance?.toStringAsFixed(2) ?? '0.00'}'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _infoRow(String label, String? value) {
    return pw.Row(
      children: [
        pw.Text('$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.Text(value ?? '-', style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(width: 20),
      ],
    );
  }

  pw.Widget _buildSummarySection(
    List<Versement> versements,
    List<Packages> packages,
  ) {
    final totalVersements =
        versements.fold<double>(0, (sum, v) => sum + (v.montantVerser ?? 0));
    final totalRetraits = versements
        .expand((v) => v.cashWithdrawalDtoList ?? [])
        .fold<double>(0, (sum, r) => sum + (r.amount ?? 0));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('RÉCAPITULATIF',
            style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1A1E49'))),
        pw.SizedBox(height: 8),
        pw.Container(
          color: PdfColor.fromHex('#1A1E49'),
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: pw.Row(
            children: [
              pw.Expanded(
                  child: pw.Text('CATÉGORIE',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold))),
              pw.Expanded(
                  child: pw.Text('MONTANT',
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
              pw.Expanded(child: pw.Text('Total versements')),
              pw.Expanded(
                  child: pw.Text(currencyFormat.format(totalVersements))),
            ],
          ),
        ),
        pw.Container(
          color: PdfColors.grey100,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Total retraits')),
              pw.Expanded(child: pw.Text(currencyFormat.format(totalRetraits))),
            ],
          ),
        ),
        pw.Container(
          color: PdfColors.grey200,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: pw.Row(
            children: [
              pw.Expanded(child: pw.Text('Nombre de colis')),
              pw.Expanded(child: pw.Text('${packages.length}')),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildVersementsSection(List<Versement> versements) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('VERSEMENTS',
            style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1A1E49'))),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          context: null,
          border: pw.TableBorder.all(color: PdfColors.grey300),
          headerStyle: pw.TextStyle(
              color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          headerDecoration:
              pw.BoxDecoration(color: PdfColor.fromHex('#1A1E49')),
          headers: ['Date', 'Référence', 'Montant', 'Type', 'Retraits'],
          data: versements
              .map((v) => [
                    dateFormat.format(v.createdAt ?? DateTime.now()),
                    v.reference ?? '-',
                    currencyFormat.format(v.montantVerser ?? 0),
                    v.type ?? '-',
                    currencyFormat.format(v.cashWithdrawalDtoList?.fold<double>(
                            0, (sum, r) => sum + (r.montant ?? 0)) ??
                        0),
                  ])
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildPackagesSection(List<Packages> packages) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('COLIS',
            style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1A1E49'))),
        pw.SizedBox(height: 8),
        for (final package in packages) ...[
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text('Colis ${package.ref}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 10),
                    pw.Text(
                        '(${dateFormat.format(package.startDate ?? DateTime.now())})'),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text('De: ${package.startCountry}'),
                    pw.SizedBox(width: 10),
                    pw.Text('À: ${package.destinationCountry}'),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text('Statut: ${package.status?.name ?? '-'}'),
                pw.SizedBox(height: 8),
                // if (package.items != null && package.items!.isNotEmpty)
                //   pw.TableHelper.fromTextArray(
                //     context: null,
                //     border: pw.TableBorder.all(color: PdfColors.grey300),
                //     headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                //     headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
                //     headers: ['Article', 'Qté', 'Prix unit.', 'Total'],
                //     data: package.items!.map((item) => [
                //       item.description ?? '-',
                //       '${item.quantity}',
                //       currencyFormat.format(item.unitPrice ?? 0),
                //       currencyFormat.format(item.totalPrice ?? 0),
                //     ]).toList(),
                //   ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
