import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_design/road_dna_design.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: child),
  theme: RdTheme.light(),
);

void main() {
  test('light typography and tertiary text keep readable semantic colors', () {
    final theme = RdTheme.light();
    final colors = theme.extension<RdSemanticColors>()!;
    final primaryStyles = [
      theme.textTheme.bodyLarge,
      theme.textTheme.bodyMedium,
      theme.textTheme.bodySmall,
      theme.textTheme.displayLarge,
      theme.textTheme.displayMedium,
      theme.textTheme.headlineLarge,
      theme.textTheme.headlineMedium,
      theme.textTheme.headlineSmall,
      theme.textTheme.labelLarge,
      theme.textTheme.labelMedium,
    ];

    for (final style in primaryStyles) {
      expect(style?.color, colors.contentPrimary);
    }
    expect(
      _contrastRatio(colors.contentTertiary, colors.surfaceSubtle),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('score grade keeps missing data unknown', () {
    expect(rdRoadGrade(null), RdRoadGrade.unknown);
    expect(rdRoadGrade(100), RdRoadGrade.good);
    expect(rdRoadGrade(39), RdRoadGrade.poor);
  });

  testWidgets('button is disabled while loading', (tester) async {
    await tester.pumpWidget(
      _wrap(const RdButton(label: '저장', loading: true, onPressed: null)),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final colors = RdTheme.light().extension<RdSemanticColors>()!;
    expect(button.onPressed, isNull);
    expect(
      button.style?.backgroundColor?.resolve({WidgetState.disabled}),
      colors.surfaceSubtle,
    );
    expect(
      button.style?.foregroundColor?.resolve({WidgetState.disabled}),
      colors.contentTertiary,
    );
  });

  testWidgets('unknown score is announced as missing data', (tester) async {
    await tester.pumpWidget(_wrap(const RdScoreGauge(score: null)));
    expect(find.bySemanticsLabel('Road DNA 점수: 데이터 없음'), findsOneWidget);
    expect(find.text('100'), findsNothing);
  });
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
