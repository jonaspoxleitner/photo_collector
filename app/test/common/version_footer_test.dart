import 'package:app/common/version_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the semantic pubspec version', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(bottomNavigationBar: VersionFooter(loadVersion: () async => '1.2.3')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Version 1.2.3'), findsOneWidget);
  });

  testWidgets('hides instead of fabricating a version when package info is '
      'unavailable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: VersionFooter(loadVersion: () async => throw StateError('no package info')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Version'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
