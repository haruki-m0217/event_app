import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6B4EE6),
    brightness: Brightness.light,
    primary: const Color(0xFF6B4EE6),
    secondary: const Color(0xFFFF529F),
    tertiary: const Color(0xFF38B2AC),
    surface: Colors.white,
  ),
  textTheme: GoogleFonts.notoSansJpTextTheme().copyWith(
    displayLarge: GoogleFonts.notoSansJp(fontWeight: FontWeight.bold),
    displayMedium: GoogleFonts.notoSansJp(fontWeight: FontWeight.bold),
    displaySmall: GoogleFonts.notoSansJp(fontWeight: FontWeight.w600),
    titleLarge: GoogleFonts.notoSansJp(fontWeight: FontWeight.bold),
    bodyLarge: GoogleFonts.notoSansJp(fontWeight: FontWeight.w500),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFF1D1D23),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFF6B4EE6),
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.notoSansJp(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    color: Colors.white,
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF6B4EE6), width: 2),
    ),
    contentPadding: const EdgeInsets.all(16),
  ),
);
