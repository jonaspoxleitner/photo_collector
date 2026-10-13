import 'package:app/common/router.dart';
import 'package:app/common/url_opener.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildScreen({required UrlOpener openUrl, Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: InvalidConfigScreen(openUrl: openUrl),
);

void main() {
  testWidgets('shows the guest message, host setup hint and GitHub link', (tester) async {
    await tester.pumpWidget(_buildScreen(openUrl: (_) {}));
    await tester.pumpAndSettle();

    expect(find.text('Invalid event link'), findsOneWidget);
    expect(find.textContaining('scan the event QR code again'), findsOneWidget);
    expect(find.textContaining('Are you the host?'), findsOneWidget);
    expect(find.text('Setup instructions on GitHub'), findsOneWidget);
  });

  testWidgets('tapping the link opens the repository URL in a new tab', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(_buildScreen(openUrl: opened.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Setup instructions on GitHub'));
    await tester.pumpAndSettle();

    expect(setUpInstructionsUrl, 'https://github.com/jonaspoxleitner/photo_collector');
    expect(opened, [setUpInstructionsUrl]);
  });

  testWidgets('renders the localized German setup strings', (tester) async {
    await tester.pumpWidget(_buildScreen(openUrl: (_) {}, locale: const Locale('de')));
    await tester.pumpAndSettle();

    expect(find.text('Ungültiger Event-Link'), findsOneWidget);
    expect(find.textContaining('Bist du der Gastgeber?'), findsOneWidget);
    expect(find.text('Einrichtungs-Anleitung auf GitHub'), findsOneWidget);
  });
}
