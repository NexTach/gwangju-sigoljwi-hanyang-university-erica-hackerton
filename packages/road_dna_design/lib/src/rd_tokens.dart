import 'package:flutter/material.dart';

abstract final class RdPalette {
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const cobalt50 = Color(0xFFEEF3FF);
  static const cobalt100 = Color(0xFFDCE6FF);
  static const cobalt200 = Color(0xFFB8CAFF);
  static const cobalt300 = Color(0xFF8EA9FF);
  static const cobalt400 = Color(0xFF6686F4);
  static const cobalt500 = Color(0xFF3563E9);
  static const cobalt600 = Color(0xFF2851D1);
  static const cobalt700 = Color(0xFF213FA8);
  static const cobalt800 = Color(0xFF1F3785);
  static const cobalt900 = Color(0xFF1D316B);
  static const cyan50 = Color(0xFFE9FBF9);
  static const cyan100 = Color(0xFFC9F4EF);
  static const cyan500 = Color(0xFF19B8B2);
  static const cyan700 = Color(0xFF087D79);
  static const coral50 = Color(0xFFFFF0EC);
  static const coral100 = Color(0xFFFFDCD2);
  static const coral300 = Color(0xFFFF9A80);
  static const coral500 = Color(0xFFFF5A36);
  static const coral700 = Color(0xFFD33B20);
  static const coral800 = Color(0xFFB52F1B);
  static const red50 = Color(0xFFFBE3DF);
  static const red500 = Color(0xFFE14F3D);
  static const red700 = Color(0xFFB93628);
  static const amber50 = Color(0xFFFDEEDA);
  static const amber100 = Color(0xFFFAD9A8);
  static const amber500 = Color(0xFFF5A623);
  static const amber700 = Color(0xFF9D650D);
  static const green50 = Color(0xFFE4F0E8);
  static const green100 = Color(0xFFCFE5D7);
  static const green500 = Color(0xFF4F9A72);
  static const green700 = Color(0xFF3E7A5A);
  static const cream = Color(0xFFFBF6F0);
  static const linen = Color(0xFFF1EBE3);
  static const sand = Color(0xFFE4DCCE);
  static const warmGray = Color(0xFF948C82);
  static const warmGrayAccessible = Color(0xFF6F6860);
  static const ink = Color(0xFF2E2A26);
  static const gray50 = Color(0xFFF7F8FA);
  static const gray100 = Color(0xFFF2F4F6);
  static const gray200 = Color(0xFFE5E8EB);
  static const gray300 = Color(0xFFD1D6DB);
  static const gray400 = Color(0xFFB0B8C1);
  static const gray500 = Color(0xFF8B95A1);
  static const gray600 = Color(0xFF6B7684);
  static const gray650 = Color(0xFF5C6673);
  static const gray700 = Color(0xFF4E5968);
  static const gray800 = Color(0xFF333D4B);
  static const gray900 = Color(0xFF191F28);
  static const gray950 = Color(0xFF101318);
}

@immutable
class RdSemanticColors extends ThemeExtension<RdSemanticColors> {
  const RdSemanticColors({
    required this.actionPrimary,
    required this.actionPrimaryPressed,
    required this.actionSecondary,
    required this.actionSecondaryContent,
    required this.border,
    required this.borderStrong,
    required this.canvas,
    required this.contentInverse,
    required this.contentPrimary,
    required this.contentSecondary,
    required this.contentTertiary,
    required this.focus,
    required this.mapCaution,
    required this.mapGood,
    required this.mapNormal,
    required this.mapPoor,
    required this.mapUnknown,
    required this.scrim,
    required this.statusCritical,
    required this.statusCriticalSubtle,
    required this.statusInfo,
    required this.statusInfoSubtle,
    required this.statusSuccess,
    required this.statusSuccessSubtle,
    required this.statusWarning,
    required this.statusWarningSubtle,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSubtle,
  });

  const RdSemanticColors.light()
    : this(
        actionPrimary: RdPalette.coral700,
        actionPrimaryPressed: const Color(0xFFAD2D18),
        actionSecondary: RdPalette.coral50,
        actionSecondaryContent: RdPalette.coral800,
        border: const Color(0xFFE9E1D8),
        borderStrong: const Color(0xFFD6CCBF),
        canvas: RdPalette.cream,
        contentInverse: RdPalette.white,
        contentPrimary: RdPalette.ink,
        contentSecondary: const Color(0xFF5F5952),
        contentTertiary: RdPalette.warmGrayAccessible,
        focus: RdPalette.coral700,
        mapCaution: RdPalette.amber500,
        mapGood: RdPalette.green500,
        mapNormal: const Color(0xFF79AE8C),
        mapPoor: RdPalette.red500,
        mapUnknown: const Color(0xFF8F877E),
        scrim: const Color(0x7A2E2A26),
        statusCritical: RdPalette.red700,
        statusCriticalSubtle: RdPalette.red50,
        statusInfo: RdPalette.coral800,
        statusInfoSubtle: RdPalette.coral50,
        statusSuccess: RdPalette.green700,
        statusSuccessSubtle: RdPalette.green50,
        statusWarning: RdPalette.amber700,
        statusWarningSubtle: RdPalette.amber50,
        surface: RdPalette.white,
        surfaceElevated: RdPalette.white,
        surfaceSubtle: RdPalette.linen,
      );

  const RdSemanticColors.dark()
    : this(
        actionPrimary: const Color(0xFFFF775B),
        actionPrimaryPressed: RdPalette.coral500,
        actionSecondary: const Color(0xFF5A2B22),
        actionSecondaryContent: RdPalette.coral100,
        border: const Color(0xFF4A433D),
        borderStrong: const Color(0xFF615850),
        canvas: const Color(0xFF211E1B),
        contentInverse: RdPalette.ink,
        contentPrimary: RdPalette.cream,
        contentSecondary: const Color(0xFFDDD4CA),
        contentTertiary: const Color(0xFFBDB4AA),
        focus: RdPalette.coral300,
        mapCaution: const Color(0xFFF6C66C),
        mapGood: const Color(0xFF8DC6A4),
        mapNormal: const Color(0xFF6FB08B),
        mapPoor: const Color(0xFFFF8E7B),
        mapUnknown: const Color(0xFFBDB4AA),
        scrim: const Color(0xA3000000),
        statusCritical: const Color(0xFFFF8E7B),
        statusCriticalSubtle: const Color(0xFF552923),
        statusInfo: RdPalette.coral300,
        statusInfoSubtle: const Color(0xFF5A2B22),
        statusSuccess: const Color(0xFF8DC6A4),
        statusSuccessSubtle: const Color(0xFF244233),
        statusWarning: const Color(0xFFF6C66C),
        statusWarningSubtle: const Color(0xFF4A3820),
        surface: RdPalette.ink,
        surfaceElevated: const Color(0xFF38332E),
        surfaceSubtle: const Color(0xFF3A342F),
      );

  final Color actionPrimary;
  final Color actionPrimaryPressed;
  final Color actionSecondary;
  final Color actionSecondaryContent;
  final Color border;
  final Color borderStrong;
  final Color canvas;
  final Color contentInverse;
  final Color contentPrimary;
  final Color contentSecondary;
  final Color contentTertiary;
  final Color focus;
  final Color mapCaution;
  final Color mapGood;
  final Color mapNormal;
  final Color mapPoor;
  final Color mapUnknown;
  final Color scrim;
  final Color statusCritical;
  final Color statusCriticalSubtle;
  final Color statusInfo;
  final Color statusInfoSubtle;
  final Color statusSuccess;
  final Color statusSuccessSubtle;
  final Color statusWarning;
  final Color statusWarningSubtle;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceSubtle;

  @override
  RdSemanticColors copyWith({
    Color? actionPrimary,
    Color? actionPrimaryPressed,
    Color? actionSecondary,
    Color? actionSecondaryContent,
    Color? border,
    Color? borderStrong,
    Color? canvas,
    Color? contentInverse,
    Color? contentPrimary,
    Color? contentSecondary,
    Color? contentTertiary,
    Color? focus,
    Color? mapCaution,
    Color? mapGood,
    Color? mapNormal,
    Color? mapPoor,
    Color? mapUnknown,
    Color? scrim,
    Color? statusCritical,
    Color? statusCriticalSubtle,
    Color? statusInfo,
    Color? statusInfoSubtle,
    Color? statusSuccess,
    Color? statusSuccessSubtle,
    Color? statusWarning,
    Color? statusWarningSubtle,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceSubtle,
  }) => RdSemanticColors(
    actionPrimary: actionPrimary ?? this.actionPrimary,
    actionPrimaryPressed: actionPrimaryPressed ?? this.actionPrimaryPressed,
    actionSecondary: actionSecondary ?? this.actionSecondary,
    actionSecondaryContent:
        actionSecondaryContent ?? this.actionSecondaryContent,
    border: border ?? this.border,
    borderStrong: borderStrong ?? this.borderStrong,
    canvas: canvas ?? this.canvas,
    contentInverse: contentInverse ?? this.contentInverse,
    contentPrimary: contentPrimary ?? this.contentPrimary,
    contentSecondary: contentSecondary ?? this.contentSecondary,
    contentTertiary: contentTertiary ?? this.contentTertiary,
    focus: focus ?? this.focus,
    mapCaution: mapCaution ?? this.mapCaution,
    mapGood: mapGood ?? this.mapGood,
    mapNormal: mapNormal ?? this.mapNormal,
    mapPoor: mapPoor ?? this.mapPoor,
    mapUnknown: mapUnknown ?? this.mapUnknown,
    scrim: scrim ?? this.scrim,
    statusCritical: statusCritical ?? this.statusCritical,
    statusCriticalSubtle: statusCriticalSubtle ?? this.statusCriticalSubtle,
    statusInfo: statusInfo ?? this.statusInfo,
    statusInfoSubtle: statusInfoSubtle ?? this.statusInfoSubtle,
    statusSuccess: statusSuccess ?? this.statusSuccess,
    statusSuccessSubtle: statusSuccessSubtle ?? this.statusSuccessSubtle,
    statusWarning: statusWarning ?? this.statusWarning,
    statusWarningSubtle: statusWarningSubtle ?? this.statusWarningSubtle,
    surface: surface ?? this.surface,
    surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
  );

  @override
  RdSemanticColors lerp(covariant RdSemanticColors? other, double t) {
    if (other == null) return this;
    return RdSemanticColors(
      actionPrimary: Color.lerp(actionPrimary, other.actionPrimary, t)!,
      actionPrimaryPressed: Color.lerp(
        actionPrimaryPressed,
        other.actionPrimaryPressed,
        t,
      )!,
      actionSecondary: Color.lerp(actionSecondary, other.actionSecondary, t)!,
      actionSecondaryContent: Color.lerp(
        actionSecondaryContent,
        other.actionSecondaryContent,
        t,
      )!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      contentInverse: Color.lerp(contentInverse, other.contentInverse, t)!,
      contentPrimary: Color.lerp(contentPrimary, other.contentPrimary, t)!,
      contentSecondary: Color.lerp(
        contentSecondary,
        other.contentSecondary,
        t,
      )!,
      contentTertiary: Color.lerp(contentTertiary, other.contentTertiary, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      mapCaution: Color.lerp(mapCaution, other.mapCaution, t)!,
      mapGood: Color.lerp(mapGood, other.mapGood, t)!,
      mapNormal: Color.lerp(mapNormal, other.mapNormal, t)!,
      mapPoor: Color.lerp(mapPoor, other.mapPoor, t)!,
      mapUnknown: Color.lerp(mapUnknown, other.mapUnknown, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      statusCritical: Color.lerp(statusCritical, other.statusCritical, t)!,
      statusCriticalSubtle: Color.lerp(
        statusCriticalSubtle,
        other.statusCriticalSubtle,
        t,
      )!,
      statusInfo: Color.lerp(statusInfo, other.statusInfo, t)!,
      statusInfoSubtle: Color.lerp(
        statusInfoSubtle,
        other.statusInfoSubtle,
        t,
      )!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      statusSuccessSubtle: Color.lerp(
        statusSuccessSubtle,
        other.statusSuccessSubtle,
        t,
      )!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      statusWarningSubtle: Color.lerp(
        statusWarningSubtle,
        other.statusWarningSubtle,
        t,
      )!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
    );
  }
}

extension RdThemeContext on BuildContext {
  RdSemanticColors get rdColors =>
      Theme.of(this).extension<RdSemanticColors>() ??
      const RdSemanticColors.light();
}

abstract final class RdSpacing {
  static const x0 = 0.0;
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x12 = 48.0;
  static const x16 = 64.0;
  static const x20 = 80.0;
  static const x24 = 96.0;
}

abstract final class RdRadius {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 28.0;
  static const screen = 44.0;
  static const pill = 999.0;
}

abstract final class RdSize {
  static const touchTarget = 44.0;
  static const buttonSmall = 40.0;
  static const buttonMedium = 48.0;
  static const buttonLarge = 56.0;
  static const navigation = 56.0;
}

abstract final class RdMotion {
  static const instant = Duration(milliseconds: 80);
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 360);
  static const standard = Cubic(0.2, 0, 0, 1);
  static const enter = Cubic(0, 0, 0, 1);
  static const exit = Cubic(0.3, 0, 1, 1);
}
