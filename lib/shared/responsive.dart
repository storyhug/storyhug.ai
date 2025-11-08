import 'package:flutter/material.dart';

class Responsive {
  static Size screenSize(BuildContext context) => MediaQuery.of(context).size;
  static double screenWidth(BuildContext context) => screenSize(context).width;
  static double screenHeight(BuildContext context) => screenSize(context).height;

  static bool isTablet(BuildContext context) => screenWidth(context) >= 600;
  static bool isLargeTablet(BuildContext context) => screenWidth(context) >= 900;

  static double widthFraction(BuildContext context, double fraction, {double min = 0, double? max}) {
    final w = screenWidth(context) * fraction;
    final clampedMin = w < min ? min : w;
    if (max != null && clampedMin > max) return max;
    return clampedMin;
  }

  static double heightFraction(BuildContext context, double fraction, {double min = 0, double? max}) {
    final h = screenHeight(context) * fraction;
    final clampedMin = h < min ? min : h;
    if (max != null && clampedMin > max) return max;
    return clampedMin;
  }

  // Logo sizing: aim for 0.28–0.35 of screen width, with clamps
  static double logoSize(BuildContext context) {
    final w = screenWidth(context);
    final h = screenHeight(context);
    final aspect = h / w; // taller screens have bigger aspect
    final baseFraction = aspect >= 2.0 ? 0.32 : (aspect > 1.6 ? 0.3 : 0.28);
    return widthFraction(context, baseFraction, min: 96, max: isLargeTablet(context) ? 280 : 200);
  }

  // Spacing scale: small phones <360dp tighter, tablets looser
  static double spacingSmall(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 6;
    if (w < 400) return 8;
    if (isTablet(context)) return 10;
    return 8;
  }

  static double spacingMedium(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 12;
    if (w < 400) return 16;
    if (isLargeTablet(context)) return 24;
    if (isTablet(context)) return 20;
    return 16;
  }

  static double spacingLarge(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 16;
    if (w < 400) return 24;
    if (isLargeTablet(context)) return 40;
    if (isTablet(context)) return 32;
    return 24;
  }

  // Card width factor: 0.88 on phones, 0.7 on tablets, 0.55 on large tablets
  static double cardWidthFactor(BuildContext context) {
    if (isLargeTablet(context)) return 0.55;
    if (isTablet(context)) return 0.7;
    return 0.88;
  }
}

