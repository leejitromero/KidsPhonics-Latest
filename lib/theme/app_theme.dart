// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Background
  static const darkBg = Color(0xFF0F0A2E);
  static const darkBg2 = Color(0xFF1B0A4F);
  static const darkBg3 = Color(0xFF071530);

  // Accent
  static const gold = Color(0xFFFFD700);
  static const pink = Color(0xFFFF6B9D);
  static const teal = Color(0xFF00BFA5);
  static const tealDark = Color(0xFF007A6A);
  static const purple = Color(0xFF6A1B9A);
  static const purpleDark = Color(0xFF4A148C);
  static const blue = Color(0xFF1565C0);
  static const blueDark = Color(0xFF0D47A1);
  static const green = Color(0xFF2E7D32);
  static const greenDark = Color(0xFF1B5E20);
  static const orange = Color(0xFFF9A825);
  static const orangeDark = Color(0xFFE65100);

  // Text
  static const textLight = Color(0xFFE0D0FF);
  static const textMuted = Color(0xFF9B6FC4);
  static const textDim = Color(0xFF6A3FA0);

  // Status
  static const correct = Color(0xFF00C9A7);
  static const wrong = Color(0xFFFF4757);
  static const star = Color(0xFFFFD700);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.teal,
          surface: AppColors.darkBg,
        ),
        scaffoldBackgroundColor: AppColors.darkBg,
        textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      );
}

// Text styles
class AppText {
  static TextStyle fredoka(double size, Color color,
          {FontWeight weight = FontWeight.normal}) =>
      GoogleFonts.fredoka(fontSize: size, color: color);

  static TextStyle nunito(double size, Color color,
          {FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.nunito(fontSize: size, color: color, fontWeight: weight);
}
