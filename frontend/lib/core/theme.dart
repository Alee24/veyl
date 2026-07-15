import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class AppTheme {
  // Light Theme Palette
  static const Color lightBg = Color(0xFFFAFAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF0F172A);
  static const Color lightAccent = Color(0xFF2563EB);
  static const Color lightSuccess = Color(0xFF10B981);
  static const Color lightWarning = Color(0xFFF59E0B);
  static const Color lightError = Color(0xFFEF4444);
  static const Color lightBorder = Color(0xFFE5E7EB);

  // Dark Theme Palette (Calm, Premium Slate/Navy)
  static const Color darkBg = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF161E2E);
  static const Color darkPrimary = Color(0xFFF1F5F9);
  static const Color darkAccent = Color(0xFF3B82F6);
  static const Color darkBorder = Color(0xFF1E293B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      cardColor: lightSurface,
      dividerColor: lightBorder,
      colorScheme: const ColorScheme.light(
        background: lightBg,
        surface: lightSurface,
        primary: lightPrimary,
        secondary: lightAccent,
        error: lightError,
      ),
      textTheme: GoogleFonts.manropeTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: lightPrimary, letterSpacing: -1.0),
          displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: lightPrimary, letterSpacing: -0.5),
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: lightPrimary),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: lightPrimary),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: lightPrimary),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: lightPrimary),
          labelSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: lightPrimary),
        titleTextStyle: TextStyle(
          color: lightPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightAccent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Colors.grey),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkSurface,
      dividerColor: darkBorder,
      colorScheme: const ColorScheme.dark(
        background: darkBg,
        surface: darkSurface,
        primary: darkPrimary,
        secondary: darkAccent,
        error: lightError,
      ),
      textTheme: GoogleFonts.manropeTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: darkPrimary, letterSpacing: -1.0),
          displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: darkPrimary, letterSpacing: -0.5),
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkPrimary),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkPrimary),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: darkPrimary),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: darkPrimary),
          labelSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkPrimary),
        titleTextStyle: TextStyle(
          color: darkPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkAccent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Colors.grey),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkBg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
