import 'dart:convert';
import 'dart:io';

import 'package:app/models/event_config.dart';
import 'package:app/util/event_token.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the shared token fixture used by both `app` and `cli` tests so
/// the `?d=` payload format cannot drift between the two sides.
/// Single source: test_fixtures/event_token_v1.json.
Map<String, Object?> loadSharedFixture() {
  final file = File('../test_fixtures/event_token_v1.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

void main() {
  group('shared fixture (test_fixtures/event_token_v1.json)', () {
    test('decodes every fixture case exactly as specified', () {
      final fixture = loadSharedFixture();
      final cases = fixture['cases']! as List<Object?>;
      expect(cases, isNotEmpty);

      for (final rawCase in cases) {
        final testCase = rawCase as Map<String, Object?>;
        final name = testCase['name']! as String;
        final token = testCase['token']! as String;
        final expected = testCase['expected']! as Map<String, Object?>;

        final config = decodeEventToken(token);
        expect(config, isNotNull, reason: 'case "$name" must decode');
        expect(config!.accessKeyId, expected['accessKeyId'], reason: 'case "$name" access key');
        expect(config.secretKey, expected['secretKey'], reason: 'case "$name" secret key');
        expect(config.bucket, expected['bucket'], reason: 'case "$name" bucket');
        expect(config.region, expected['region'], reason: 'case "$name" region');
        expect(config.endpoint, expected['endpoint'], reason: 'case "$name" endpoint');
        expect(config.hasCustomEndpoint, expected['endpoint'] != null, reason: 'case "$name" endpoint flag');
      }
    });

    test('re-encoding a decoded config reproduces the fixture token', () {
      final fixture = loadSharedFixture();
      final cases = fixture['cases']! as List<Object?>;
      for (final rawCase in cases) {
        final testCase = rawCase as Map<String, Object?>;
        final name = testCase['name']! as String;
        final payload = testCase['payload']! as Map<String, Object?>;
        final token = testCase['token']! as String;

        // Compact JSON, base64url without padding — the locked format.
        final encoded = base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
        expect(encoded, token, reason: 'case "$name" must round-trip to the same token');
      }
    });

    test('decodes the token out of a full QR URL with ?d=', () {
      final fixture = loadSharedFixture();
      final cases = fixture['cases']! as List<Object?>;
      for (final rawCase in cases) {
        final testCase = rawCase as Map<String, Object?>;
        final url = Uri.parse(testCase['url']! as String);
        final config = decodeEventTokenFromUrl(url);
        expect(config, isA<EventConfig>());
        expect(config!.bucket, (testCase['expected']! as Map<String, Object?>)['bucket']);
      }
    });
  });

  group('decodeEventToken validation', () {
    test('returns null for missing or blank tokens', () {
      expect(decodeEventToken(null), isNull);
      expect(decodeEventToken(''), isNull);
      expect(decodeEventToken('   '), isNull);
    });

    test('returns null when the URL has no d parameter', () {
      expect(decodeEventTokenFromUrl(Uri.parse('https://photos.example.com/')), isNull);
    });

    String encode(Object? value, {bool asText = false}) =>
        base64Url.encode(utf8.encode(asText ? value as String : jsonEncode(value))).replaceAll('=', '');

    test('rejects non-base64url input', () {
      expect(() => decodeEventToken('!!!not-base64!!!\$\$'), throwsA(isA<EventTokenException>()));
      expect(() => decodeEventToken('abc def'), throwsA(isA<EventTokenException>()));
    });

    test('rejects base64url that is not JSON', () {
      expect(() => decodeEventToken(encode('not json at all', asText: true)), throwsA(isA<EventTokenException>()));
    });

    test('rejects JSON that is not an object', () {
      expect(() => decodeEventToken(encode(['k', 's'])), throwsA(isA<EventTokenException>()));
      expect(() => decodeEventToken(encode('{"k":')), throwsA(anything)); // malformed JSON
    });

    test('rejects missing required fields', () {
      for (final missing in ['k', 's', 'b', 'r']) {
        final payload = {'k': 'key', 's': 'secret', 'b': 'bucket', 'r': 'region'}..remove(missing);
        expect(
          () => decodeEventToken(encode(payload)),
          throwsA(isA<EventTokenException>()),
          reason: 'missing "$missing" must be rejected',
        );
      }
    });

    test('rejects empty required values', () {
      for (final field in ['k', 's', 'b', 'r']) {
        final payload = {'k': 'key', 's': 'secret', 'b': 'bucket', 'r': 'region'};
        payload[field] = '';
        expect(
          () => decodeEventToken(encode(payload)),
          throwsA(isA<EventTokenException>()),
          reason: 'empty "$field" must be rejected',
        );
      }
    });

    test('rejects non-string required values', () {
      final payload = {'k': 42, 's': 'secret', 'b': 'bucket', 'r': 'region'};
      expect(() => decodeEventToken(encode(payload)), throwsA(isA<EventTokenException>()));
    });

    test('rejects an empty optional endpoint', () {
      final payload = {'k': 'key', 's': 'secret', 'b': 'bucket', 'r': 'region', 'ep': ''};
      expect(() => decodeEventToken(encode(payload)), throwsA(isA<EventTokenException>()));
    });

    test('accepts padded base64url as well as unpadded', () {
      final fixture = loadSharedFixture();
      final cases = fixture['cases']! as List<Object?>;
      final token = (cases.first as Map<String, Object?>)['token']! as String;
      final padded = token + '=' * ((4 - token.length % 4) % 4);
      expect(decodeEventToken(padded), isA<EventConfig>());
    });
  });
}
