import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/device_breakpoints.dart';

/// Responsive typography: sizes adapt to mobile vs tablet via breakpoints.
/// On tablet: minimum 18px for readability, all sizes scaled proportionally.
/// Use with: TextStyle(fontSize: AppTextSize.title(context))
/// No hardcoded font sizes in UI — use this or Theme extensions.
abstract final class AppTextSize {
  AppTextSize._();

  /// Minimum font size on tablet (exigence fonctionnelle).
  static const double tabletMinSize = 16.0;

  // --- Mobile sizes (unchanged) ---
  static const double _captionMobile = 11.0;
  static const double _bodyMobile = 14.0;
  static const double _subtitleMobile = 16.0;
  static const double _titleMobile = 18.0;
  static const double _headlineMobile = 22.0;
  static const double _displayMobile = 28.0;

  // --- Tablet sizes: min 18px + proportional scale (caption→body→subtitle→title→headline) ---
  static const double _captionTablet = 16.0; // minimum
  static const double _bodyTablet = 20.0; // 18 * (14/11)
  static const double _subtitleTablet = 22.0; // 18 * (16/11)
  static const double _titleTablet = 24.0; // 18 * (18/11)
  static const double _headlineTablet = 28.0; // 18 * (22/11)
  static const double _displayTablet = 30.0;

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

  /// Large display/hero text (e.g. login welcome).
  static double display(BuildContext context) =>
      _size(context, _displayMobile, _displayTablet);

  /// Button text: same as body.
  static double button(BuildContext context) => body(context);

  /// Input/label text: same as body.
  static double input(BuildContext context) => body(context);

  static double label(BuildContext context) => body(context);

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

  static TextStyle displayStyle(BuildContext context,
      {Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: display(context),
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color ?? Theme.of(context).textTheme.headlineMedium?.color,
    );
  }

  static TextStyle buttonStyle(BuildContext context,
      {Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: button(context),
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color ?? Theme.of(context).textTheme.labelLarge?.color,
    );
  }

  static TextStyle labelStyle(BuildContext context,
      {Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: label(context),
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
    );
  }
}
