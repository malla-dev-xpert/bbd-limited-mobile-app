import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/device_breakpoints.dart';

/// Responsive typography: sizes adapt to mobile vs tablet via breakpoints.
/// Use with: TextStyle(fontSize: AppTextSize.title(context))
/// No hardcoded font sizes in UI — use this or Theme extensions.
abstract final class AppTextSize {
  AppTextSize._();

  // Mobile sizes
  static const double _captionMobile = 11.0;
  static const double _bodyMobile = 14.0;
  static const double _subtitleMobile = 16.0;
  static const double _titleMobile = 18.0;
  static const double _headlineMobile = 22.0;

  // Tablet sizes (increased for readability)
  static const double _captionTablet = 12.0;
  static const double _bodyTablet = 15.0;
  static const double _subtitleTablet = 17.0;
  static const double _titleTablet = 20.0;
  static const double _headlineTablet = 26.0;

  static double _size(BuildContext context, double mobile, double tablet) {
    return DeviceBreakpoints.isTablet(context) ? tablet : mobile;
  }

  static double caption(BuildContext context) =>
      _size(context, _captionMobile, _captionTablet);

  static double body(BuildContext context) =>
      _size(context, _bodyMobile, _bodyTablet);

  static double subtitle(BuildContext context) =>
      _size(context, _subtitleMobile, _subtitleTablet);

  static double title(BuildContext context) =>
      _size(context, _titleMobile, _titleTablet);

  static double headline(BuildContext context) =>
      _size(context, _headlineMobile, _headlineTablet);

  /// Pre-built TextStyle helpers (optional; can use with Theme.textTheme too).
  static TextStyle captionStyle(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: caption(context),
      color: color ?? Theme.of(context).textTheme.bodySmall?.color,
    );
  }

  static TextStyle bodyStyle(BuildContext context,
      {Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: body(context),
      color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
      fontWeight: fontWeight,
    );
  }

  static TextStyle subtitleStyle(BuildContext context,
      {Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: subtitle(context),
      color: color ?? Theme.of(context).textTheme.titleSmall?.color,
      fontWeight: fontWeight ?? FontWeight.w500,
    );
  }

  static TextStyle titleStyle(BuildContext context,
      {Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: title(context),
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color ?? Theme.of(context).textTheme.titleMedium?.color,
    );
  }

  static TextStyle headlineStyle(BuildContext context,
      {Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: headline(context),
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color ?? Theme.of(context).textTheme.headlineSmall?.color,
    );
  }
}
