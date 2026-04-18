import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color accent = Color(0xFF6366F1);
  static const Color coral = Color(0xFFEF6461);
  static const Color amber = Color(0xFFF59E0B);
  static const Color green = Color(0xFF22C55E);
  static const Color sky = Color(0xFF0EA5E9);
  static const Color pink = Color(0xFFEC4899);
  static const Color orange = Color(0xFFF97316);

  static const Color bg = Color(0xFFF6F8FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF111827);
  static const Color textSec = Color(0xFF6B7280);
  static const Color textMut = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color surface = Color(0xFFF3F4F6);
  static const Color danger = Color(0xFFDC2626);

  static Color riskColor(int s) {
    if (s >= 75) return danger;
    if (s >= 50) return coral;
    if (s >= 30) return amber;
    return green;
  }

  static Color riskBg(int s) {
    if (s >= 75) return const Color(0xFFFEE2E2);
    if (s >= 50) return const Color(0xFFFFF1F0);
    if (s >= 30) return const Color(0xFFFEF9C3);
    return const Color(0xFFDCFCE7);
  }

  static ThemeData get theme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, secondary: primaryLight, surface: card, error: coral),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w800, color: text, letterSpacing: -1.2, height: 1.15),
        headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.8),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.3),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: text),
        bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: textSec, height: 1.6),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: textSec, height: 1.5),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textMut),
        labelLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.5),
        iconTheme: const IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: border, width: 1)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: textMut),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: primary,
        unselectedItemColor: textMut,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
