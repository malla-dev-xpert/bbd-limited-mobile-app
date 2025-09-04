import 'package:flutter/material.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class TranslationHelper {
  static String t(BuildContext context, String key) {
    return AppLocalizations.of(context).translate(key);
  }

  static String tWithParams(
      BuildContext context, String key, Map<String, String> params) {
    String translation = AppLocalizations.of(context).translate(key);

    params.forEach((paramKey, paramValue) {
      translation = translation.replaceAll('{$paramKey}', paramValue);
    });

    return translation;
  }
}
