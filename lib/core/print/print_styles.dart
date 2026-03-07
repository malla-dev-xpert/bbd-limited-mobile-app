import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Styles centralisés pour l'impression PDF.
/// Garantit des documents professionnels, lisibles (A4 portrait),
/// avec contraste suffisant pour impression noir & blanc.
/// Ne modifie pas la logique métier.
class PrintStyles {
  PrintStyles._();

  // --- Format page ---
  /// Format cible pour l'impression (A4 portrait).
  static const PdfPageFormat pageFormat = PdfPageFormat.a4;

  /// Marge horizontale et verticale (points, ~24 pt ≈ 8 mm).
  static const double pageMargin = 24.0;

  /// Espacement vertical standard entre sections.
  static const double sectionSpacing = 16.0;

  /// Espacement entre lignes de tableau.
  static const double tableRowSpacing = 1.5;

  // --- Bordures et lignes (couleur et épaisseur uniques) ---
  /// Épaisseur des bordures de tableaux et lignes (identique partout).
  static const double tableBorderWidth = 0.8;

  /// Bordure complète pour tableaux (couleur + épaisseur unifiées).
  static pw.Border get tableBorder => pw.Border.all(
        color: tableBorderColor,
        width: tableBorderWidth,
      );

  /// Ligne horizontale (séparation entre lignes).
  static pw.BorderSide get tableBorderSide => pw.BorderSide(
        color: tableBorderColor,
        width: tableBorderWidth,
      );

  // --- Tableaux ---
  /// Padding interne des cellules (compact, bonne lisibilité).
  static const double cellPaddingH = 5.0;
  static const double cellPaddingV = 4.0;

  /// Hauteur minimale d'une ligne de tableau.
  static const double tableRowMinHeight = 18.0;

  /// Nombre max de lignes pour les textes longs (descriptions, commentaires).
  static const int maxLinesLongText = 5;

  /// Taille de police tableau (corps des cellules).
  static const double tableFontSize = 8.0;

  /// Taille de police en-tête de colonnes (légèrement plus grand que le corps).
  static const double tableHeaderFontSize = 8.5;

  /// Taille de police titres de section (ex: "Liste des articles").
  static const double sectionTitleFontSize = 14.0;

  /// Taille de police titre principal (ex: "Market Finance Invoice").
  static const double mainTitleFontSize = 18.0;

  /// Taille de police libellés (grille infos, sous-total/total).
  static const double labelFontSize = 9.0;

  /// Taille de police secondaire (frais, détails).
  static const double smallFontSize = 7.5;

  // --- Style Market Finance Invoice (vert menthe / teal) ---
  /// Couleur texte principale (noir pour contraste).
  static final PdfColor textColor = PdfColors.grey900;

  /// Vert menthe / teal clair pour en-têtes et libellés (#D9F2E7) - RGB explicite pour rendu PDF fiable et identique partout.
  static final PdfColor headerGreen = PdfColor(217 / 255, 242 / 255, 231 / 255);

  /// Couleur en-têtes de tableau (style Market Finance).
  static final PdfColor tableHeaderBackground = headerGreen;

  /// Couleur bordure tableau (lignes fines sombres).
  static final PdfColor tableBorderColor = PdfColors.grey800;

  /// Couleur fond lignes de données (blanc).
  static final PdfColor tableRowAltBackground = PdfColors.white;

  /// Couleur fond lignes de résumé (frais de travail, remises, etc.) - jaune très clair.
  static final PdfColor summaryRowBackground =
      PdfColor(255 / 255, 250 / 255, 230 / 255);

  /// Couleur de la ligne Sous-total (gris clair).
  static final PdfColor subtotalRowBackground =
      PdfColor(245 / 255, 245 / 255, 245 / 255);

  /// Couleur de la ligne Total (bleu très clair).
  static final PdfColor totalRowBackground =
      PdfColor(232 / 255, 240 / 255, 254 / 255);

  /// Couleur accent (titres, montants importants) - bleu/teal foncé (#1A1E49), RGB explicite.
  static final PdfColor accentColor = PdfColor(26 / 255, 30 / 255, 73 / 255);

  /// Style texte cellule (tableau).
  static pw.TextStyle cellTextStyle({double? fontSize}) => pw.TextStyle(
        fontSize: fontSize ?? tableFontSize,
        color: textColor,
      );

  /// Style en-tête de colonne de tableau.
  static pw.TextStyle tableHeaderStyle() => pw.TextStyle(
        fontSize: tableHeaderFontSize,
        fontWeight: pw.FontWeight.bold,
        color: accentColor,
      );

  /// Style titre de section (ex: "Liste des articles").
  static pw.TextStyle sectionTitleStyle() => pw.TextStyle(
        fontSize: sectionTitleFontSize,
        fontWeight: pw.FontWeight.bold,
        color: accentColor,
      );

  /// Style titre principal (ex: "Market Finance Invoice").
  static pw.TextStyle mainTitleStyle() => pw.TextStyle(
        fontSize: mainTitleFontSize,
        fontWeight: pw.FontWeight.bold,
        color: accentColor,
      );

  /// Style libellé (grille infos, sous-total).
  static pw.TextStyle labelStyle() => pw.TextStyle(
        fontSize: labelFontSize,
        fontWeight: pw.FontWeight.bold,
        color: textColor,
      );

  /// Style petit texte (frais, détails).
  static pw.TextStyle smallStyle() => pw.TextStyle(
        fontSize: smallFontSize,
        color: textColor,
      );
}
