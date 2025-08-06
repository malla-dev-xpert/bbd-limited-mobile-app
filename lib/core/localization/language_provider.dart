import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  Locale _currentLocale = const Locale('fr');

  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _detectSystemLanguage() async {
    final String? systemLanguage = await _getSystemLanguage();
    if (systemLanguage != null) {
      _currentLocale = Locale(systemLanguage);
      notifyListeners();
    }
  }

  Future<String?> _getSystemLanguage() async {
    try {
      const platform = MethodChannel('flutter/language');
      final String? language = await platform.invokeMethod('getLanguage');
      return language;
    } catch (e) {
      // Fallback to device locale
      final String deviceLocale =
          WidgetsBinding.instance.window.locale.languageCode;
      if (['fr', 'en', 'zh'].contains(deviceLocale)) {
        return deviceLocale;
      }
      return 'fr'; // Default to French
    }
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);
    if (savedLanguage != null) {
      _currentLocale = Locale(savedLanguage);
      notifyListeners();
    } else {
      // If no saved language, detect system language
      await _detectSystemLanguage();
    }
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }

  String getCurrentLanguageName() {
    switch (_currentLocale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      default:
        return 'Français';
    }
  }

  List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'fr', 'name': 'Français', 'nativeName': 'Français'},
      {'code': 'en', 'name': 'English', 'nativeName': 'English'},
      {'code': 'zh', 'name': 'Chinese', 'nativeName': '中文'},
    ];
  }
}
