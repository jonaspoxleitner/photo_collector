import 'package:app/app.dart';
import 'package:app/models/event_config.dart';
import 'package:app/modules/landing/file_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fake_storage_service.dart';

/// Valid fixture config shared by the guest-flow widget tests.
const testEventConfig = EventConfig(
  accessKeyId: 'AKIAEXAMPLE00000001',
  secretKey: 'example-secret',
  bucket: 'wedding-20261025',
  region: 'eu-central-1',
);

PickedGuestFile pickedFile(String name, {int sizeBytes = 4096}) =>
    PickedGuestFile(name: name, sizeBytes: sizeBytes, bytes: List<int>.filled(16, 3));

/// Builds the full guest app wired to a [FakeStorageService] and, when
/// provided, a fake [fileSelector]; never touches network or DOM.
Widget buildTestApp({
  EventConfig? eventConfig = testEventConfig,
  Locale locale = const Locale('en'),
  FakeStorageService? storage,
  FileSelector? fileSelector,
}) => PhotoCollectorApp(
  eventConfig: eventConfig,
  locale: locale,
  storageService: storage ?? FakeStorageService(),
  fileSelector: fileSelector,
);

/// The router under test, for direct route navigation.
GoRouter routerOf(WidgetTester tester) {
  final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
  return app.routerConfig! as GoRouter;
}
