import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/device_breakpoints.dart';

/// Global spacing constants based on an 8pt grid.
/// Use these everywhere — no hardcoded spacing in UI.
/// Values scale on tablet for better readability.
abstract final class AppSpacing {
  AppSpacing._();

  // Base grid (8pt)
  static const double _base = 4.0;
  static const double _base8 = 8.0;

  /// 4
  static const double xs = _base;

  /// 8
  static const double sm = _base8;

  /// 12
  static const double md = 12.0;

  /// 16
  static const double lg = 16.0;

  /// 24
  static const double xl = 24.0;

  /// 32
  static const double xxl = 32.0;

  /// 40 (e.g. FAB displacement, large gaps)
  static const double xxxl = 40.0;

  /// Returns spacing value; on tablet multiplies by [tabletScale] for larger gaps.
  static double of(BuildContext context, {double tabletScale = 1.25}) {
    if (DeviceBreakpoints.isTablet(context)) {
      return _base8 * tabletScale; // default scale for generic "of"
    }
    return _base8;
  }

  /// xs as EdgeInsets
  static EdgeInsets get paddingXs => const EdgeInsets.all(xs);

  /// sm as EdgeInsets
  static EdgeInsets get paddingSm => const EdgeInsets.all(sm);

  /// md as EdgeInsets
  static EdgeInsets get paddingMd => const EdgeInsets.all(md);

  /// lg as EdgeInsets
  static EdgeInsets get paddingLg => const EdgeInsets.all(lg);

  /// xl as EdgeInsets
  static EdgeInsets get paddingXl => const EdgeInsets.all(xl);

  /// xxl as EdgeInsets
  static EdgeInsets get paddingXxl => const EdgeInsets.all(xxl);

  /// Horizontal padding for screen content (responsive).
  static EdgeInsets horizontal(BuildContext context) {
    final base = DeviceBreakpoints.isTablet(context) ? xl : lg;
    return EdgeInsets.symmetric(horizontal: base);
  }

  /// Vertical padding for screen content (responsive).
  static EdgeInsets vertical(BuildContext context) {
    final base = DeviceBreakpoints.isTablet(context) ? xl : lg;
    return EdgeInsets.symmetric(vertical: base);
  }

  /// All-around screen padding (responsive).
  static EdgeInsets screen(BuildContext context) {
    final base = DeviceBreakpoints.isTablet(context) ? xl : lg;
    return EdgeInsets.all(base);
  }
}
