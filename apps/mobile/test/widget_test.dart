import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_design/road_dna_design.dart';
import 'package:road_dna_mobile/design_system_catalog.dart';

void main() {
  testWidgets('design system catalog exposes critical states', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DesignSystemCatalog(darkMode: false, onDarkModeChanged: (_) {}),
        theme: RdTheme.light(),
      ),
    );

    expect(find.text('Actions'), findsOneWidget);
    expect(find.text('측정 시작'), findsOneWidget);
    expect(find.text('데이터 없음'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('이동 충격 패턴 감지'), 500);
    expect(find.text('이동 충격 패턴 감지'), findsOneWidget);
  });
}
