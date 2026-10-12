import 'package:app/blocs/upload/upload_queue_state.dart';
import 'package:app/models/upload_item.dart';
import 'package:app/modules/landing/file_selection.dart';
import 'package:app/services/storage/s3/upload_error.dart';
import 'package:app/services/storage/storage_service.dart';
import 'package:app/util/name_sanitizer.dart';
import 'package:app/util/uuid_values.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:app/blocs/upload/upload_queue_state.dart';

/// Orchestrates the guest upload queue: batch creation, per-file uploads
/// with byte progress, and retry semantics.
///
/// Uploads run sequentially: the event happens on mobile networks, and one
/// upload at a time keeps progress predictable and per-file failures easy to
/// retry. Retry only re-uploads failed items; there is no full-queue
/// restart — a fresh batch starts from the thank-you screen's
/// upload-more flow.
///
/// The picked file bytes are buffered in browser memory (the web platform
/// keeps picked files in memory anyway) and held here by item ID so retries
/// can re-send without asking the guest to pick the files again.
class UploadQueueCubit extends Cubit<UploadQueueState> {
  UploadQueueCubit({StorageService? storageService, UuidGenerator generateUuid = uuidV4})
    : _storageOverride = storageService,
      _generateUuid = generateUuid,
      super(const UploadQueueState());

  /// Test/restart seam; production resolves [StorageService.instance]
  /// lazily during [start] so the app shell never touches storage
  /// credentials before an upload is actually requested.
  final StorageService? _storageOverride;

  /// UUID4 source; injectable for deterministic cubit tests.
  final UuidGenerator _generateUuid;

  /// Buffered file bytes keyed by [UploadItem.id].
  final Map<String, List<int>> _bytesById = {};

  StorageService get _storage => _storageOverride ?? StorageService.instance;

  /// Creates a new batch from the picked [files] and the optional raw
  /// [guestName], generating exactly one batch UUID4 for all files.
  ///
  /// Any previously queued batch is replaced. Each picked file becomes
  /// exactly one [UploadItem] with an object key following
  /// `{sanitized-name}-{batch-uuid}/{safe-original-filename}`.
  void prepareBatch(String? guestName, List<PickedGuestFile> files) {
    final batchId = _generateUuid();
    _bytesById.clear();
    final items = <UploadItem>[
      for (final file in files)
        () {
          final id = _generateUuid();
          _bytesById[id] = file.bytes;
          return UploadItem(
            id: id,
            originalFileName: file.name,
            sizeBytes: file.sizeBytes,
            objectKey: buildObjectKey(guestName: guestName, batchId: batchId, originalFileName: file.name),
          );
        }(),
    ];
    emit(UploadQueueState(guestName: guestName?.trim() ?? '', batchId: batchId, items: items));
  }

  /// Clears the queue and releases buffered bytes (thank-you screen,
  /// upload-more flow). The next batch gets a fresh batch UUID.
  void reset() {
    _bytesById.clear();
    emit(const UploadQueueState());
  }

  /// Uploads all pending items sequentially.
  ///
  /// No-ops while already uploading so concurrent starts cannot duplicate
  /// transmissions.
  Future<void> start() async {
    if (state.isUploading || state.pendingItems.isEmpty) return;
    emit(state.copyWith(isUploading: true));
    try {
      for (final item in state.pendingItems) {
        await _upload(item);
      }
    } finally {
      emit(state.copyWith(isUploading: false));
    }
  }

  /// Re-uploads only the failed items. Successful items are untouched:
  /// generated object keys are unique, so retrying is always safe, but
  /// re-sending finished files would only waste the guest's data volume.
  Future<void> retryFailed() async {
    if (state.isUploading || !state.hasFailures) return;
    _resetItems((item) => item.status == UploadStatus.failed);
    await start();
  }

  void _resetItems(bool Function(UploadItem item) shouldReset) {
    emit(
      state.copyWith(
        items: [
          for (final item in state.items)
            if (shouldReset(item))
              item.copyWith(status: UploadStatus.pending, bytesSent: 0, errorMessage: null)
            else
              item,
        ],
      ),
    );
  }

  Future<void> _upload(UploadItem item) async {
    _update(item.id, (current) => current.copyWith(status: UploadStatus.uploading, bytesSent: 0, errorMessage: null));
    try {
      await _storage.uploadObject(
        objectKey: item.objectKey,
        data: _bytesById[item.id] ?? const [],
        onProgress: (bytesSent, totalBytes) {
          _update(item.id, (current) => current.copyWith(bytesSent: bytesSent));
        },
      );
      _update(
        item.id,
        (current) => current.copyWith(status: UploadStatus.succeeded, bytesSent: current.sizeBytes, errorMessage: null),
      );
    } on UploadException catch (error, stackTrace) {
      // Typed storage failure: persist the machine marker so the UI can
      // show localized, actionable copy and retry can be classified.
      debugPrint('Upload failed (${error.kind.name}): $error\n$stackTrace');
      _update(item.id, (current) => current.copyWith(status: UploadStatus.failed, errorMessage: error.marker));
    } on StateError catch (error, stackTrace) {
      // Uninitialized storage (no usable configuration). Controlled,
      // actionable failure instead of a crash.
      debugPrint('Storage is not configured; upload failed: $error\n$stackTrace');
      _update(
        item.id,
        (current) => current.copyWith(status: UploadStatus.failed, errorMessage: 'storage-not-configured'),
      );
    } catch (error, stackTrace) {
      debugPrint('Upload failed: $error\n$stackTrace');
      _update(item.id, (current) => current.copyWith(status: UploadStatus.failed, errorMessage: error.toString()));
    }
  }

  void _update(String id, UploadItem Function(UploadItem item) update) {
    emit(
      state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == id) update(item) else item,
        ],
      ),
    );
  }

  @override
  Future<void> close() {
    _bytesById.clear();
    return super.close();
  }
}
