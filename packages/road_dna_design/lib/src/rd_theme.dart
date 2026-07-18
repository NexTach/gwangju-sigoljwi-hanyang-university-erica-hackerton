import 'package:flutter/material.dart';

import 'rd_tokens.dart';

abstract final class RdTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    colors: const RdSemanticColors.light(),
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    colors: const RdSemanticColors.dark(),
  );

  static ThemeData _build({
    required Brightness brightness,
    required RdSemanticColors colors,
  }) {
    final base = ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        error: colors.statusCritical,
        onError: colors.contentInverse,
        onPrimary: colors.contentInverse,
        onSecondary: colors.actionSecondaryContent,
        onSurface: colors.contentPrimary,
        primary: colors.actionPrimary,
        secondary: colors.mapGood,
        surface: colors.surface,
      ),
      scaffoldBackgroundColor: colors.canvas,
      useMaterial3: true,
    );

    final baseTextTheme = base.textTheme.apply(
      bodyColor: colors.contentPrimary,
      displayColor: colors.contentPrimary,
      fontFamily: 'Pretendard',
    );
    final textTheme = baseTextTheme.copyWith(
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 22 / 15,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
      ),
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontFamily: 'SUIT',
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 56 / 48,
        letterSpacing: -1,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontFamily: 'SUIT',
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 46 / 36,
        letterSpacing: -0.8,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontFamily: 'SUIT',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 38 / 28,
        letterSpacing: -0.5,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontFamily: 'SUIT',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 30 / 22,
        letterSpacing: -0.3,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontFamily: 'SUIT',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 26 / 18,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 24 / 16,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
      ),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        elevation: 0,
        foregroundColor: colors.contentPrimary,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.labelLarge?.copyWith(
          color: colors.contentPrimary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceElevated,
        modalBarrierColor: colors.scrim,
        modalElevation: 12,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RdRadius.xl),
          ),
        ),
        showDragHandle: true,
      ),
      dividerColor: colors.border,
      extensions: [colors],
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RdRadius.md),
          borderSide: BorderSide(color: colors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RdRadius.md),
          borderSide: BorderSide(color: colors.borderStrong),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RdRadius.md),
          borderSide: BorderSide(color: colors.statusCritical),
        ),
        filled: true,
        fillColor: colors.surface,
        focusColor: colors.focus,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RdRadius.md),
          borderSide: BorderSide(color: colors.focus, width: 2),
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: colors.contentSecondary,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colors.contentTertiary,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colors.contentSecondary,
        ),
        suffixStyle: textTheme.bodyMedium?.copyWith(
          color: colors.contentSecondary,
        ),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: const FadeForwardsPageTransitionsBuilder(),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        actionTextColor: colors.contentInverse,
        backgroundColor: colors.contentPrimary,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: textTheme.labelMedium?.copyWith(
          color: colors.contentInverse,
        ),
        elevation: 8,
        insetPadding: const EdgeInsets.all(RdSpacing.x5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RdRadius.lg),
        ),
      ),
      textTheme: textTheme,
    );
  }
}
