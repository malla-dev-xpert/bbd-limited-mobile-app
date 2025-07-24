import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/cashWithdrawal.dart';

class VersementPrintService {
  static Future<Uint8List> buildVersementPdfBytes(
    Versement versement,
    List<Achat> achats,
    List<CashWithdrawal> retraits, // <-- nouveau paramètre
  ) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
        locale: 'fr_FR', symbol: versement.deviseCode ?? 'CNY');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final Uint8List logoBytes = await rootBundle
        .load('assets/images/logo.png')
        .then((data) => data.buffer.asUint8List());
    double sousTotal = 0;
    for (final achat in achats) {
      for (final item in (achat.items ?? [])) {
        sousTotal += item.totalPrice ?? 0;
      }
    }
    // double tva = sousTotal * 0.15;
    double montantTotal = sousTotal;
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
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Image(pw.MemoryImage(logoBytes), width: 100),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('FACTURE',
                                  style: pw.TextStyle(
                                      fontSize: 32,
                                      color: PdfColor.fromHex('#1A1E49'),
                                      fontWeight: pw.FontWeight.bold,
                                      letterSpacing: 4)),
                              pw.SizedBox(height: 8),
                              pw.Row(children: [
                                pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  children: [
                                    pw.Text('RÉF DU VERSEMENT',
                                        style: pw.TextStyle(
                                          fontSize: 9,
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
                                    pw.Text('DATE DU VERSEMENT',
                                        style: pw.TextStyle(
                                          fontSize: 9,
                                          color: PdfColors.grey600,
                                          fontWeight: pw.FontWeight.bold,
                                          letterSpacing: 1.2,
                                        )),
                                    pw.Text(
                                      dateFormat.format(versement.createdAt ??
                                          DateTime.now()),
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
                                    pw.Text('MONTANT VERSÉ',
                                        style: pw.TextStyle(
                                          fontSize: 9,
                                          color: PdfColors.grey600,
                                          fontWeight: pw.FontWeight.bold,
                                          letterSpacing: 1.2,
                                        )),
                                    pw.Text(
                                      currencyFormat
                                          .format(versement.montantVerser),
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
                                    pw.Text('MONTANT RESTANT',
                                        style: pw.TextStyle(
                                          fontSize: 9,
                                          color: PdfColors.grey600,
                                          fontWeight: pw.FontWeight.bold,
                                          letterSpacing: 1.2,
                                        )),
                                    pw.Text(
                                      currencyFormat
                                          .format(versement.montantRestant),
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
                      ),
                      pw.SizedBox(height: 24),
                      pw.Row(
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
                                if (versement.note != null &&
                                    versement.note!.isNotEmpty)
                                  pw.Text(versement.note!,
                                      style: const pw.TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text('COMISSIONNAIRE',
                                    style: pw.TextStyle(
                                        fontSize: 12,
                                        color: PdfColor.fromHex('#1A1E49'),
                                        fontWeight: pw.FontWeight.bold,
                                        letterSpacing: 2)),
                                pw.Text(
                                    'Nom : ${versement.commissionnaireName}',
                                    style: pw.TextStyle(fontSize: 12)),
                                pw.Text(
                                    'Téléphone : ${versement.commissionnairePhone}',
                                    style: pw.TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 24),
                      pw.Text("Liste des articles",
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#1A1E49'),
                          )),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        color: PdfColor.fromHex('#1A1E49'),
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                                child: pw.Text('Désignation',
                                    style: pw.TextStyle(
                                        color: PdfColors.white,
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Container(
                                width: 40,
                                child: pw.Text('Qté',
                                    style: pw.TextStyle(
                                        color: PdfColors.white,
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Container(
                                width: 70,
                                child: pw.Text('Taux d\'achat',
                                    style: pw.TextStyle(
                                        color: PdfColors.white,
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Container(
                                width: 100,
                                child: pw.Text('P.U',
                                    style: pw.TextStyle(
                                        color: PdfColors.white,
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Container(
                                width: 100,
                                child: pw.Text('TOTAL',
                                    style: pw.TextStyle(
                                        color: PdfColors.white,
                                        fontWeight: pw.FontWeight.bold))),
                          ],
                        ),
                      ),
                      for (final achat in achats)
                        for (final item in (achat.items ?? []))
                          pw.Container(
                            color: PdfColors.grey200,
                            padding: const pw.EdgeInsets.symmetric(
                                vertical: 4, horizontal: 12),
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                    child: pw.Text(item.description ?? '',
                                        style:
                                            const pw.TextStyle(fontSize: 12))),
                                pw.Container(
                                    width: 40,
                                    child: pw.Text('${item.quantity ?? ''}',
                                        style:
                                            const pw.TextStyle(fontSize: 12))),
                                pw.Container(
                                    width: 70,
                                    child: pw.Text('${item.salesRate ?? ''}',
                                        style:
                                            const pw.TextStyle(fontSize: 12))),
                                pw.Container(
                                    width: 100,
                                    child: pw.Text(
                                        currencyFormat
                                            .format(item.unitPrice ?? 0),
                                        style:
                                            const pw.TextStyle(fontSize: 12))),
                                pw.Container(
                                    width: 100,
                                    child: pw.Text(
                                        currencyFormat
                                            .format(item.totalPrice ?? 0),
                                        style:
                                            const pw.TextStyle(fontSize: 12))),
                              ],
                            ),
                          ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              // pw.Text(
                              //     'Sous-total : ${currencyFormat.format(sousTotal)}',
                              //     style: const pw.TextStyle(fontSize: 12)),
                              // pw.Text(
                              //     'TVA (15%) : ${currencyFormat.format(tva)}',
                              //     style: const pw.TextStyle(fontSize: 12)),
                              pw.Text(
                                  'MONTANT TOTAL : ${currencyFormat.format(montantTotal)}',
                                  style: pw.TextStyle(
                                      fontSize: 14,
                                      fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      // Ajout du tableau des retraits d'argent si non vide
                      if (retraits.isNotEmpty) ...[
                        pw.SizedBox(height: 24),
                        pw.Text("Liste des retraits d'argent",
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#1A1E49'),
                            )),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          color: PdfColor.fromHex('#1A1E49'),
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 6, horizontal: 12),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                  width: 100,
                                  child: pw.Text('Date',
                                      style: pw.TextStyle(
                                          color: PdfColors.white,
                                          fontWeight: pw.FontWeight.bold))),
                              pw.Container(
                                  width: 100,
                                  child: pw.Text('Montant',
                                      style: pw.TextStyle(
                                          color: PdfColors.white,
                                          fontWeight: pw.FontWeight.bold))),
                              pw.Expanded(
                                  child: pw.Text('Motif',
                                      style: pw.TextStyle(
                                          color: PdfColors.white,
                                          fontWeight: pw.FontWeight.bold))),
                            ],
                          ),
                        ),
                        ...retraits.map((r) => pw.Container(
                              color: PdfColors.grey200,
                              padding: const pw.EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 12),
                              child: pw.Row(
                                children: [
                                  pw.Container(
                                    width: 100,
                                    child: pw.Text(
                                      r.dateRetrait != null
                                          ? dateFormat.format(r.dateRetrait!)
                                          : 'Date inconnue',
                                    ),
                                  ),
                                  pw.Container(
                                      width: 100,
                                      child: pw.Text(
                                          currencyFormat.format(r.montant))),
                                  pw.Expanded(child: pw.Text(r.note ?? '')),
                                ],
                              ),
                            )),
                        // Ajout du total des retraits
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Text(
                                'TOTAL DES RETRAITS : ${currencyFormat.format(totalRetraits)}',
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
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
    bool isProforma = false,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final Uint8List logoBytes = await rootBundle
        .load('assets/images/logo.png')
        .then((data) => data.buffer.asUint8List());

    final primaryColor =
        isProforma ? PdfColor.fromHex('#6c757d') : PdfColor.fromHex('#1A1E49');

    // Calcul du montant total
    double montantTotal =
        achat.items?.fold(0, (sum, item) => sum! + (item.totalPrice ?? 0)) ?? 0;

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
                      // En-tête avec logo et informations principales
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Image(pw.MemoryImage(logoBytes), width: 100),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                  isProforma ? 'PRO-FORMA' : 'FACTURE D\'ACHAT',
                                  style: pw.TextStyle(
                                      fontSize: 32,
                                      color: PdfColor.fromHex('#1A1E49'),
                                      fontWeight: pw.FontWeight.bold,
                                      letterSpacing: 4)),
                              pw.SizedBox(height: 8),
                              pw.Row(children: [
                                pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  children: [
                                    pw.Text('RÉFÉRENCE',
                                        style: pw.TextStyle(
                                          fontSize: 9,
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
                                    pw.Text('DATE',
                                        style: pw.TextStyle(
                                          fontSize: 9,
                                          color: PdfColors.grey600,
                                          fontWeight: pw.FontWeight.bold,
                                          letterSpacing: 1.2,
                                        )),
                                    pw.Text(
                                      dateFormat.format(
                                          achat.createdAt ?? DateTime.now()),
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
                      ),
                      pw.SizedBox(height: 24),

                      // Informations du fournisseur (si demandé)
                      if (includeSupplierInfo &&
                          achat.items?.isNotEmpty == true &&
                          achat.items?.first.supplierName != null)
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('FOURNISSEUR',
                                      style: pw.TextStyle(
                                          fontSize: 12,
                                          color: PdfColor.fromHex('#1A1E49'),
                                          fontWeight: pw.FontWeight.bold,
                                          letterSpacing: 2)),
                                  pw.Text(achat.items!.first.supplierName ?? '',
                                      style: const pw.TextStyle(fontSize: 12)),
                                  if (achat.items!.first.supplierPhone != null)
                                    pw.Text(
                                        'Tél: ${achat.items!.first.supplierPhone}',
                                        style:
                                            const pw.TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      pw.SizedBox(height: 24),

                      // Liste des articles
                      pw.Text("LISTE DES ARTICLES",
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#1A1E49'),
                          )),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        color: isProforma
                            ? PdfColors.grey100
                            : PdfColor.fromHex('#1A1E49'),
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                                child: pw.Text('DÉSIGNATION',
                                    style: pw.TextStyle(
                                        color: isProforma
                                            ? PdfColors.grey500
                                            : PdfColors.white,
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Container(
                                width: 40,
                                child: pw.Text('QTÉ',
                                    style: pw.TextStyle(
                                        color: isProforma
                                            ? PdfColors.grey500
                                            : PdfColors.white,
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Container(
                                width: 70,
                                child: pw.Text('TAUX',
                                    style: pw.TextStyle(
                                        color: isProforma
                                            ? PdfColors.grey500
                                            : PdfColors.white,
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Container(
                                width: 100,
                                child: pw.Text('PRIX UNIT.',
                                    style: pw.TextStyle(
                                        color: isProforma
                                            ? PdfColors.grey500
                                            : PdfColors.white,
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Container(
                                width: 100,
                                child: pw.Text('TOTAL',
                                    style: pw.TextStyle(
                                        color: isProforma
                                            ? PdfColors.grey500
                                            : PdfColors.white,
                                        fontWeight: pw.FontWeight.bold))),
                          ],
                        ),
                      ),
                      for (final item in (achat.items ?? []))
                        pw.Container(
                          color: PdfColors.grey200,
                          padding: const pw.EdgeInsets.symmetric(
                              vertical: 4, horizontal: 12),
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                  child: pw.Text(item.description ?? '',
                                      style: const pw.TextStyle(fontSize: 12))),
                              pw.Container(
                                  width: 40,
                                  child: pw.Text('${item.quantity ?? ''}',
                                      style: const pw.TextStyle(fontSize: 12))),
                              pw.Container(
                                  width: 70,
                                  child: pw.Text('${item.salesRate ?? ''}',
                                      style: const pw.TextStyle(fontSize: 12))),
                              pw.Container(
                                  width: 100,
                                  child: pw.Text(
                                      currencyFormat
                                          .format(item.unitPrice ?? 0),
                                      style: const pw.TextStyle(fontSize: 12))),
                              pw.Container(
                                  width: 100,
                                  child: pw.Text(
                                      currencyFormat
                                          .format(item.totalPrice ?? 0),
                                      style: const pw.TextStyle(fontSize: 12))),
                            ],
                          ),
                        ),
                      pw.SizedBox(height: 12),

                      // Total
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                  'MONTANT TOTAL : ${currencyFormat.format(montantTotal)}',
                                  style: pw.TextStyle(
                                      fontSize: 14,
                                      fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
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
}
