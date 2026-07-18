import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_design/road_dna_design.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: child),
  theme: RdTheme.light(),
);

void main() {
  test('score grade keeps missing data unknown', () {
    expect(rdRoadGrade(null), RdRoadGrade.unknown);
    expect(rdRoadGrade(100), RdRoadGrade.good);
    expect(rdRoadGrade(39), RdRoadGrade.poor);
  });

  testWidgets('button is disabled while loading', (tester) async {
    await tester.pumpWidget(
      _wrap(const RdButton(label: '저장', loading: true, onPressed: null)),
    );

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('unknown score is announced as missing data', (tester) async {
    await tester.pumpWidget(_wrap(const RdScoreGauge(score: null)));
    expect(find.bySemanticsLabel('Road DNA 점수: 데이터 없음'), findsOneWidget);
    expect(find.text('100'), findsNothing);
  });
}
