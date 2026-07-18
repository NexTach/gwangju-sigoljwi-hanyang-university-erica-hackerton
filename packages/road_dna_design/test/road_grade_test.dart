import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_design/road_dna_design.dart';

void main() {
  group('Describe rdRoadGrade', () {
    group('Context 점수 경계값을 노면 등급으로 변환하는 경우', () {
      test('It 미확인 값과 네 개 점수 구간을 구분한다', () {
        expect([null, 39, 40, 60, 80].map(rdRoadGrade), [
          RdRoadGrade.unknown,
          RdRoadGrade.poor,
          RdRoadGrade.caution,
          RdRoadGrade.normal,
          RdRoadGrade.good,
        ]);
      });
    });
  });
}
