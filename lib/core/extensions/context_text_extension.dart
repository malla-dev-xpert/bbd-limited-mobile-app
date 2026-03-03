import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/app_text_size.dart';

/// Extension on [BuildContext] for easy access to responsive text sizes and styles.
/// Usage: context.textSizes.caption, context.textSizes.bodyStyle()
extension ContextTextExtension on BuildContext {
  /// Access responsive text sizes and pre-built styles.
  AppTextSizeContext get textSizes => AppTextSizeContext(this);
}

/// Provides responsive text sizes and styles bound to a [BuildContext].
/// Use via [ContextTextExtension]: context.textSizes
class AppTextSizeContext {
  const AppTextSizeContext(this._context);
  final BuildContext _context;

  double get caption => AppTextSize.caption(_context);
  double get body => AppTextSize.body(_context);
  double get subtitle => AppTextSize.subtitle(_context);
  double get title => AppTextSize.title(_context);
  double get headline => AppTextSize.headline(_context);
  double get display => AppTextSize.display(_context);
  double get button => AppTextSize.button(_context);
  double get input => AppTextSize.input(_context);
  double get label => AppTextSize.label(_context);

  TextStyle captionStyle({Color? color}) =>
      AppTextSize.captionStyle(_context, color: color);
  TextStyle bodyStyle({Color? color, FontWeight? fontWeight}) =>
      AppTextSize.bodyStyle(_context, color: color, fontWeight: fontWeight);
  TextStyle subtitleStyle({Color? color, FontWeight? fontWeight}) =>
      AppTextSize.subtitleStyle(_context, color: color, fontWeight: fontWeight);
  TextStyle titleStyle({Color? color, FontWeight? fontWeight}) =>
      AppTextSize.titleStyle(_context, color: color, fontWeight: fontWeight);
  TextStyle headlineStyle({Color? color, FontWeight? fontWeight}) =>
      AppTextSize.headlineStyle(_context, color: color, fontWeight: fontWeight);
  TextStyle displayStyle({Color? color, FontWeight? fontWeight}) =>
      AppTextSize.displayStyle(_context, color: color, fontWeight: fontWeight);
  TextStyle buttonStyle({Color? color, FontWeight? fontWeight}) =>
      AppTextSize.buttonStyle(_context, color: color, fontWeight: fontWeight);
  TextStyle labelStyle({Color? color, FontWeight? fontWeight}) =>
      AppTextSize.labelStyle(_context, color: color, fontWeight: fontWeight);
}
