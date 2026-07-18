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
      focusColor: colors.focus.withValues(alpha: 0.2),
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      scaffoldBackgroundColor: colors.canvas,
      splashColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
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
        fontFamily: 'Pretendard',
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 54 / 48,
        letterSpacing: -1.2,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontFamily: 'Pretendard',
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 42 / 36,
        letterSpacing: -0.9,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontFamily: 'Pretendard',
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 36 / 28,
        letterSpacing: -0.7,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontFamily: 'Pretendard',
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 32 / 24,
        letterSpacing: -0.5,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontFamily: 'Pretendard',
        fontSize: 19,
        fontWeight: FontWeight.w800,
        height: 27 / 19,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        height: 22 / 15,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 19 / 13,
      ),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colors.canvas,
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
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RdRadius.lg),
        ),
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
        fillColor: colors.surfaceElevated,
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
        elevation: 0,
        insetPadding: const EdgeInsets.all(RdSpacing.x5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RdRadius.lg),
        ),
      ),
      textTheme: textTheme,
    );
  }
}
