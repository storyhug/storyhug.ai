import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // StoryHug.ai Magic Night-Sky Theme (from loginin.png)
  static const Color primaryColor = Color(0xFFFFD85A); // Warm yellow
  static const Color secondaryColor = Color(0xFFFF8CB3); // Playful pink
  static const Color surfaceColor = Color(0xFF1C1C1C); // Dark gray
  static const Color accentColor = Color(0xFFFFD85A); // Yellow accent
  static const Color textColor = Color(0xFFFFFFFF); // White
  static const Color backgroundColor = Color(0xFF87CEEB); // Light blue
  
  // Magic Night-Sky Gradient Colors (from loginin.png)
  static const Color gradientTop = Color(0xFF5D5CFD); // Deep twilight blue
  static const Color gradientBottom = Color(0xFFFAD6C4); // Soft peach
  
  // Glass morphism colors
  static const Color glassCard = Color(0xFF6D62D8); // Translucent purple
  static const Color cardColor = Color(0xFF6D62D8); // Glass card color
  static const Color dividerColor = Color(0xFF404040);
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF4CAF50);
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: surfaceColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        onSurface: textColor,
        error: errorColor,
        onError: textColor,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        TextTheme(
          // Story titles: Poppins 22sp - warm and playful
          displayLarge: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: -0.5,
          ),
          displayMedium: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: -0.5,
          ),
          displaySmall: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          headlineLarge: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          headlineSmall: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          // Body text: Poppins 16sp - soft and readable
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            color: textColor,
            height: 1.5,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            color: textColor.withOpacity(0.9),
            height: 1.5,
          ),
          bodySmall: GoogleFonts.poppins(
            fontSize: 12,
            color: textColor.withOpacity(0.7),
          ),
          // Buttons: Poppins 14sp - rounded and friendly
          labelLarge: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: 0.5,
          ),
          labelMedium: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black87,
          elevation: 6,
          shadowColor: primaryColor.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // Increased from 12 to 24
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Increased from 12 to 24 for softer look
        ),
        elevation: 0, // Using shadows from decoration instead
        margin: const EdgeInsets.all(8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: const Color(0xFFA9A9A9)),
        hintStyle: GoogleFonts.poppins(color: const Color(0xFFA9A9A9)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: textColor,
        size: 24,
      ),
      // Rounded icon style
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  // Magic Night-Sky Gradient Background (from loginin.png)
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientTop, gradientBottom],
  );
  
  // Glass card gradient
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6D62D8), // Translucent purple
      Color(0xFF8B7ED8), // Lighter purple
    ],
  );
  
  // Glass morphism decoration for cards
  static BoxDecoration glassCardDecoration = BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: Colors.white.withOpacity(0.2),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 30,
        offset: const Offset(0, 15),
      ),
    ],
  );
}
