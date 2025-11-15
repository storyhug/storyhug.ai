import 'package:flutter/material.dart';

class Responsive {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1000;

  // Screen size helpers
  static Size screenSize(BuildContext context) => MediaQuery.of(context).size;
  static double screenWidth(BuildContext context) => screenSize(context).width;
  static double screenHeight(BuildContext context) =>
      screenSize(context).height;

  // Breakpoint checks
  static bool isMobile(BuildContext context) =>
      screenWidth(context) < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= mobileBreakpoint &&
      screenWidth(context) < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      screenWidth(context) >= tabletBreakpoint;

  // Legacy compatibility
  static bool isLargeTablet(BuildContext context) => isDesktop(context);

  // Width/Height fractions with constraints
  static double widthFraction(
    BuildContext context,
    double fraction, {
    double min = 0,
    double? max,
  }) {
    final w = screenWidth(context) * fraction;
    final clampedMin = w < min ? min : w;
    if (max != null && clampedMin > max) return max;
    return clampedMin;
  }

  static double heightFraction(
    BuildContext context,
    double fraction, {
    double min = 0,
    double? max,
  }) {
    final h = screenHeight(context) * fraction;
    final clampedMin = h < min ? min : h;
    if (max != null && clampedMin > max) return max;
    return clampedMin;
  }

  // Responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 64, vertical: 32);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 64);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32);
    }
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  static EdgeInsets responsiveVerticalPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(vertical: 32);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(vertical: 24);
    }
    return const EdgeInsets.symmetric(vertical: 16);
  }

  // Responsive spacing
  static double spacingSmall(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 6;
    if (w < 400) return 8;
    if (isDesktop(context)) return 12;
    if (isTablet(context)) return 10;
    return 8;
  }

  static double spacingMedium(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 12;
    if (w < 400) return 16;
    if (isDesktop(context)) return 32;
    if (isTablet(context)) return 24;
    return 16;
  }

  static double spacingLarge(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 16;
    if (w < 400) return 24;
    if (isDesktop(context)) return 48;
    if (isTablet(context)) return 40;
    return 24;
  }

  // Responsive font sizes
  static double responsiveFontSize(
    BuildContext context,
    double mobile,
    double tablet,
    double desktop,
  ) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  // Grid cross-axis count
  static int gridCrossAxisCount(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 4,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  // Card width factor
  static double cardWidthFactor(BuildContext context) {
    if (isDesktop(context)) return 0.55;
    if (isTablet(context)) return 0.7;
    return 0.88;
  }

  // Max content width (for centering on large screens)
  static double maxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 800;
    return double.infinity;
  }

  // Logo sizing
  static double logoSize(BuildContext context) {
    final w = screenWidth(context);
    final h = screenHeight(context);
    final aspect = h / w;
    final baseFraction = aspect >= 2.0 ? 0.32 : (aspect > 1.6 ? 0.3 : 0.28);
    return widthFraction(
      context,
      baseFraction,
      min: 96,
      max: isDesktop(context) ? 280 : 200,
    );
  }

  // Child aspect ratio for grids
  static double gridChildAspectRatio(BuildContext context) {
    if (isDesktop(context)) return 1.2;
    if (isTablet(context)) return 1.0;
    return 0.9;
  }
}
