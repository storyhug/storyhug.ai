import 'package:flutter/material.dart';

/// StoryHug.ai Brand Colors and Theme
/// Based on the official logo color palette
class StoryHugBranding {
  // Primary Brand Colors (from logo)
  static const Color primaryYellow = Color(0xFFFFD85A);  // Warm yellow from book
  static const Color secondaryPink = Color(0xFFFF8CB3);  // Playful pink from character
  static const Color accentBlue = Color(0xFF7EC8E3);     // Soft blue from background
  
  // Background Gradient Colors (from loginin.png - magical storybook theme)
  static const Color gradientStart = Color(0xFF5D5CFD);  // Deep twilight blue (top)
  static const Color gradientEnd = Color(0xFFFAD6C4);    // Soft peach (bottom)
  static const Color gradientMid = Color(0xFF8B7ED8);    // Purple-mid
  
  // Material 3 Theme Colors
  static const Color primary = Color(0xFFFFD85A);
  static const Color secondary = Color(0xFFFF8CB3);
  static const Color tertiary = Color(0xFF7EC8E3);
  
  // Text Colors (from loginin.png reference)
  static const Color textPrimary = Colors.white;         // White for readability
  static const Color textSecondary = Color(0xFFEDE7F6);  // Light purple-gray
  static const Color textLight = Colors.white;
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFFCE4EC);
  static const Color backgroundLightBlue = Color(0xFFE3F2FD);
  static const Color surface = Colors.white;
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);
  
  /// Main background gradient from loginin.png
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientEnd],
  );
  
  /// Card glassmorphism background (translucent with blur)
  static const Color cardGlassBackground = Color(0xFF6D62D8);
  
  /// Soft gradient for cards and surfaces
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF5F8),
      Color(0xFFF0F9FF),
    ],
  );
  
  /// Material 3 Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        surfaceContainerHighest: backgroundLight,
        onPrimary: textLight,
        onSecondary: textLight,
        onSurface: textPrimary,
        error: error,
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surface,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryPink,
        foregroundColor: textLight,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
    );
  }
  
  /// Animated gradient container widget
  static Widget gradientContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      decoration: const BoxDecoration(gradient: mainGradient),
      padding: padding,
      child: child,
    );
  }
  
  /// Logo asset path
  static const String logoPath = 'assets/branding/storyhug_logo.png';
  static const String logoTransparentPath = 'assets/branding/storyhug_logo_transparent.png';
  
  /// Brand animation durations
  static const Duration splashDuration = Duration(milliseconds: 1200);
  static const Duration fadeInDuration = Duration(milliseconds: 600);
  static const Duration scaleUpDuration = Duration(milliseconds: 800);
}

