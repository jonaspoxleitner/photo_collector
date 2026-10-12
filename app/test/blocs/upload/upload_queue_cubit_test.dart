import 'package:app/blocs/upload/upload_queue_cubit.dart';
import 'package:app/models/upload_item.dart';
import 'package:app/modules/landing/file_selection.dart';
import 'package:app/services/storage/s3/upload_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_storage_service.dart';

/// Deterministic, valid UUID4-shaped ids for the cubit under test.
String Function() deterministicUuids() {
  var counter = 0;
  return () {
    counter++;
    final hex = counter.toRadixString(16).padLeft(12, '0');
    return '00000000-0000-4000-8000-$hex';
  };
}

PickedGuestFile fakeFile(String name, {int bytes = 16}) =>
    PickedGuestFile(name: name, sizeBytes: bytes, bytes: List<int>.filled(bytes, 7));

UploadQueueCubit buildCubit(FakeStorageService storage) =>
    UploadQueueCubit(storageService: storage, generateUuid: deterministicUuids());

void main() {
  group('batch creation', () {
    test('each selected file becomes exactly one upload item', () {
      final cubit = buildCubit(FakeStorageService());
      cubit.prepareBatch('Jonas', [fakeFile('a.jpg'), fakeFile('b.mov'), fakeFile('c.png')]);

      expect(cubit.state.items.length, 3);
      expect(cubit.state.items.map((item) => item.originalFileName), ['a.jpg', 'b.mov', 'c.png']);
      expect(cubit.state.items.every((item) => item.status == UploadStatus.pending), isTrue);
    });

    test('generates one batch UUID reused for every file of the batch', () {
      final cubit = buildCubit(FakeStorageService());
      cubit.prepareBatch('Jonas', [fakeFile('a.jpg'), fakeFile('b.jpg')]);

      final state = cubit.state;
      expect(state.batchId, '00000000-0000-4000-8000-000000000001');
      for (final item in state.items) {
        expect(item.objectKey, contains('-${state.batchId}/'));
      }
    });

    test('object keys follow {sanitized-name}-{batch-uuid}/{safe-filename}', () {
      final cubit = buildCubit(FakeStorageService());
      cubit.prepareBatch('  Müller, Anna  ', [fakeFile('My Photo (1).JPG')]);

      expect(
        cubit.state.items.single.objectKey,
        'mueller-anna-00000000-0000-4000-8000-000000000001/'
        'My-Photo-1-.JPG',
      );
    });

    test('empty names use the anonymous sanitized folder', () {
      final cubit = buildCubit(FakeStorageService());
      cubit.prepareBatch(null, [fakeFile('a.jpg')]);
      expect(cubit.state.items.single.objectKey, startsWith('anonymous-'));

      cubit.prepareBatch('   ', [fakeFile('a.jpg')]);
      expect(cubit.state.items.single.objectKey, startsWith('anonymous-'));

      cubit.prepareBatch('!!!', [fakeFile('a.jpg')]);
      expect(cubit.state.items.single.objectKey, startsWith('anonymous-'));
    });

    test('file names cannot introduce traversal or duplicate separators', () {
      final cubit = buildCubit(FakeStorageService());
      cubit.prepareBatch(r'../../evil//name', [fakeFile(r'../../etc/passwd'), fakeFile('a//b\\c.jpg')]);

      for (final item in cubit.state.items) {
        final segments = item.objectKey.split('/');
        expect(segments.length, 2, reason: 'expected exactly name-batch/file, got ${item.objectKey}');
        expect(item.objectKey, isNot(contains('..')));
        expect(item.objectKey, isNot(contains('//')));
        expect(item.objectKey, isNot(contains(r'\')));
      }
      expect(cubit.state.items[0].objectKey, endsWith('/passwd'));
      expect(cubit.state.items[1].objectKey, endsWith('/c.jpg'));
    });
  });

  group('upload flow', () {
    test('start uploads every pending item and reports byte progress', () async {
      final storage = FakeStorageService();
      final cubit = buildCubit(storage);
      cubit.prepareBatch('Jonas', [fakeFile('a.jpg'), fakeFile('b.mov')]);

      await cubit.start();

      expect(cubit.state.allSucceeded, isTrue);
      expect(cubit.state.isUploading, isFalse);
      expect(storage.calls.map((call) => call.objectKey), cubit.state.items.map((item) => item.objectKey));
      // The final progress emission of each call reports every byte.
      for (final call in storage.calls) {
        expect(call.progress.last.bytesSent, call.data.length);
        expect(call.progress.last.totalBytes, call.data.length);
      }
    });

    test('a failing item ends failed with an error and does not block others', () async {
      final storage = FakeStorageService()..shouldFail = (key) => key.endsWith('b.mov');
      final cubit = buildCubit(storage);
      cubit.prepareBatch(null, [fakeFile('a.jpg'), fakeFile('b.mov')]);

      await cubit.start();

      expect(cubit.state.items[0].status, UploadStatus.succeeded);
      expect(cubit.state.items[1].status, UploadStatus.failed);
      expect(cubit.state.items[1].errorMessage, isNotNull);
      expect(cubit.state.hasFailures, isTrue);
      expect(cubit.state.allSucceeded, isFalse);
    });

    test('retryFailed is a no-op when nothing failed', () async {
      final storage = FakeStorageService();
      final cubit = buildCubit(storage);
      cubit.prepareBatch(null, [fakeFile('a.jpg'), fakeFile('b.mov')]);

      await cubit.start();
      expect(cubit.state.allSucceeded, isTrue);
      expect(storage.calls.length, 2);

      await cubit.retryFailed();

      // Nothing to retry: no additional transmissions.
      expect(storage.calls.length, 2);
      expect(cubit.state.allSucceeded, isTrue);
    });

    test('retryFailed re-uploads only the failed subset, never successes', () async {
      var failVideo = true;
      final storage = FakeStorageService()..shouldFail = (key) => failVideo && key.endsWith('b.mov');
      final cubit = buildCubit(storage);
      cubit.prepareBatch(null, [fakeFile('a.jpg'), fakeFile('b.mov')]);

      await cubit.start();
      expect(storage.calls.length, 2);

      failVideo = false;
      await cubit.retryFailed();

      expect(storage.calls.length, 3);
      expect(storage.calls.last.objectKey, endsWith('/b.mov'));
      expect(cubit.state.allSucceeded, isTrue);
    });

    test('concurrent start calls cannot duplicate transmissions', () async {
      final storage = FakeStorageService();
      final cubit = buildCubit(storage);
      cubit.prepareBatch(null, [fakeFile('a.jpg')]);

      await Future.wait([cubit.start(), cubit.start(), cubit.start()]);

      expect(storage.calls.length, 1);
    });

    test('typed storage failures keep their kind as the error marker', () async {
      final storage = FakeStorageService()
        ..shouldFail = ((key) => key.endsWith('b.mov'))
        ..errorFactory = ((_) => const UploadException(UploadErrorKind.networkOrCors, message: 'simulated'));
      final cubit = buildCubit(storage);
      cubit.prepareBatch(null, [fakeFile('a.jpg'), fakeFile('b.mov')]);

      await cubit.start();

      expect(cubit.state.items[0].status, UploadStatus.succeeded);
      expect(cubit.state.items[1].status, UploadStatus.failed);
      expect(cubit.state.items[1].errorMessage, 'upload-error.networkOrCors');
    });
  });

  group('queue lifecycle', () {
    test('reset clears items, batch, and buffered bytes', () {
      final cubit = buildCubit(FakeStorageService());
      cubit.prepareBatch('Jonas', [fakeFile('a.jpg')]);
      expect(cubit.state.hasItems, isTrue);

      cubit.reset();

      expect(cubit.state.hasItems, isFalse);
      expect(cubit.state.batchId, isEmpty);
      expect(cubit.state.guestName, isEmpty);
    });

    test('a new batch gets a fresh batch UUID', () {
      final cubit = buildCubit(FakeStorageService());
      cubit.prepareBatch('Jonas', [fakeFile('a.jpg')]);
      final firstBatch = cubit.state.batchId;

      cubit.reset();
      cubit.prepareBatch('Jonas', [fakeFile('a.jpg')]);

      expect(cubit.state.batchId, isNot(firstBatch));
    });
  });
}
