import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Renk Paleti ────────────────────────────────────────────────────────────
class AppColors {
  static const bg       = Color(0xFF0D1B2A);
  static const bg2      = Color(0xFF132236);
  static const bg3      = Color(0xFF1A2E45);
  static const surface  = Color(0xFF1E3450);

  static const border   = Color(0x14FFFFFF);
  static const border2  = Color(0x24FFFFFF);

  static const text     = Color(0xFFE8EDF2);
  static const muted    = Color(0xFF7A90A4);
  static const dim      = Color(0xFF4A6070);

  static const fen      = Color(0xFF4FC3F7);
  static const fenDim   = Color(0x1F4FC3F7);
  static const fenGlow  = Color(0x404FC3F7);

  static const saglik   = Color(0xFF4DD0A6);
  static const saglikDim = Color(0x1F4DD0A6);

  static const sosyal   = Color(0xFFF5A623);
  static const sosyalDim = Color(0x1FF5A623);

  static const danger   = Color(0xFFFF6B6B);
  static const dangerDim = Color(0x1AFF6B6B);
  static const success  = Color(0xFF4DD0A6);
}

// ─── Tipografi ───────────────────────────────────────────────────────────────
class AppTextStyles {
  static TextStyle display(double size, {Color? color, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: weight, color: color ?? AppColors.text, letterSpacing: -0.03 * size);

  static TextStyle body(double size, {Color? color, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color ?? AppColors.text);

  static TextStyle mono(double size, {Color? color, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color ?? AppColors.text);

  static TextStyle label(double size, {Color? color}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w600, color: color ?? AppColors.muted,
          letterSpacing: 0.08 * size);
}

// ─── Tema ────────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.fen,
      secondary: AppColors.saglik,
      surface:   AppColors.bg2,
      error:     AppColors.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: AppColors.text),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bg2,
      selectedItemColor: AppColors.fen,
      unselectedItemColor: AppColors.dim,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerColor: AppColors.border,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
  );
}

// ─── Sabitler ────────────────────────────────────────────────────────────────
class AppRadius {
  static const sm = Radius.circular(8);
  static const md = Radius.circular(14);
  static const lg = Radius.circular(20);
  static const xl = Radius.circular(28);

  static const smBR = BorderRadius.all(sm);
  static const mdBR = BorderRadius.all(md);
  static const lgBR = BorderRadius.all(lg);
  static const xlBR = BorderRadius.all(xl);
}
