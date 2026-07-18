import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/services/api_service.dart';
import 'package:road_dna_mobile/services/identity_service.dart';

void main() {
  test('API timestamps are truncated to milliseconds', () {
    final timestamp = formatApiTimestamp(
      DateTime.utc(2026, 7, 18, 13, 10, 0, 123, 456),
    );

    expect(timestamp, '2026-07-18T13:10:00.123Z');
  });

  test('stored anonymous identity must satisfy the API UUID contract', () {
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
}
