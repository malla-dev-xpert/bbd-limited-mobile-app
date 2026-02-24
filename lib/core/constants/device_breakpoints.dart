import 'package:flutter/material.dart';

/// Centralized device breakpoints for responsive layout.
/// No responsive logic should be duplicated across screens — use these values.
abstract final class DeviceBreakpoints {
  DeviceBreakpoints._();

  /// Mobile: width < 600
  static const double mobileMax = 600;

  /// Tablet: 600 <= width < 900
  static const double tabletMin = 600;
  static const double tabletMax = 900;

  /// Large tablet / desktop: width >= 900 (extensible for future)
  static const double largeTabletMin = 900;

  /// Returns true if the current device is considered a tablet (shortest side or width).
  static bool isTablet(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final shortestSide = media.size.shortestSide;
    return width >= tabletMin || shortestSide >= tabletMin;
  }

  /// Returns true if the current device is large tablet or desktop.
  static bool isLargeTabletOrDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeTabletMin;
  }

  /// Returns true if the current device is mobile.
  static bool isMobile(BuildContext context) {
    return !isTablet(context);
  }

  /// Device type enum for explicit branching when needed.
  static DeviceType deviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= largeTabletMin) return DeviceType.largeTablet;
    if (width >= tabletMin) return DeviceType.tablet;
    return DeviceType.mobile;
  }
}

enum DeviceType {
  mobile,
  tablet,
  largeTablet,
}
