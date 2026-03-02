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
  static const double tableRowSpacing = 2.0;

  // --- Tableaux ---
  /// Padding interne des cellules (évite chevauchement, améliore lisibilité).
  static const double cellPaddingH = 6.0;
  static const double cellPaddingV = 5.0;

  /// Hauteur minimale d'une ligne de tableau (pour texte multi-lignes).
  static const double tableRowMinHeight = 20.0;

  /// Nombre max de lignes pour les textes longs (descriptions, commentaires).
  static const int maxLinesLongText = 5;

  /// Taille de police tableau (lisible N&B).
  static const double tableFontSize = 9.0;

  /// Taille de police en-tête de section.
  static const double sectionTitleFontSize = 12.0;

  // --- Contraste noir & blanc ---
  /// Couleur texte principale (noir pour contraste).
  static final PdfColor textColor = PdfColors.grey900;

  /// Couleur en-têtes de tableau (fond gris moyen pour contraste).
  static final PdfColor tableHeaderBackground = PdfColors.grey300;

  /// Couleur bordure tableau (noir pour netteté).
  static final PdfColor tableBorderColor = PdfColors.grey800;

  /// Couleur fond lignes alternées (optionnel, léger gris).
  static final PdfColor tableRowAltBackground = PdfColors.grey100;

  /// Couleur de la ligne Sous-total (jaune léger avec opacité réduite).
  static final PdfColor subtotalRowBackground =
      PdfColor(1.0, 1.0, 0.85, 0.85);

  /// Couleur de la ligne Total (vert).
  static final PdfColor totalRowBackground =
      PdfColor(0.65, 0.84, 0.65); // vert clair type #A5D6A7

  /// Couleur accent (titres, montants importants) - reste lisible en N&B.
  static final PdfColor accentColor = PdfColors.grey900;

  /// Style texte cellule avec retour à la ligne implicite (pas de débordement).
  static pw.TextStyle cellTextStyle({double fontSize = tableFontSize}) =>
      pw.TextStyle(
        fontSize: fontSize,
        color: textColor,
      );

  /// Style en-tête de section.
  static pw.TextStyle sectionTitleStyle() => pw.TextStyle(
        fontSize: sectionTitleFontSize,
        fontWeight: pw.FontWeight.bold,
        color: accentColor,
      );
}
