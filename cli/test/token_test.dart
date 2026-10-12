import 'dart:convert';
import 'dart:io';

import 'package:cli/cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The single source of truth for the `?d=` token format, shared with the
/// guest app. Lives at the repository root.
Map<String, Object?> loadSharedFixture() {
  final file = File(p.normalize(p.join(Directory.current.path, '../test_fixtures/event_token_v1.json')));
  if (!file.existsSync()) {
    throw StateError('shared fixture must exist at ${file.path}');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

void main() {
  group('event token (shared fixture)', () {
    final fixture = loadSharedFixture();
    final cases = fixture['cases']! as List<Object?>;
    final baseUrl = fixture['baseUrl']! as String;

    test('mints exactly the shared-fixture tokens and URLs', () {
      for (final raw in cases) {
        final c = raw! as Map<String, Object?>;
        final payload = c['payload']! as Map<String, Object?>;
        final token = mintEventToken(
          accessKeyId: payload['k']! as String,
          secretKey: payload['s']! as String,
          bucket: payload['b']! as String,
          region: payload['r']! as String,
          endpoint: payload.containsKey('ep') ? payload['ep']! as String : null,
        );
        expect(token, c['token'], reason: 'case ${c['name']}');
        expect(buildEventUrl(baseUrl, token), c['url'], reason: 'case ${c['name']} url');
      }
    });

    test('decodes to the shared-fixture payload structure', () {
      for (final raw in cases) {
        final c = raw! as Map<String, Object?>;
        final expected = c['expected']! as Map<String, Object?>;
        final payload = decodeEventToken(c['token']! as String);
        expect(payload['k'], expected['accessKeyId'], reason: 'case ${c['name']}');
        expect(payload['s'], expected['secretKey'], reason: 'case ${c['name']}');
        expect(payload['b'], expected['bucket'], reason: 'case ${c['name']}');
        expect(payload['r'], expected['region'], reason: 'case ${c['name']}');
        expect(payload['ep'], expected['endpoint'], reason: 'case ${c['name']}');
      }
    });
  });

  group('mintEventToken validation', () {
    test('rejects empty required values', () {
      expect(
        () => mintEventToken(accessKeyId: '', secretKey: 's', bucket: 'b', region: 'r'),
        throwsA(isA<EventTokenFormatException>()),
      );
      expect(
        () => mintEventToken(accessKeyId: 'k', secretKey: '  ', bucket: 'b', region: 'r'),
        throwsA(isA<EventTokenFormatException>()),
      );
      expect(
        () => mintEventToken(accessKeyId: 'k', secretKey: 's', bucket: '', region: 'r'),
        throwsA(isA<EventTokenFormatException>()),
      );
      expect(
        () => mintEventToken(accessKeyId: 'k', secretKey: 's', bucket: 'b', region: ''),
        throwsA(isA<EventTokenFormatException>()),
      );
    });

    test('rejects a non-empty but blank optional endpoint', () {
      expect(
        () => mintEventToken(accessKeyId: 'k', secretKey: 's', bucket: 'b', region: 'r', endpoint: '   '),
        throwsA(isA<EventTokenFormatException>()),
      );
    });

    test('rejects values containing whitespace', () {
      expect(
        () => mintEventToken(accessKeyId: 'k', secretKey: 's', bucket: 'my bucket', region: 'r'),
        throwsA(isA<EventTokenFormatException>()),
      );
    });

    test('is deterministic (fixed key order, compact JSON)', () {
      final a = mintEventToken(accessKeyId: 'k', secretKey: 's', bucket: 'b', region: 'r');
      final b = mintEventToken(accessKeyId: 'k', secretKey: 's', bucket: 'b', region: 'r');
      expect(a, b);
      // Compact JSON without padding must survive a round-trip.
      expect(a, isNot(contains('=')));
      expect(decodeEventToken(a), {'k': 'k', 's': 's', 'b': 'b', 'r': 'r'});
    });
  });

  group('buildEventUrl validation', () {
    test('appends a trailing slash before the query', () {
      final token = mintEventToken(accessKeyId: 'k', secretKey: 's', bucket: 'b', region: 'r');
      expect(buildEventUrl('https://photos.example.com', token), 'https://photos.example.com/?d=$token');
    });

    test('rejects non-http(s) URLs and URLs with query parts', () {
      final token = mintEventToken(accessKeyId: 'k', secretKey: 's', bucket: 'b', region: 'r');
      expect(() => buildEventUrl('ftp://example.com', token), throwsA(isA<EventTokenFormatException>()));
      expect(() => buildEventUrl('example.com', token), throwsA(isA<EventTokenFormatException>()));
      expect(() => buildEventUrl('https://example.com/?x=1', token), throwsA(isA<EventTokenFormatException>()));
      expect(() => buildEventUrl('   ', token), throwsA(isA<EventTokenFormatException>()));
    });
  });
}
