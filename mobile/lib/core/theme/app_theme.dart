import 'package:flutter/material.dart';

/// Cores do tema RHEMA - Baseado no modelo-app
class RhemaColors {
  // Paleta principal - Tons terrosos e sofisticados
  static const Color primary50 = Color(0xFFF7F6F4);   // Warm off-white
  static const Color primary100 = Color(0xFFEBE9E4);
  static const Color primary200 = Color(0xFFD6D1C7);
  static const Color primary300 = Color(0xFFBDB6A8);
  static const Color primary400 = Color(0xFF9E9584);  // Earthy muted
  static const Color primary500 = Color(0xFF857B67);
  static const Color primary600 = Color(0xFF6B6252);
  static const Color primary700 = Color(0xFF544D41);
  static const Color primary800 = Color(0xFF3D382F);
  static const Color primary900 = Color(0xFF29251F);
  
  // Dourado premium
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE6C866);
  static const Color goldDark = Color(0xFFB8960E);
  
  // Cores de feedback
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Cores do feed (modo escuro)
  static const Color feedBackground = Color(0xFF000000);
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color surfaceDark = Color(0xFF121212);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: RhemaColors.primary800,
      scaffoldBackgroundColor: RhemaColors.primary50,
      colorScheme: const ColorScheme.light(
        primary: RhemaColors.primary800,
        secondary: RhemaColors.gold,
        surface: RhemaColors.primary50,
        surfaceContainerLowest: RhemaColors.primary50,
        error: RhemaColors.error,
        onPrimary: Colors.white,
        onSecondary: RhemaColors.primary900,
        onSurface: RhemaColors.primary900,
      ),
      textTheme: _textTheme(isLight: true),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: RhemaColors.primary800),
        titleTextStyle: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: RhemaColors.primary800,
          fontStyle: FontStyle.italic,
        ),
      ),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      inputDecorationTheme: _inputDecorationTheme(),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: RhemaColors.gold,
      scaffoldBackgroundColor: RhemaColors.feedBackground,
      colorScheme: const ColorScheme.dark(
        primary: RhemaColors.gold,
        secondary: RhemaColors.primary300,
        surface: RhemaColors.cardBackground,
        surfaceContainerLowest: RhemaColors.feedBackground,
        error: RhemaColors.error,
        onPrimary: RhemaColors.primary900,
        onSecondary: RhemaColors.primary900,
        onSurface: Colors.white,
      ),
      textTheme: _textTheme(isLight: false),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontStyle: FontStyle.italic,
        ),
      ),
      elevatedButtonTheme: _elevatedButtonThemeDark(),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: RhemaColors.surfaceDark,
        selectedItemColor: RhemaColors.gold,
        unselectedItemColor: RhemaColors.primary400,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: RhemaColors.cardBackground,
      ),
    );
  }

  static TextTheme _textTheme({required bool isLight}) {
    final color = isLight ? RhemaColors.primary900 : Colors.white;
    final mutedColor = isLight ? RhemaColors.primary600 : RhemaColors.primary300;
    
    return TextTheme(
      // Display - Playfair Display (Serif)
      displayLarge: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 48,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: color,
      ),
      displayMedium: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 36,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: color,
      ),
      displaySmall: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: color,
      ),
      // Headlines
      headlineLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      // Titles
      titleLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      titleSmall: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      // Body
      bodyLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodySmall: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedColor,
      ),
      // Labels
      labelLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: color,
      ),
      labelMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: mutedColor,
      ),
      labelSmall: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.0,
        color: mutedColor,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: RhemaColors.primary800,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonThemeDark() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: RhemaColors.gold,
        foregroundColor: RhemaColors.primary900,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RhemaColors.primary800,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: RhemaColors.primary300),
        textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RhemaColors.primary200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RhemaColors.primary200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RhemaColors.primary800, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RhemaColors.error),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        color: RhemaColors.primary400,
      ),
    );
  }
}
