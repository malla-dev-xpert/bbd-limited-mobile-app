import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageState {
  final Locale locale;
  final bool isLoading;

  const LanguageState({
    required this.locale,
    this.isLoading = true,
  });

  LanguageState copyWith({
    Locale? locale,
    bool? isLoading,
  }) {
    return LanguageState(
      locale: locale ?? this.locale,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LanguageNotifier extends StateNotifier<LanguageState> {
  static const String _languageKey = 'selected_language';

  LanguageNotifier() : super(const LanguageState(locale: Locale('fr'))) {
    _loadSavedLanguage();
  }

  Future<void> _detectSystemLanguage() async {
    final String? systemLanguage = await _getSystemLanguage();
    if (systemLanguage != null) {
      state = state.copyWith(
        locale: Locale(systemLanguage),
        isLoading: false,
      );
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
      state = state.copyWith(
        locale: Locale(savedLanguage),
        isLoading: false,
      );
    } else {
      // If no saved language, detect system language
      await _detectSystemLanguage();
    }
  }

  Future<void> setLanguage(String languageCode) async {
    state = state.copyWith(
      locale: Locale(languageCode),
      isLoading: false,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  String getCurrentLanguageName() {
    switch (state.locale.languageCode) {
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

// Provider pour Riverpod
final languageProvider =
    StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  return LanguageNotifier();
});
