import 'dart:async';
import 'dart:io' as io;

import 'package:app/modules/landing/file_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_storage_service.dart';
import '../../helpers/test_app.dart';

void main() {
  group('landing page text', () {
    testWidgets('renders all basic text in English', (tester) async {
      await tester.pumpWidget(buildTestApp(fileSelector: ({onProgress}) async => []));
      await tester.pumpAndSettle();

      expect(find.text('Share your photos'), findsOneWidget);
      expect(
        find.text('Add your favorite photos and videos — straight from your phone, no app install, no account.'),
        findsOneWidget,
      );
      expect(find.text('Your name (optional)'), findsOneWidget);
      expect(find.text('Select photos and videos'), findsOneWidget);
      expect(find.text('Leave it empty if you prefer to stay anonymous.'), findsOneWidget);
    });

    testWidgets('renders all basic text in German', (tester) async {
      await tester.pumpWidget(buildTestApp(locale: const Locale('de'), fileSelector: ({onProgress}) async => []));
      await tester.pumpAndSettle();

      expect(find.text('Teile deine Fotos'), findsOneWidget);
      expect(
        find.text('Füge deine schönsten Fotos und Videos hinzu — direkt vom Handy, ohne App, ohne Konto.'),
        findsOneWidget,
      );
      expect(find.text('Dein Name (optional)'), findsOneWidget);
      expect(find.text('Fotos und Videos auswählen'), findsOneWidget);
      expect(find.text('Lass das Feld leer, wenn du anonym bleiben möchtest.'), findsOneWidget);
    });

    testWidgets('does not show the internal bucket name', (tester) async {
      for (final locale in const [Locale('en'), Locale('de')]) {
        await tester.pumpWidget(buildTestApp(locale: locale, fileSelector: ({onProgress}) async => []));
        await tester.pumpAndSettle();
        expect(find.textContaining('wedding-20261025'), findsNothing);
      }
    });
  });

  group('landing flow', () {
    testWidgets('guest can continue without entering a name', (tester) async {
      final storage = FakeStorageService();
      await tester.pumpWidget(
        buildTestApp(storage: storage, fileSelector: ({onProgress}) async => [pickedFile('IMG_0001.JPG')]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select photos and videos'));
      await tester.pumpAndSettle();

      expect(storage.calls.length, 1);
      expect(storage.calls.single.objectKey, matches(r'^anonymous-[0-9a-f-]{36}/IMG_0001\.JPG$'));
      // Successful upload auto-completes to the thank-you screen.
      expect(find.text('Thank you'), findsWidgets);
    });

    testWidgets('an entered name prefixes the object key, sanitized', (tester) async {
      final storage = FakeStorageService();
      await tester.pumpWidget(
        buildTestApp(storage: storage, fileSelector: ({onProgress}) async => [pickedFile('IMG_0001.JPG')]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  Jonas   Poxleitner ');
      await tester.tap(find.text('Select photos and videos'));
      await tester.pumpAndSettle();

      expect(storage.calls.length, 1);
      expect(storage.calls.single.objectKey, matches(r'^jonas-poxleitner-[0-9a-f-]{36}/IMG_0001\.JPG$'));
    });

    testWidgets('a slow selection shows preparing progress', (tester) async {
      final completer = Completer<List<PickedGuestFile>>();
      await tester.pumpWidget(
        buildTestApp(
          fileSelector: ({onProgress}) {
            // Buffering files takes a while: report progress, then hang.
            onProgress?.call(1, 3);
            return completer.future;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select photos and videos'));
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.text('Preparing file 1 of 3…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Selection finishes; the preparing state disappears.
      completer.complete([]);
      await tester.pumpAndSettle();
      expect(find.text('Preparing file 1 of 3…'), findsNothing);
    });

    testWidgets('a stuck preparation can be cancelled by the guest', (tester) async {
      final storage = FakeStorageService();
      // Selector that never resolves: simulates a browser file read that
      // hangs forever.
      await tester.pumpWidget(
        buildTestApp(storage: storage, fileSelector: ({onProgress}) => Completer<List<PickedGuestFile>>().future),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select photos and videos'));
      await tester.pump();
      expect(find.text('Waiting for the file picker…'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Back to the idle, fully interactive landing page.
      expect(find.text('Waiting for the file picker…'), findsNothing);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
      expect(storage.calls, isEmpty);
    });

    testWidgets('cancelling the picker stays on the landing page', (tester) async {
      final storage = FakeStorageService();
      await tester.pumpWidget(buildTestApp(storage: storage, fileSelector: ({onProgress}) async => []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select photos and videos'));
      await tester.pumpAndSettle();

      expect(storage.calls, isEmpty);
      expect(find.text('Select photos and videos'), findsOneWidget);
    });

    testWidgets('invalid event config prevents selection and explains next '
        'steps', (tester) async {
      await tester.pumpWidget(
        buildTestApp(eventConfig: null, fileSelector: ({onProgress}) async => [pickedFile('IMG_0001.JPG')]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invalid event link'), findsOneWidget);
      expect(find.textContaining('scan the event QR code again'), findsOneWidget);
      // The file-selection affordances are not offered at all.
      expect(find.text('Select photos and videos'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('inline upload status', () {
    final files = [pickedFile('IMG_0001.JPG'), pickedFile('party-video.mp4')];

    /// Pumps the app, picks [files] through the landing flow, and returns
    /// the fake storage the app under test is wired to.
    Future<FakeStorageService> startUploadFlow(
      WidgetTester tester, {
      required List<PickedGuestFile> files,
      FakeStorageService? storage,
      Locale locale = const Locale('en'),
    }) async {
      final effectiveStorage = storage ?? FakeStorageService();
      await tester.pumpWidget(
        buildTestApp(locale: locale, storage: effectiveStorage, fileSelector: ({onProgress}) async => files),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(locale.languageCode == 'de' ? 'Fotos und Videos auswählen' : 'Select photos and videos'),
      );
      await tester.pump();
      return effectiveStorage;
    }

    testWidgets('shows aggregate progress inline without per-file details '
        'while uploading', (tester) async {
      final gate = Completer<void>();
      final storage = FakeStorageService()..gate = gate;
      await startUploadFlow(tester, files: files, storage: storage);
      await tester.pump();

      // The guest stays on the landing page; no navigation to /upload.
      expect(routerOf(tester).state.uri.path, '/');
      expect(find.text('0 of 2 uploaded'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(bar.value, 0.0);
      // No per-file detail: neither names nor per-file status labels.
      expect(find.text('IMG_0001.JPG'), findsNothing);
      expect(find.text('party-video.mp4'), findsNothing);
      expect(find.text('Uploading…'), findsNothing);
      expect(find.text('Waiting'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      // Full success auto-navigates to the thank-you screen.
      expect(routerOf(tester).state.uri.path, '/thanks');
      expect(find.text('Thank you'), findsWidgets);
    });

    testWidgets('name field and select button are disabled while uploading', (tester) async {
      final gate = Completer<void>();
      final storage = FakeStorageService()..gate = gate;
      await startUploadFlow(tester, files: files, storage: storage);
      await tester.pump();

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Select photos and videos'));
      expect(button.onPressed, isNull);

      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('failure shows one error line and retry re-sends only the '
        'failed file', (tester) async {
      var failVideo = true;
      final storage = FakeStorageService()..shouldFail = (key) => failVideo && key.endsWith('party-video.mp4');
      await startUploadFlow(tester, files: files, storage: storage);
      await tester.pumpAndSettle();

      // Still on the landing page with one success, one failure.
      expect(routerOf(tester).state.uri.path, '/');
      expect(find.text('1 of 2 uploaded'), findsOneWidget);
      expect(find.text('1 of 2 uploads failed — you can retry below.'), findsOneWidget);
      expect(find.text('Retry failed'), findsOneWidget);
      // Still no per-file status labels.
      expect(find.text('Failed'), findsNothing);
      expect(find.text('Done'), findsNothing);

      failVideo = false;
      await tester.tap(find.text('Retry failed'));
      await tester.pumpAndSettle();

      // Retry touched only the failed file, then success navigated away.
      expect(storage.calls.length, 3);
      expect(storage.calls.last.objectKey, endsWith('/party-video.mp4'));
      expect(routerOf(tester).state.uri.path, '/thanks');
    });

    testWidgets('inline upload status renders in German', (tester) async {
      var failVideo = true;
      final storage = FakeStorageService()..shouldFail = (key) => failVideo && key.endsWith('party-video.mp4');
      await startUploadFlow(tester, files: files, storage: storage, locale: const Locale('de'));
      await tester.pumpAndSettle();

      expect(routerOf(tester).state.uri.path, '/');
      expect(find.text('1 von 2 hochgeladen'), findsOneWidget);
      expect(find.text('1 von 2 Uploads sind fehlgeschlagen — du kannst sie unten erneut versuchen.'), findsOneWidget);
      expect(find.text('Fehlgeschlagene erneut versuchen'), findsOneWidget);

      failVideo = false;
      await tester.tap(find.text('Fehlgeschlagene erneut versuchen'));
      await tester.pumpAndSettle();
      expect(find.text('Danke'), findsWidgets);
    });
  });

  group('file picker contract', () {
    test('the picker uses multiple-selection pickFiles, restricts to '
        'media extensions, buffers bytes, and never sets the restrictive '
        'capture attribute', () {
      var source = io.File('lib/modules/landing/file_selection_web.dart').readAsStringSync();
      // Strip doc/comment lines: the rationale mentions the forbidden
      // attribute, only the imperative code may not.
      source = source.split('\n').where((line) => !line.trimLeft().startsWith('//')).join('\n');
      // pickFiles is multiple-selection in file_picker 13; pickFile is
      // the single-selection variant and must not be used.
      expect(source, contains('FilePicker.pickFiles('));
      expect(source, contains('type: FileType.custom'));
      expect(source, contains('readAsBytes()'));
      expect(source, isNot(contains('capture')));
    });
  });
}
