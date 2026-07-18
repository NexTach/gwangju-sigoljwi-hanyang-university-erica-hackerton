import 'package:flutter/material.dart';
import 'package:road_dna_design/road_dna_design.dart';

abstract final class CompanionColors {
  static const cream = Color(0xFFFBF6F0);
  static const creamMuted = Color(0xFFF1EBE3);
  static const creamMap = Color(0xFFF3EEE4);
  static const creamLine = Color(0xFFE4DCCE);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2E2A26);
  static const muted = Color(0xFF776F66);
  static const faint = Color(0xFFC9C2B6);
  static const coral = Color(0xFFFF5A36);
  static const coralAction = Color(0xFFD33B20);
  static const coralPressed = Color(0xFFAD2D18);
  static const coralSoft = Color(0xFFFBE3DF);
  static const red = Color(0xFFC23A28);
  static const green = Color(0xFF3E7A5A);
  static const greenBright = Color(0xFF4F9A72);
  static const greenSoft = Color(0xFFE4F0E8);
  static const amber = Color(0xFFC77E12);
  static const amberBright = Color(0xFFF5A623);
  static const amberSoft = Color(0xFFFDEEDA);
}

final companionButtonOverlayColor = WidgetStateProperty.resolveWith<Color?>((
  states,
) {
  if (states.contains(WidgetState.focused)) {
    return const Color(0x33FF5A36);
  }
  return Colors.transparent;
});

ButtonStyle companionButtonStyle(ButtonStyle? style) {
  final baseStyle = style ?? const ButtonStyle();
  return baseStyle.copyWith(
    overlayColor: companionButtonOverlayColor,
    side: WidgetStateProperty.resolveWith((states) {
      final existingSide = baseStyle.side?.resolve(states);
      if (states.contains(WidgetState.focused)) {
        return BorderSide(
          color: CompanionColors.coralPressed,
          width: 2,
          strokeAlign:
              existingSide?.strokeAlign ?? BorderSide.strokeAlignInside,
        );
      }
      return existingSide;
    }),
    splashFactory: NoSplash.splashFactory,
  );
}

ThemeData companionTheme() {
  final semanticColors = const RdSemanticColors.light().copyWith(
    actionPrimary: CompanionColors.coralAction,
    actionPrimaryPressed: CompanionColors.coralPressed,
    actionSecondary: CompanionColors.coralSoft,
    actionSecondaryContent: CompanionColors.coralPressed,
    border: CompanionColors.creamLine,
    borderStrong: const Color(0xFFD8CFC2),
    canvas: CompanionColors.cream,
    contentPrimary: CompanionColors.ink,
    contentSecondary: CompanionColors.muted,
    contentTertiary: CompanionColors.muted,
    focus: CompanionColors.coral,
    mapCaution: CompanionColors.amberBright,
    mapGood: CompanionColors.greenBright,
    mapNormal: CompanionColors.green,
    mapPoor: CompanionColors.red,
    mapUnknown: CompanionColors.faint,
    statusCritical: CompanionColors.red,
    statusCriticalSubtle: CompanionColors.coralSoft,
    statusInfo: CompanionColors.coralPressed,
    statusInfoSubtle: CompanionColors.coralSoft,
    statusSuccess: CompanionColors.green,
    statusSuccessSubtle: CompanionColors.greenSoft,
    statusWarning: CompanionColors.amber,
    statusWarningSubtle: CompanionColors.amberSoft,
    surface: CompanionColors.white,
    surfaceElevated: CompanionColors.white,
    surfaceSubtle: CompanionColors.creamMuted,
  );
  final base = RdTheme.light();
  final textTheme = base.textTheme
      .apply(
        bodyColor: CompanionColors.ink,
        displayColor: CompanionColors.ink,
        fontFamily: 'Pretendard',
      )
      .copyWith(
        displayLarge: const TextStyle(
          color: CompanionColors.ink,
          fontFamily: 'Pretendard',
          fontSize: 40,
          fontWeight: FontWeight.w800,
          height: 1.12,
          letterSpacing: -1.2,
        ),
        displayMedium: const TextStyle(
          color: CompanionColors.ink,
          fontFamily: 'Pretendard',
          fontSize: 30,
          fontWeight: FontWeight.w800,
          height: 1.18,
          letterSpacing: -0.8,
        ),
        headlineLarge: const TextStyle(
          color: CompanionColors.ink,
          fontFamily: 'Pretendard',
          fontSize: 26,
          fontWeight: FontWeight.w800,
          height: 1.22,
          letterSpacing: -0.55,
        ),
        headlineMedium: const TextStyle(
          color: CompanionColors.ink,
          fontFamily: 'Pretendard',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1.28,
          letterSpacing: -0.4,
        ),
        headlineSmall: const TextStyle(
          color: CompanionColors.ink,
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          height: 1.32,
          letterSpacing: -0.2,
        ),
        bodyLarge: const TextStyle(
          color: CompanionColors.ink,
          fontFamily: 'Pretendard',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          color: CompanionColors.ink,
          fontFamily: 'Pretendard',
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          height: 1.46,
        ),
        bodySmall: const TextStyle(
          color: CompanionColors.muted,
          fontFamily: 'Pretendard',
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
        labelLarge: const TextStyle(
          color: CompanionColors.ink,
          fontFamily: 'Pretendard',
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        labelMedium: const TextStyle(
          color: CompanionColors.ink,
          fontFamily: 'Pretendard',
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        labelSmall: const TextStyle(
          color: CompanionColors.muted,
          fontFamily: 'Pretendard',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: CompanionColors.cream,
      elevation: 0,
      foregroundColor: CompanionColors.ink,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    focusColor: const Color(0x33FF5A36),
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: CompanionColors.cream,
      modalBarrierColor: Color(0x662E2A26),
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: companionButtonStyle(base.elevatedButtonTheme.style),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: companionButtonStyle(base.filledButtonTheme.style),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: companionButtonStyle(base.iconButtonTheme.style),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: companionButtonStyle(base.menuButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: companionButtonStyle(base.outlinedButtonTheme.style),
    ),
    textButtonTheme: TextButtonThemeData(
      style: companionButtonStyle(base.textButtonTheme.style),
    ),
    colorScheme: base.colorScheme.copyWith(
      error: CompanionColors.red,
      onPrimary: CompanionColors.white,
      onSurface: CompanionColors.ink,
      primary: CompanionColors.coralAction,
      secondary: CompanionColors.green,
      surface: CompanionColors.white,
    ),
    extensions: [semanticColors],
    inputDecorationTheme: const InputDecorationTheme(
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: CompanionColors.coral, width: 2),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: CompanionColors.creamLine, width: 2),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: CompanionColors.red, width: 2),
      ),
      filled: false,
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: CompanionColors.coral, width: 2),
      ),
      hintStyle: TextStyle(color: CompanionColors.faint),
    ),
    scaffoldBackgroundColor: CompanionColors.cream,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: CompanionColors.ink,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: textTheme.labelMedium?.copyWith(
        color: CompanionColors.white,
      ),
      elevation: 0,
      insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    switchTheme: base.switchTheme.copyWith(
      overlayColor: companionButtonOverlayColor,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: CompanionColors.coral,
      selectionColor: Color(0x44FF5A36),
      selectionHandleColor: CompanionColors.coral,
    ),
    textTheme: textTheme,
  );
}
