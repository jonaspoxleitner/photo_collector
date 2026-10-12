import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_item.freezed.dart';

/// Lifecycle status of one queued upload.
enum UploadStatus {
  /// Queued, not yet transmitted.
  pending,

  /// Currently uploading; [UploadItem.bytesSent] tracks transmitted bytes.
  uploading,

  /// Stored successfully.
  succeeded,

  /// Upload failed; the raw detail is kept in [UploadItem.errorMessage].
  failed,
}

/// One queued guest file.
///
/// Beyond the identity and archive naming contract established in Phase 1,
/// this model carries the per-file status, byte progress, and error state
/// the upload queue needs to render and retry individual files.
@freezed
class UploadItem with _$UploadItem {
  const factory UploadItem({
    /// Stable ID for this queue entry.
    required String id,

    /// File name as picked by the guest (display only).
    required String originalFileName,

    /// Size of the picked file in bytes.
    required int sizeBytes,

    /// Archive-safe storage object key following
    /// `{sanitized-name}-{batch-uuid}/{safe-original-filename}`.
    required String objectKey,

    @Default(UploadStatus.pending) UploadStatus status,

    @Default(0) int bytesSent,

    /// Raw storage error detail, set when [status] is
    /// [UploadStatus.failed]. Never shown to guests verbatim.
    String? errorMessage,
  }) = _UploadItem;

  const UploadItem._();

  bool get isUploading => status == UploadStatus.uploading;

  /// Upload fraction between 0 and 1 for progress indicators.
  ///
  /// Stays at 0 while pending or when the size is unknown, and is exactly 1
  /// for succeeded items regardless of the recorded bytes.
  double get progress {
    if (status == UploadStatus.succeeded) return 1;
    if (sizeBytes <= 0) return 0;
    return (bytesSent / sizeBytes).clamp(0.0, 1.0);
  }
}
