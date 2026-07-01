import 'package:flutter/material.dart';

class AppTheme {
  // Temple color palette
  static const Color saffron = Color(0xFFFF6B00);
  static const Color darkOrange = Color(0xFFCC4400);
  static const Color gold = Color(0xFFD4A017);
  static const Color cream = Color(0xFFFFF8F0);
  static const Color lightOrange = Color(0xFFFFE0B2);
  static const Color dark = Color(0xFF1A1A1A);
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color cardBg = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: saffron,
        primary: saffron,
        secondary: gold,
        surface: cardBg,
        background: cream,
      ),
      fontFamily: 'NotoSansTamil',
      appBarTheme: const AppBarTheme(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: saffron,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkOrange,
          side: const BorderSide(color: saffron, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: saffron, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
        color: cardBg,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(lightOrange),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, color: darkOrange, fontSize: 13),
        dataRowColor: WidgetStateProperty.all(Colors.white),
        dividerThickness: 0.5,
      ),
    );
  }

  static BoxDecoration get goldGradient => const BoxDecoration(
        gradient: LinearGradient(
          colors: [saffron, darkOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
}