import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Map<String, String> _localizedStrings = {};

  Future<bool> load() async {
    try {
      String jsonString = await rootBundle
          .loadString('assets/translations/${locale.languageCode}.json');

      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings =
          jsonMap.map((key, value) => MapEntry(key, value.toString()));

      return true;
    } catch (e) {
      print('Error loading translations for ${locale.languageCode}: $e');
      // En cas d'erreur, on charge les traductions par défaut (français)
      if (locale.languageCode != 'fr') {
        try {
          String jsonString =
              await rootBundle.loadString('assets/translations/fr.json');

          Map<String, dynamic> jsonMap = json.decode(jsonString);
          _localizedStrings =
              jsonMap.map((key, value) => MapEntry(key, value.toString()));

          return true;
        } catch (fallbackError) {
          print('Error loading fallback translations: $fallbackError');
          return false;
        }
      }
      return false;
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['fr', 'en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
