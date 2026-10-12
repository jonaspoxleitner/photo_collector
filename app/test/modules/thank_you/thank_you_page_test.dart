import 'package:app/blocs/upload/upload_queue_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_storage_service.dart';
import '../../helpers/test_app.dart';

void main() {
  group('thank-you page text', () {
    testWidgets('renders all basic text in English', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      routerOf(tester).go('/thanks');
      await tester.pumpAndSettle();

      expect(find.text('Thank you'), findsOneWidget);
      expect(find.text('Thank you for sharing your photos and videos! ❤️'), findsOneWidget);
      expect(
        find.text(
          'Everything arrived safely. '
          'The host will take care of the memories.',
        ),
        findsOneWidget,
      );
      expect(find.text('Upload more photos'), findsOneWidget);
    });

    testWidgets('renders all basic text in German', (tester) async {
      await tester.pumpWidget(buildTestApp(locale: const Locale('de')));
      await tester.pumpAndSettle();
      routerOf(tester).go('/thanks');
      await tester.pumpAndSettle();

      expect(find.text('Danke'), findsOneWidget);
      expect(find.text('Danke, dass du deine Fotos und Videos teilst! ❤️'), findsOneWidget);
      expect(
        find.text(
          'Alles ist sicher angekommen. '
          'Der Gastgeber kümmert sich um die Erinnerungen.',
        ),
        findsOneWidget,
      );
      expect(find.text('Weitere Fotos hochladen'), findsOneWidget);
    });
  });

  group('upload-more flow', () {
    testWidgets('starts a fresh batch and returns to the landing page', (tester) async {
      final storage = FakeStorageService();
      await tester.pumpWidget(
        buildTestApp(storage: storage, fileSelector: ({onProgress}) async => [pickedFile('IMG_0001.JPG')]),
      );
      await tester.pumpAndSettle();

      // Complete one batch so the flow lands on the thank-you screen.
      await tester.tap(find.text('Select photos and videos'));
      await tester.pumpAndSettle();
      expect(storage.calls, hasLength(1));
      expect(routerOf(tester).state.uri.path, '/thanks');

      await tester.tap(find.text('Upload more photos'));
      await tester.pumpAndSettle();

      expect(routerOf(tester).state.uri.path, '/');
      expect(find.text('Share your photos'), findsOneWidget);

      // The queue was reset: no items, no batch left over.
      final context = tester.element(find.byType(Scaffold).first);
      final cubit = context.read<UploadQueueCubit>();
      expect(cubit.state.hasItems, isFalse);
      expect(cubit.state.batchId, isEmpty);
    });
  });
}
