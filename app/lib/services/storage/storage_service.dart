import 'package:app/services/storage/s3/upload_error.dart';
import 'package:meta/meta.dart';

/// Abstraction over object storage writes.
///
/// The production implementation (S3ClientStorageService, backed by
/// `package:s3_client`) uploads directly to S3-compatible storage with
/// client-side SigV4 signing. Tests replace
/// [instance] with a fake; no implementation may require read, list,
/// update, or delete permissions.
///
/// Error contract: implementations throw typed [UploadException] failures
/// (network/CORS, 4xx, 5xx, payload-too-large, cancellation, unknown) so
/// the upload queue can classify retries and the UI can show localized,
/// actionable copy. Untyped exceptions are still surfaced as failures, just
/// without classification. Implementations must never include credentials
/// or signed request material in thrown errors.
abstract class StorageService {
  static StorageService? _instance;

  /// Active storage service.
  ///
  /// Throws [StateError] until the app or a test assigns an implementation.
  static StorageService get instance {
    final service = _instance;
    if (service == null) {
      throw StateError('StorageService.instance has not been initialized.');
    }
    return service;
  }

  /// Replaces the active storage service (used by tests and during app
  /// initialization).
  @visibleForTesting
  static set instance(StorageService service) => _instance = service;

  /// Uploads [data] under [objectKey].
  ///
  /// [onProgress], when provided, receives `(bytesSent, totalBytes)` updates
  /// as bytes are transmitted. Implementations must not persist credentials
  /// or keys beyond the lifetime of the request.
  Future<void> uploadObject({
    required String objectKey,
    required List<int> data,
    void Function(int bytesSent, int totalBytes)? onProgress,
  });
}
