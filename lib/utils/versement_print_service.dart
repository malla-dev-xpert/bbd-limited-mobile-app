import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/models/achats/achat.dart';

class VersementPrintService {
  static Future<Uint8List> buildVersementPdfBytes(
    Versement versement,
    List<Achat> achats,
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
    double tva = sousTotal * 0.15;
    double montantTotal = sousTotal + tva;
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
                        children: [
                          pw.Image(pw.MemoryImage(logoBytes), height: 50),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('DÉTAILS',
                                  style: pw.TextStyle(
                                      fontSize: 32,
                                      color: PdfColor.fromHex('#1A1E49'),
                                      fontWeight: pw.FontWeight.bold,
                                      letterSpacing: 4)),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                  'RÉF. DU VERSEMENT : ${versement.reference ?? ''}',
                                  style: pw.TextStyle(
                                      fontSize: 12,
                                      color: PdfColor.fromHex('#1A1E49'))),
                              pw.Text(
                                  'DATE : ${dateFormat.format(versement.createdAt ?? DateTime.now())}',
                                  style: pw.TextStyle(
                                      fontSize: 12,
                                      color: PdfColor.fromHex('#1A1E49'))),
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
                                        style: pw.TextStyle(fontSize: 12))),
                                pw.Container(
                                    width: 40,
                                    child: pw.Text('${item.quantity ?? ''}',
                                        style: pw.TextStyle(fontSize: 12))),
                                pw.Container(
                                    width: 70,
                                    child: pw.Text('${item.salesRate ?? ''}',
                                        style: pw.TextStyle(fontSize: 12))),
                                pw.Container(
                                    width: 100,
                                    child: pw.Text(
                                        currencyFormat
                                            .format(item.unitPrice ?? 0),
                                        style: pw.TextStyle(fontSize: 12))),
                                pw.Container(
                                    width: 100,
                                    child: pw.Text(
                                        currencyFormat
                                            .format(item.totalPrice ?? 0),
                                        style: pw.TextStyle(fontSize: 12))),
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
                              pw.Text(
                                  'Sous-total : ${currencyFormat.format(sousTotal)}',
                                  style: pw.TextStyle(fontSize: 12)),
                              pw.Text(
                                  'TVA (15%) : ${currencyFormat.format(tva)}',
                                  style: pw.TextStyle(fontSize: 12)),
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
