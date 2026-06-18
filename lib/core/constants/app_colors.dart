import 'package:flutter/material.dart';

/// Central color palette for the JAAN Network LMS app.
/// Modern, premium educational look with soft backgrounds and vibrant accents.
class AppColors {
  AppColors._();

  // ── Primary ────────────────────────────────────────────
  static const Color primary = Color(0xFF4F46E5); // Deep Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);

  // ── Accent ─────────────────────────────────────────────
  static const Color accent = Color(0xFF10B981); // Modern Emerald
  static const Color accentLight = Color(0xFF34D399);
  static const Color accentDark = Color(0xFF047857);

  // ── Surface / Background ───────────────────────────────
  static const Color background = Color(0xFFF4F7FC); // Soft premium background
  static const Color surface = Colors.white;
  static const Color cardSurface = Colors.white;

  // ── Text ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A); // High contrast slate
  static const Color textSecondary = Color(0xFF64748B); // Soft grey
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textOnPrimary = Colors.white;

  // ── Status ─────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);

  // ── Gradients ──────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentLight, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
