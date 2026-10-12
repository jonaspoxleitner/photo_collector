import 'package:app/common/locale_resolution.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('supportedAppLocales', () {
    test('contains exactly English and German', () {
      expect(supportedAppLocales.length, 2);
      expect(supportedAppLocales, containsAll(const [Locale('en'), Locale('de')]));
    });
  });

  group('resolveAppLocale', () {
    test('German device locale resolves to German', () {
      expect(resolveAppLocale(deviceLocale: const Locale('de')), const Locale('de'));
    });

    test('German regional locales resolve to German', () {
      for (final region in ['DE', 'AT', 'CH']) {
        expect(
          resolveAppLocale(deviceLocale: Locale('de', region)),
          const Locale('de'),
          reason: 'de-$region should resolve to German',
        );
      }
    });

    test('English device locale resolves to English', () {
      expect(resolveAppLocale(deviceLocale: const Locale('en')), const Locale('en'));
    });

    test('English regional locales resolve to English', () {
      for (final region in ['US', 'GB']) {
        expect(
          resolveAppLocale(deviceLocale: Locale('en', region)),
          const Locale('en'),
          reason: 'en-$region should resolve to English',
        );
      }
    });

    test('unsupported device locales fall back to English', () {
      for (final locale in [
        const Locale('fr'),
        const Locale('fr', 'FR'),
        const Locale('ja'),
        const Locale('es', 'MX'),
      ]) {
        expect(
          resolveAppLocale(deviceLocale: locale),
          const Locale('en'),
          reason: '$locale should fall back to English',
        );
      }
    });

    test('missing device locale falls back to English', () {
      expect(resolveAppLocale(), const Locale('en'));
    });

    test('explicit test locale overrides the device locale', () {
      expect(resolveAppLocale(deviceLocale: const Locale('de'), testLocale: const Locale('en')), const Locale('en'));
      expect(resolveAppLocale(deviceLocale: const Locale('en'), testLocale: const Locale('de')), const Locale('de'));
    });
  });
}
