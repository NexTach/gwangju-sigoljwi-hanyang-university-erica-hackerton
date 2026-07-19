import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/core/app_config.dart';

void main() {
  group('Describe AppConfig.fromEnvironment', () {
    group('Context 모바일 앱을 기본 설정으로 실행하는 경우', () {
      test('It 용봉동 시나리오를 별도 실행 플래그 없이 활성화한다', () {
        final config = AppConfig.fromEnvironment();

        expect(config.demoMode, isTrue);
        expect(config.apiBaseUrl, 'https://kimtaeeun.site/road-dna');
      });
    });
  });
}
