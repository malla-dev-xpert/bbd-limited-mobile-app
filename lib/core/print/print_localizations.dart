import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/print/print_language.dart';

/// Service centralisé pour gérer les traductions d'impression
/// Permet de choisir dynamiquement la langue d'impression indépendamment de la langue de l'application
class PrintLocalizations {
  final PrintLanguage language;
  Map<String, String> _localizedStrings = {};

  PrintLocalizations(this.language);

  /// Accès à la langue pour compatibilité avec le code existant
  Locale get locale => Locale(language.code);

  /// Charge les traductions pour la langue d'impression spécifiée
  Future<bool> load() async {
    try {
      String jsonString = await rootBundle
          .loadString('assets/translations/${language.code}.json');

      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings =
          jsonMap.map((key, value) => MapEntry(key, value.toString()));

      return true;
    } catch (e) {
      print('Error loading print translations for ${language.code}: $e');
      // En cas d'erreur, on charge les traductions par défaut (français)
      if (language.code != 'fr') {
        try {
          String jsonString =
              await rootBundle.loadString('assets/translations/fr.json');

          Map<String, dynamic> jsonMap = json.decode(jsonString);
          _localizedStrings =
              jsonMap.map((key, value) => MapEntry(key, value.toString()));

          return true;
        } catch (fallbackError) {
          print('Error loading fallback print translations: $fallbackError');
          return false;
        }
      }
      return false;
    }
  }

  /// Traduit une clé de traduction
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  /// Crée une instance de PrintLocalizations avec la langue par défaut
  static Future<PrintLocalizations> createDefault() async {
    final localizations = PrintLocalizations(PrintLanguage.defaultLanguage);
    await localizations.load();
    return localizations;
  }

  /// Crée une instance de PrintLocalizations avec une langue spécifique
  static Future<PrintLocalizations> create(PrintLanguage language) async {
    final localizations = PrintLocalizations(language);
    await localizations.load();
    return localizations;
  }
}
