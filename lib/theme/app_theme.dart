import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const Color background = Color(0xFFF4F6F8);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color primaryBlue = Color(0xFF2563EB); // Elegant Blue
  static const Color successGreen = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color textMain = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);
  static const Color errorRed = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        surface: cardColor,
        primary: primaryBlue,
        onPrimary: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: textMain),
        bodyMedium: TextStyle(color: textMain),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
      iconTheme: const IconThemeData(color: textMuted),
      useMaterial3: true,
    );
  }
}
