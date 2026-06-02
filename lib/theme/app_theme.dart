import 'package:flutter/material.dart';

class AppTheme {
  // Cores principais
  static const Color destressBackground = Color(0xFF0D1B2A);
  static const Color destressPrimary = Color(0xFF4FC3F7);
  static const Color destressAccent = Color(0xFF80CBC4);
  static const Color destressCircle = Color(0xFF1A3A4A);

  static const Color focusBackground = Color(0xFF1A1200);
  static const Color focusPrimary = Color(0xFFFFB300);
  static const Color focusAccent = Color(0xFFFF8F00);
  static const Color focusCircle = Color(0xFF3A2800);

  static const Color homeBackground = Color(0xFF0A0A14);
  static const Color homePrimary = Color(0xFF9C89FF);
  static const Color homeAccent = Color(0xFF6C63FF);

  static const Color textPrimary = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFFB0B0C0);

  static ThemeData get theme => ThemeData(
        scaffoldBackgroundColor: homeBackground,
        fontFamily: 'sans-serif',
        colorScheme: const ColorScheme.dark(
          primary: homePrimary,
          secondary: homeAccent,
          surface: homeBackground,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
          displayMedium: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.5,
          ),
          bodyLarge: TextStyle(
            color: textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            color: textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      );
}