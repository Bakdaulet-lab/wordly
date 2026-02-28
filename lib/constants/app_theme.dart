import 'package:flutter/material.dart';

/// Centralized theme configuration supporting both light and dark modes.
class AppTheme {
  AppTheme._();

  // ── Shared constants ───────────────────────────────────────────────
  static const double _borderRadius = 12.0;

  // ── Light palette ──────────────────────────────────────────────────
  static const Color _lightPrimary = Color(0xFF6C63FF);
  static const Color _lightPrimaryDark = Color(0xFF4A42DB);
  static const Color _lightBackground = Color(0xFFF5F5FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF1A1A2E);
  static const Color _lightTextSecondary = Color(0xFF6B7280);
  static const Color _lightTextHint = Color(0xFF9CA3AF);

  // ── Dark palette ───────────────────────────────────────────────────
  static const Color _darkPrimary = Color(0xFF9D97FF);
  static const Color _darkPrimaryDark = Color(0xFF6C63FF);
  static const Color _darkBackground = Color(0xFF121218);
  static const Color _darkSurface = Color(0xFF1E1E2C);
  static const Color _darkCard = Color(0xFF252538);
  static const Color _darkTextPrimary = Color(0xFFE8E8F0);
  static const Color _darkTextSecondary = Color(0xFFA0A0B8);
  static const Color _darkTextHint = Color(0xFF6B6B80);

  // ── Gamification (shared) ──────────────────────────────────────────
  static const Color xpGold = Color(0xFFFFD700);
  static const Color streakOrange = Color(0xFFFF6B35);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFEF5350);

  // ── Difficulty (shared) ────────────────────────────────────────────
  static const Color difficultyBeginner = Color(0xFF4CAF50);
  static const Color difficultyEasy = Color(0xFF8BC34A);
  static const Color difficultyMedium = Color(0xFFFFEB3B);
  static const Color difficultyHard = Color(0xFFFF9800);
  static const Color difficultyExpert = Color(0xFFf44336);

  // ── Helper: resolve by brightness ──────────────────────────────────
  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkPrimary
          : _lightPrimary;

  static Color primaryDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkPrimaryDark
          : _lightPrimaryDark;

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkBackground
          : _lightBackground;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkSurface
          : _lightSurface;

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkCard
          : _lightCard;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkTextPrimary
          : _lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkTextSecondary
          : _lightTextSecondary;

  static Color textHint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _darkTextHint
          : _lightTextHint;

  // ── ThemeData builders ─────────────────────────────────────────────
  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        primary: _lightPrimary,
        background: _lightBackground,
        surface: _lightSurface,
        card: _lightCard,
        textPrimary: _lightTextPrimary,
        textSecondary: _lightTextSecondary,
        textHint: _lightTextHint,
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        primary: _darkPrimary,
        background: _darkBackground,
        surface: _darkSurface,
        card: _darkCard,
        textPrimary: _darkTextPrimary,
        textSecondary: _darkTextSecondary,
        textHint: _darkTextHint,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color background,
    required Color surface,
    required Color card,
    required Color textPrimary,
    required Color textSecondary,
    required Color textHint,
  }) {
    final isDark = brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: primary,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: isDark ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          side: isDark
              ? BorderSide(color: Colors.grey.shade800, width: 0.5)
              : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textHint,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
