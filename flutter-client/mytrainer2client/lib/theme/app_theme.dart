import 'package:flutter/material.dart';

import 'app_density.dart';

class AppTheme {
  static ThemeData light() {
    const seed = Color(0xFF2F80FF);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFF),
      visualDensity: const VisualDensity(
        horizontal: -1.2,
        vertical: -1.6,
      ),
    );

    final text = _scaleTextTheme(
      base.textTheme.apply(
        bodyColor: const Color(0xFF232530),
        displayColor: const Color(0xFF232530),
      ),
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF232530),
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppDensity.circular(24),
          side: const BorderSide(color: Color(0xFFDCE8FF)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: AppDensity.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: AppDensity.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDCE8FF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDensity.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDCE8FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDensity.circular(18),
          borderSide: const BorderSide(color: seed, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(0, AppDensity.space(48)),
          padding: AppDensity.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppDensity.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, AppDensity.space(46)),
          padding: AppDensity.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppDensity.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: AppDensity.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: AppDensity.circular(14),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        padding: AppDensity.symmetric(horizontal: 8, vertical: 4),
        labelStyle: text.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: AppDensity.circular(999),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDensity.radius(32)),
          ),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppDensity.circular(28),
        ),
      ),
    );
  }

  static TextTheme _scaleTextTheme(TextTheme textTheme) {
    TextStyle? scale(TextStyle? style) {
      if (style == null) return null;
      final size = style.fontSize;
      if (size == null) return style;
      return style.copyWith(fontSize: size * AppDensity.textScale);
    }

    return textTheme.copyWith(
      displayLarge: scale(textTheme.displayLarge),
      displayMedium: scale(textTheme.displayMedium),
      displaySmall: scale(textTheme.displaySmall),
      headlineLarge: scale(textTheme.headlineLarge),
      headlineMedium: scale(textTheme.headlineMedium),
      headlineSmall: scale(textTheme.headlineSmall),
      titleLarge: scale(textTheme.titleLarge),
      titleMedium: scale(textTheme.titleMedium),
      titleSmall: scale(textTheme.titleSmall),
      bodyLarge: scale(textTheme.bodyLarge),
      bodyMedium: scale(textTheme.bodyMedium),
      bodySmall: scale(textTheme.bodySmall),
      labelLarge: scale(textTheme.labelLarge),
      labelMedium: scale(textTheme.labelMedium),
      labelSmall: scale(textTheme.labelSmall),
    );
  }
}
