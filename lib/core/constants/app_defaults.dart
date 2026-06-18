import 'package:flutter/material.dart';

/// Centralized defaults for spacing, sizing, and shapes.
/// Use these constants instead of hard-coding values like `16.0`
/// to easily change the app's global look and feel later.
class AppDefaults {
  AppDefaults._();

  // ── Padding & Margins ────────────────────────────────────
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0; // The standard padding
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const EdgeInsets edgeInsetsMedium = EdgeInsets.all(paddingMedium);
  static const EdgeInsets edgeInsetsLarge = EdgeInsets.all(paddingLarge);

  // ── Border Radius (Roundness) ────────────────────────────
  /// Default roundness for standard elements (like buttons and text fields)
  static const double radiusStandard = 12.0;

  /// Default roundness for cards and large containers
  static const double radiusCard = 20.0;

  static const BorderRadius borderRadiusStandard = BorderRadius.all(
    Radius.circular(radiusStandard),
  );
  static const BorderRadius borderRadiusCard = BorderRadius.all(
    Radius.circular(radiusCard),
  );

  // ── Icon Sizes ───────────────────────────────────────────
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;

  // ── Button Dimensions ────────────────────────────────────
  static const double buttonHeight = 52.0;
}
