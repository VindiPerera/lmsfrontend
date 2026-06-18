import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_defaults.dart';
import 'app_text_styles.dart';

/// The Master Theme definition for JAAN LMS.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter', // Assuming Inter is your standard font
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),

      // ── App Bar Theme ──────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.heading3, // Applies our standard heading
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ── Button Themes ──────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size.fromHeight(AppDefaults.buttonHeight),
          textStyle: AppTextStyles.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: AppDefaults.borderRadiusStandard,
          ),
          elevation: 2,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(AppDefaults.buttonHeight),
          textStyle: AppTextStyles.buttonText,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: AppDefaults.borderRadiusStandard,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: AppDefaults.borderRadiusStandard,
          ),
        ),
      ),

      // ── Text Field Theme ───────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDefaults.paddingMedium,
          vertical: AppDefaults.paddingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: AppDefaults.borderRadiusStandard,
          borderSide: BorderSide(
            color: AppColors.textHint.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDefaults.borderRadiusStandard,
          borderSide: BorderSide(
            color: AppColors.textHint.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDefaults.borderRadiusStandard,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDefaults.borderRadiusStandard,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDefaults.borderRadiusStandard,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      // ── Card Theme ──────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        margin: AppDefaults.edgeInsetsMedium,
        shape: const RoundedRectangleBorder(
          borderRadius: AppDefaults.borderRadiusCard,
        ),
      ),

      // ── Divider Theme ───────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: AppColors.textHint.withValues(alpha: 0.15),
        thickness: 1,
        space: 24,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.accentLight,
        surface: Color(0xFF1E1E1E),
        error: Color(0xFFEF5350),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        margin: AppDefaults.edgeInsetsMedium,
        shape: const RoundedRectangleBorder(
          borderRadius: AppDefaults.borderRadiusCard,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: Colors.white54,
      ),
    );
  }
}
