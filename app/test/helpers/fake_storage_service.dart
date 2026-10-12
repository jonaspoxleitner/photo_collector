import 'dart:async';

import 'package:app/services/storage/storage_service.dart';

/// Error thrown by [FakeStorageService] for configured failures.
class FakeStorageException implements Exception {
  const FakeStorageException(this.message);

  final String message;

  @override
  String toString() => 'FakeStorageException: $message';
}

/// One recorded upload request.
class FakeUploadCall {
  FakeUploadCall({required this.objectKey, required this.data});

  /// Object key the upload was signed/queued under.
  final String objectKey;

  /// Buffered bytes of the upload request.
  final List<int> data;

  /// Observed `(bytesSent, totalBytes)` progress emissions.
  final List<({int bytesSent, int totalBytes})> progress = [];
}

/// Deterministic, controllable [StorageService] for widget and cubit tests.
///
/// Never touches the network. Behavior knobs:
/// - [shouldFail]: returns true for keys that must throw
///   [FakeStorageException].
/// - [gate]: when set, uploads wait for this completer before finishing
///   (used to observe in-flight UI states).
/// - [progressSteps]: number of progress emissions per successful upload.
class FakeStorageService extends StorageService {
  /// Calls received so far, in upload order.
  final List<FakeUploadCall> calls = [];

  /// Failure predicate keyed on the object key.
  bool Function(String objectKey)? shouldFail;

  /// Error factory for failed keys. Defaults to [FakeStorageException];
  /// set to produce typed errors (e.g. `UploadException`) for
  /// error-classification tests.
  Object Function(String objectKey)? errorFactory;

  /// When non-null, every upload awaits this completer before resolving.
  Completer<void>? gate;

  /// Number of emitted progress updates per upload (final one reports all
  /// bytes sent).
  int progressSteps = 3;

  /// Object keys of successful uploads.
  List<String> get uploadedKeys =>
      calls.where((call) => shouldFail == null || !shouldFail!(call.objectKey)).map((call) => call.objectKey).toList();

  @override
  Future<void> uploadObject({
    required String objectKey,
    required List<int> data,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async {
    final call = FakeUploadCall(objectKey: objectKey, data: data);
    calls.add(call);
    final total = data.length;
    for (var step = 1; step <= progressSteps; step++) {
      final sent = (total * step / progressSteps).round();
      call.progress.add((bytesSent: sent, totalBytes: total));
      onProgress?.call(sent, total);
      await Future<void>.value();
    }
    final pendingGate = gate;
    if (pendingGate != null) {
      await pendingGate.future;
    }
    if (shouldFail?.call(objectKey) ?? false) {
      throw errorFactory?.call(objectKey) ?? FakeStorageException('upload failed for "$objectKey"');
    }
  }
}
