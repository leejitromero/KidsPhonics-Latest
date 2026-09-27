import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Shared learner UI values; the existing brand accents remain unchanged.
abstract final class KidsUi {
  static const space = 8.0, gap = 12.0, padding = 16.0, section = 24.0;
  static const radius = 20.0, buttonHeight = 56.0;
  static const titleSize = 24.0, bodySize = 18.0, answerSize = 22.0;
  static const background = Color(0xFFF7F5FF);
  static const ink = Color(0xFF30214F);
  static const muted = Color(0xFF655677);
  static const correct = AppColors.tealDark;
  static const incorrect = Color(0xFFAD3B52);
  static ThemeData get theme => ThemeData(
        fontFamily: 'Nunito',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.purple,
            primary: const Color(0xFF7052CA),
            secondary: AppColors.tealDark),
        scaffoldBackgroundColor: background,
        textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: bodySize, color: ink),
            bodyLarge: TextStyle(fontSize: bodySize, color: ink)),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, buttonHeight),
                textStyle: const TextStyle(fontSize: bodySize),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)))),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, buttonHeight),
                textStyle: const TextStyle(fontSize: bodySize),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)))),
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                textStyle: const TextStyle(fontSize: bodySize))),
      );
}
