import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF0B0F0E);
  static const surface = Color(0xFF19221F);
  static const elevated = Color(0xFF19221F);
  static const lime = Color(0xFFC6F277);
  static const text = Color(0xFFE8EEE9);
  static const secondaryText = Color(0xFF9DA9A0);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: lime,
        onPrimary: background,
        secondary: lime,
        surface: surface,
        onSurface: text,
        error: text,
        onError: background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: surface,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: elevated),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lime,
          foregroundColor: background,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: secondaryText),
      ),
    );
  }
}
