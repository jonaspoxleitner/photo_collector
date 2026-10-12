import 'dart:ui';

/// Locales supported by the guest app.
const supportedAppLocales = <Locale>[Locale('en'), Locale('de')];

/// Deterministically resolves the app locale.
///
/// - A [testLocale] (only set by tests) always wins.
/// - English and German language codes resolve to their locale, regardless of
///   region (`de-DE`, `de-AT`, `de-CH` -> German; `en-US`, `en-GB` -> English).
/// - Any other device locale, or a missing one, falls back to English.
Locale resolveAppLocale({Locale? deviceLocale, Locale? testLocale}) {
  final locale = testLocale ?? deviceLocale;
  final languageCode = locale?.languageCode.toLowerCase();
  if (languageCode == 'de') {
    return const Locale('de');
  }
  return const Locale('en');
}
