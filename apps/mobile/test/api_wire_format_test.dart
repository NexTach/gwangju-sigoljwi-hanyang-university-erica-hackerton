import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/services/api_service.dart';
import 'package:road_dna_mobile/services/identity_service.dart';

void main() {
  group('Describe formatApiTimestamp', () {
    group('Context Dart 시각에 마이크로초가 포함된 경우', () {
      test('It API 계약에 맞게 UTC 밀리초까지만 직렬화한다', () {
        final timestamp = formatApiTimestamp(
          DateTime.utc(2026, 7, 18, 13, 10, 0, 123, 456),
        );

        expect(timestamp, '2026-07-18T13:10:00.123Z');
      });
    });
  });

  group('Describe isValidAnonymousIdentity', () {
    group('Context 저장된 익명 식별자를 검증하는 경우', () {
      test('It API가 허용하는 UUID만 승인한다', () {
        expect(
          isValidAnonymousIdentity('d189be1f-e2d5-4b90-8cec-360ec343be99'),
          isTrue,
        );
        expect(isValidAnonymousIdentity('anonymous'), isFalse);
        expect(
          isValidAnonymousIdentity('d189be1f-e2d5-0b90-8cec-360ec343be99'),
          isFalse,
        );
      });
    });
  });
}
