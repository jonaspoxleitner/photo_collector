import 'package:app/app.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import 'package:app/models/event_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _validConfig = EventConfig(
  accessKeyId: 'AKIAEXAMPLE00000001',
  secretKey: 'example-secret',
  bucket: 'wedding-20261025',
  region: 'eu-central-1',
);

void main() {
  testWidgets('application shell registers localized router app', (tester) async {
    await tester.pumpWidget(const PhotoCollectorApp(eventConfig: _validConfig, locale: Locale('en')));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    // The web title/theme-color color matches the scaffold background.
    expect(app.color, const Color(0xFFFFF8F8));
    // Localization delegates are wired up.
    expect(app.localizationsDelegates, isNotEmpty);
    // supportedLocales contains exactly English and German.
    expect(app.supportedLocales.length, 2);
    expect(app.supportedLocales, containsAll(const [Locale('en'), Locale('de')]));
    // Landing route renders its localized title.
    expect(find.text('Share your photos'), findsWidgets);
  });

  testWidgets('explicit test locale renders German strings', (tester) async {
    await tester.pumpWidget(const PhotoCollectorApp(eventConfig: _validConfig, locale: Locale('de')));
    await tester.pumpAndSettle();
    expect(find.text('Teile deine Fotos'), findsWidgets);
  });

  testWidgets('regional German test locale resolves to German', (tester) async {
    await tester.pumpWidget(const PhotoCollectorApp(eventConfig: _validConfig, locale: Locale('de', 'AT')));
    await tester.pumpAndSettle();
    expect(find.text('Teile deine Fotos'), findsWidgets);
  });

  testWidgets('missing event config shows the controlled invalid-config '
      'state instead of throwing', (tester) async {
    await tester.pumpWidget(const PhotoCollectorApp(eventConfig: null, locale: Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Invalid event link'), findsWidgets);
    expect(find.textContaining('scan the event QR code again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('/thanks route is registered through go_router', (tester) async {
    await tester.pumpWidget(const PhotoCollectorApp(eventConfig: _validConfig, locale: Locale('en')));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final router = app.routerConfig! as GoRouter;

    // The dedicated /upload route is gone: upload progress renders
    // inline on the landing page.
    router.go('/thanks');
    await tester.pumpAndSettle();
    expect(find.text('Thank you'), findsWidgets);

    router.go('/');
    await tester.pumpAndSettle();
    expect(find.text('Share your photos'), findsWidgets);
  });

  test('generated localizations load for both supported locales', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final de = await AppLocalizations.delegate.load(const Locale('de'));
    expect(en.appTitle, isNotEmpty);
    expect(de.appTitle, isNotEmpty);
    expect(AppLocalizations.supportedLocales.length, 2);
  });
}
