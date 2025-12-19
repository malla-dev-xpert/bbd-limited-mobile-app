/// Enum représentant les langues disponibles pour l'impression
enum PrintLanguage {
  french('fr', 'Français', '🇫🇷'),
  english('en', 'English', '🇬🇧'),
  chinese('zh', '中文', '🇨🇳');

  final String code;
  final String displayName;
  final String flag;

  const PrintLanguage(this.code, this.displayName, this.flag);

  /// Retourne la langue par défaut (français)
  static PrintLanguage get defaultLanguage => PrintLanguage.french;

  /// Convertit un code de langue en PrintLanguage
  static PrintLanguage fromCode(String code) {
    return PrintLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => PrintLanguage.french,
    );
  }
}
