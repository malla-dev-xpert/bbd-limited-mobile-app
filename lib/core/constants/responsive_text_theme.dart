import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/app_text_size.dart';

/// Builds a [TextTheme] that uses [AppTextSize] for all font sizes.
/// Use in ThemeData so that Theme.of(context).textTheme is responsive (tablet = larger).
/// Compatible with ThemeData; inject via MaterialApp builder.
TextTheme buildResponsiveTextTheme(BuildContext context, ColorScheme colorScheme) {
  final color = colorScheme.onSurface;
  final secondary = colorScheme.onSurfaceVariant;
  return TextTheme(
    displayLarge: TextStyle(
      fontSize: AppTextSize.display(context),
      fontWeight: FontWeight.bold,
      color: color,
    ),
    displayMedium: TextStyle(
      fontSize: AppTextSize.headline(context),
      fontWeight: FontWeight.bold,
      color: color,
    ),
    displaySmall: TextStyle(
      fontSize: AppTextSize.headline(context),
      fontWeight: FontWeight.w600,
      color: color,
    ),
    headlineLarge: TextStyle(
      fontSize: AppTextSize.headline(context),
      fontWeight: FontWeight.bold,
      color: color,
    ),
    headlineMedium: TextStyle(
      fontSize: AppTextSize.title(context),
      fontWeight: FontWeight.bold,
      color: color,
    ),
    headlineSmall: TextStyle(
      fontSize: AppTextSize.title(context),
      fontWeight: FontWeight.w600,
      color: color,
    ),
    titleLarge: TextStyle(
      fontSize: AppTextSize.title(context),
      fontWeight: FontWeight.bold,
      color: color,
    ),
    titleMedium: TextStyle(
      fontSize: AppTextSize.subtitle(context),
      fontWeight: FontWeight.w600,
      color: color,
    ),
    titleSmall: TextStyle(
      fontSize: AppTextSize.subtitle(context),
      fontWeight: FontWeight.w500,
      color: color,
    ),
    bodyLarge: TextStyle(
      fontSize: AppTextSize.body(context),
      fontWeight: FontWeight.normal,
      color: color,
    ),
    bodyMedium: TextStyle(
      fontSize: AppTextSize.body(context),
      fontWeight: FontWeight.normal,
      color: color,
    ),
    bodySmall: TextStyle(
      fontSize: AppTextSize.caption(context),
      fontWeight: FontWeight.normal,
      color: secondary,
    ),
    labelLarge: TextStyle(
      fontSize: AppTextSize.button(context),
      fontWeight: FontWeight.w600,
      color: color,
    ),
    labelMedium: TextStyle(
      fontSize: AppTextSize.body(context),
      fontWeight: FontWeight.w500,
      color: color,
    ),
    labelSmall: TextStyle(
      fontSize: AppTextSize.caption(context),
      fontWeight: FontWeight.w500,
      color: secondary,
    ),
  );
}
