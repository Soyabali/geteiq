import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Builds the single [ThemeData] the app runs on.
///
/// Inter is used because it is metrically close to San Francisco, so the UI
/// reads as native on iOS while staying crisp on Android.
class AppTheme {
  const AppTheme._();

  static TextTheme _textTheme() {
    const ink = AppColors.ink;

    // Tight tracking on the large sizes matches the prototype's -0.3/-0.5px.
    final base = TextStyle(color: ink, height: 1.25);

    return GoogleFonts.interTextTheme(
      TextTheme(
        displaySmall: base.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        headlineMedium: base.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        // Screen titles ("Login", "Select Guests", "Invite Guests").
        headlineSmall: base.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: base.copyWith(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        // Card headings.
        titleMedium: base.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleSmall: base.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        bodyLarge: base.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        bodyMedium: base.copyWith(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          height: 1.45,
          color: AppColors.inkSoft,
        ),
        bodySmall: base.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.45,
          color: AppColors.muted,
        ),
        labelLarge: base.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        labelMedium: base.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
        labelSmall: base.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.muted,
        ),
      ),
    );
  }

  static ThemeData light() {
    final text = _textTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: text,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        primary: AppColors.brand,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.danger,
      ),
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
        iconTheme: const IconThemeData(color: AppColors.ink, size: 24),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardShape,
          side: const BorderSide(color: AppColors.borderSoft),
        ),
      ),

      // Fields are flat, filled and borderless until focused — matches the
      // clean look of the Login / Add Guest screens.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: AppColors.faint),
        labelStyle: text.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderSoft,
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.sheetShape),
        showDragHandle: false,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),

      // Smooth, platform-appropriate page transitions.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
