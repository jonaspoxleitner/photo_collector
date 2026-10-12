import 'package:app/models/upload_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_queue_state.freezed.dart';

/// Immutable state of the guest upload queue.
@freezed
class UploadQueueState with _$UploadQueueState {
  const factory UploadQueueState({
    /// Raw guest name as entered; empty when the guest stayed anonymous.
    @Default('') String guestName,

    /// UUID4 generated once per guest upload batch and reused for the
    /// object keys of every file in the batch.
    @Default('') String batchId,

    /// Queued files with per-file status, progress, and error state.
    @Default(<UploadItem>[]) List<UploadItem> items,

    @Default(false) bool isUploading,
  }) = _UploadQueueState;

  const UploadQueueState._();

  List<UploadItem> get pendingItems =>
      items.where((item) => item.status == UploadStatus.pending).toList(growable: false);

  List<UploadItem> get failedItems => items.where((item) => item.status == UploadStatus.failed).toList(growable: false);

  List<UploadItem> get succeededItems =>
      items.where((item) => item.status == UploadStatus.succeeded).toList(growable: false);

  bool get hasItems => items.isNotEmpty;

  /// True when at least one upload failed and can be retried.
  bool get hasFailures => failedItems.isNotEmpty;

  /// True when at least one file was queued and every single upload
  /// succeeded; triggers the thank-you navigation.
  bool get allSucceeded => items.isNotEmpty && items.every((item) => item.status == UploadStatus.succeeded);

  /// True when uploads are done and nothing failed.
  bool get completedWithoutFailures => allSucceeded && !isUploading;
}
