import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Polices préchargées pour le header PDF (latin + chinois).
/// Obtenir via [PdfHeader.loadFonts()].
class PdfHeaderFonts {
  const PdfHeaderFonts({
    required this.latin,
    required this.chinese,
  });

  final pw.Font latin;
  final pw.Font chinese;
}

/// Constantes visuelles du header PDF (reproduction pixel-perfect).
abstract class _PdfHeaderConstants {
  _PdfHeaderConstants._();

  // --- Proportions layout (A4) ---
  static const int flexLeft = 7;
  static const int flexRight = 3;

  // --- Couleurs (spécification) ---
  /// Bleu titre BBD LIMITED — #4A79B8
  static final PdfColor colorTitle = PdfColor.fromHex('#4A79B8');

  /// Rouge adresses — #C62828
  static final PdfColor colorAddress = PdfColor.fromHex('#C62828');

  /// Ligne de séparation — #3F51B5
  static final PdfColor colorSeparator = PdfColor.fromHex('#3F51B5');

  /// Texte secondaire (contact, email)
  static final PdfColor colorSecondary = PdfColors.grey800;

  // --- Tailles de police (explicites) ---
  static const double fontSizeTitle = 30.0;
  static const double fontSizeAddress = 12.5;
  static const double fontSizeContactLabel = 11.0;
  static const double fontSizeContactValue = 11.0;

  // --- Espacements (pt) ---
  static const double spacingAfterTitle = 6.0;
  static const double spacingBetweenAddresses = 2.0;
  static const double spacingBeforeSeparator = 8.0;
  static const double separatorHeight = 1.0;
  static const double spacingAfterSeparator = 8.0;
  static const double spacingBetweenContactColumns = 24.0;
  static const double spacingContactLabelToValue = 3.0;
  static const double paddingLeftSection = 16.0;
  static const double logoContainerPadding = 8.0;
  static const double logoSize = 130.0;
  static const double letterSpacingTitle = 1.2;
}

class PdfHeader {
  PdfHeader._();

  static const String _companyName = 'BBD LIMITED';
  static const String _addressEn =
      '1Floor, Building 10, Room 102, Zhao Zhai san qu, Yiwu, Zhejiang, China';
  static const String _addressZh = '中国 浙江省义乌市赵宅3区10栋1单元102';
  static const String _phone1 = '0086 18678859834';
  static const String _phone2 = '0086 13503032311';
  static const String _phone3 = '0086 (579)85568522';
  static const String _email = 'bbd@bbdcompany.com';

  /// Chemins des polices (assets).
  static const String assetLatinFont = 'assets/fonts/Roboto-Regular.ttf';
  static const String assetChineseFont =
      'assets/fonts/NotoSansSC-VariableFont_wght.ttf';

  /// Charge les polices depuis les assets (latin + chinois).
  /// Utiliser le résultat dans [build].
  static Future<PdfHeaderFonts> loadFonts() async {
    pw.Font latin;
    try {
      final data = await rootBundle.load(assetLatinFont);
      latin = pw.Font.ttf(data);
    } catch (_) {
      latin = pw.Font.helvetica();
    }
    final chineseData = await rootBundle.load(assetChineseFont);
    final chinese = pw.Font.ttf(chineseData);
    return PdfHeaderFonts(latin: latin, chinese: chinese);
  }

  /// Construit le widget header (carte société + logo).
  /// [logoBytes] : image du logo (ex. chargée depuis assets/images/logo.png).
  /// [fonts] : polices retournées par [loadFonts()].
  static pw.Widget build(Uint8List logoBytes, PdfHeaderFonts fonts) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        // Outer border only, no generic background color to allow right side to be white
        border: pw.Border.all(
          color: _PdfHeaderConstants.colorSeparator,
          width: 1.0,
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment
            .start, // Avoid stretch to fix TooManyPagesException
        children: [
          pw.Expanded(
            flex: _PdfHeaderConstants.flexLeft,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex(
                    '#E3F2FD'), // Background color moved to left container
                border: pw.Border(
                  right: pw.BorderSide(
                    color: _PdfHeaderConstants.colorSeparator,
                    width: 1.0,
                  ),
                ),
              ),
              padding: const pw.EdgeInsets.all(
                  _PdfHeaderConstants.paddingLeftSection),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    _companyName,
                    style: pw.TextStyle(
                      fontSize: _PdfHeaderConstants.fontSizeTitle,
                      fontWeight: pw.FontWeight.bold,
                      fontStyle: pw.FontStyle.italic,
                      color: _PdfHeaderConstants.colorTitle,
                      letterSpacing: _PdfHeaderConstants.letterSpacingTitle,
                      font: fonts.latin,
                    ),
                  ),
                  pw.SizedBox(height: _PdfHeaderConstants.spacingAfterTitle),
                  pw.Text(
                    _addressEn,
                    style: pw.TextStyle(
                      fontSize: _PdfHeaderConstants.fontSizeAddress,
                      color: _PdfHeaderConstants.colorAddress,
                      font: fonts.latin,
                    ),
                  ),
                  pw.SizedBox(
                      height: _PdfHeaderConstants.spacingBetweenAddresses),
                  pw.Text(
                    _addressZh,
                    style: pw.TextStyle(
                      fontSize: _PdfHeaderConstants.fontSizeAddress,
                      color: _PdfHeaderConstants.colorAddress,
                      font: fonts.chinese,
                    ),
                  ),
                  pw.SizedBox(
                      height: _PdfHeaderConstants.spacingBeforeSeparator),
                  pw.Container(
                    height: _PdfHeaderConstants.separatorHeight,
                    color: _PdfHeaderConstants.colorSeparator,
                  ),
                  pw.SizedBox(
                      height: _PdfHeaderConstants.spacingAfterSeparator),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              'Contact :',
                              style: pw.TextStyle(
                                fontSize:
                                    _PdfHeaderConstants.fontSizeContactLabel,
                                fontWeight: pw.FontWeight.bold,
                                color: _PdfHeaderConstants.colorSecondary,
                                font: fonts.latin,
                              ),
                            ),
                            pw.SizedBox(
                                height: _PdfHeaderConstants
                                    .spacingContactLabelToValue),
                            pw.Text(
                              _phone1,
                              style: pw.TextStyle(
                                fontSize:
                                    _PdfHeaderConstants.fontSizeContactValue,
                                color: _PdfHeaderConstants.colorSecondary,
                                font: fonts.latin,
                              ),
                            ),
                            pw.Text(
                              _phone2,
                              style: pw.TextStyle(
                                fontSize:
                                    _PdfHeaderConstants.fontSizeContactValue,
                                color: _PdfHeaderConstants.colorSecondary,
                                font: fonts.latin,
                              ),
                            ),
                            pw.Text(
                              _phone3,
                              style: pw.TextStyle(
                                fontSize:
                                    _PdfHeaderConstants.fontSizeContactValue,
                                color: _PdfHeaderConstants.colorSecondary,
                                font: fonts.latin,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(
                          width:
                              _PdfHeaderConstants.spacingBetweenContactColumns),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              'EMail :',
                              style: pw.TextStyle(
                                fontSize:
                                    _PdfHeaderConstants.fontSizeContactLabel,
                                fontWeight: pw.FontWeight.bold,
                                color: _PdfHeaderConstants.colorSecondary,
                                font: fonts.latin,
                              ),
                            ),
                            pw.SizedBox(
                                height: _PdfHeaderConstants
                                    .spacingContactLabelToValue),
                            pw.Text(
                              _email,
                              style: pw.TextStyle(
                                fontSize:
                                    _PdfHeaderConstants.fontSizeContactValue,
                                color: _PdfHeaderConstants.colorSecondary,
                                font: fonts.latin,
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
          pw.Expanded(
            flex: _PdfHeaderConstants.flexRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(
                  _PdfHeaderConstants.logoContainerPadding),
              alignment: pw.Alignment.center,
              // Background is naturally white, and left border is handled by the left container's right border
              child: pw.Center(
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  width: _PdfHeaderConstants.logoSize,
                  height: _PdfHeaderConstants.logoSize,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
