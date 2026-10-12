import 'dart:typed_data';

import 'package:app/common/environment.dart';
import 'package:app/models/event_config.dart';
import 'package:app/services/storage/s3/upload_error.dart';
import 'package:app/services/storage/s3/upload_timeout.dart';
import 'package:app/services/storage/storage_service.dart';
import 'package:ctx/ctx.dart';
import 'package:http/http.dart' as http;
import 'package:s3_client/s3_client.dart';

/// Direct PUT uploads from the browser to S3-compatible storage, backed by
/// `package:s3_client`. (Replaces the hand-rolled signer/transport, which
/// was removed after the real-event smoke test validated this backend.)
///
/// Why the package fits here (verified against its source):
///
/// - The region is configured explicitly — no `s3:GetBucketLocation`
///   discovery call, so the guest's PutObject-only IAM policy is
///   sufficient.
/// - Streamed bodies are signed with `UNSIGNED-PAYLOAD`, so no file bytes
///   are hashed in the browser. (In-memory byte bodies would be SHA-256
///   hashed; this service always sends a stream.)
/// - `putObject` is exactly one HTTP PUT. Multipart never happens unless
///   explicitly orchestrated, matching the single-PUT design and its
///   [maxUploadBytes] ceiling.
///
/// Differences from the previous hand-rolled implementation (all accepted
/// deliberately):
///
/// - No per-byte upload progress: the browser transport is `fetch`, which
///   buffers the request body. [onProgress] is reported only as
///   `(0, total)` at start and `(total, total)` on success; the UI shows
///   file-count progress ("x of y uploaded") since the upload-screen
///   removal, so byte granularity is not needed.
/// - Stall detection uses a [Context] deadline ([uploadTimeoutFor]) that
///   aborts the `fetch` request, so a stuck upload fails and becomes
///   retryable instead of hanging the sequential queue.
class S3ClientStorageService extends StorageService {
  S3ClientStorageService({required this.config, S3Client? client, this.maxUploadBytes = Environment.maxSinglePutBytes})
    : _client = client;

  /// Parsed event/storage configuration from the `?d=` token.
  final EventConfig config;

  /// Client-side single-PUT payload ceiling; defaults to the documented
  /// [Environment.maxSinglePutBytes] (2 GB). Injectable for tests.
  final int maxUploadBytes;

  /// Lazily created so constructing the service in VM tests never builds
  /// an HTTP client unless one is injected.
  S3Client? _client;

  S3Client get _effectiveClient => _client ??= _buildClient();

  S3Client _buildClient() {
    final credentials = S3CredentialsProvider.static(
      accessKeyId: config.accessKeyId,
      secretAccessKey: config.secretKey,
    );
    final endpoint = config.endpoint;
    if (endpoint == null) {
      // AWS S3, virtual-hosted style: https://{bucket}.s3.{region}.amazonaws.com/{key}
      return S3Client.aws(region: config.region, credentials: credentials);
    }
    // Custom S3-compatible endpoint, path style (same as S3StorageService).
    final normalized = endpoint.startsWith(RegExp('https?://')) ? endpoint : 'https://$endpoint';
    return S3Client(
      baseEndpoint: Uri.parse(normalized.replaceAll(RegExp(r'/+$'), '')),
      region: config.region,
      credentials: credentials,
      usePathStyle: true,
    );
  }

  @override
  Future<void> uploadObject({
    required String objectKey,
    required List<int> data,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async {
    if (data.length > maxUploadBytes) {
      throw UploadException(
        UploadErrorKind.payloadTooLarge,
        message: 'payload exceeds the $maxUploadBytes-byte single-PUT limit',
      );
    }

    final body = data is Uint8List ? data : Uint8List.fromList(data);
    final (ctx, cancel) = Context.empty().withTimeout(uploadTimeoutFor(body.length));
    onProgress?.call(0, body.length);
    try {
      await _effectiveClient.putObject(
        bucket: config.bucket,
        key: objectKey,
        // Streamed bodies are signed with UNSIGNED-PAYLOAD by s3_client.
        body: Stream<Uint8List>.value(body),
        contentLength: body.length,
        ctx: ctx,
      );
      onProgress?.call(body.length, body.length);
    } on S3Exception catch (e) {
      throw _mapS3Exception(e);
    } on ContextTimeoutException {
      throw const UploadException(
        UploadErrorKind.networkOrCors,
        message: 'upload deadline exceeded (stalled or very slow connection)',
      );
    } on ContextCancelException {
      throw const UploadException(UploadErrorKind.cancelled, message: 'upload cancelled');
    } on http.ClientException {
      // fetch/XHR failures: no connectivity, DNS failure, or —
      // indistinguishable in the browser — a CORS preflight rejection.
      throw const UploadException(
        UploadErrorKind.networkOrCors,
        message: 'no response from storage (network failure or CORS rejection)',
      );
    } finally {
      cancel();
    }
  }

  /// Maps an s3_client exception onto the [UploadException] contract.
  ///
  /// `S3Exception` carries only the provider error [S3Exception.code] and a
  /// message, never the HTTP status. When the body was not valid S3 error
  /// XML, s3_client falls back to using the numeric status as the code.
  ///
  /// The exception message is deliberately **not** propagated: provider
  /// messages can echo credential material (e.g. `InvalidAccessKeyId`
  /// includes the access key ID), which the [UploadException] contract
  /// forbids.
  static UploadException _mapS3Exception(S3Exception e) {
    if (e is S3EntityTooLargeException) {
      return UploadException(UploadErrorKind.payloadTooLarge, providerErrorCode: e.code);
    }
    final status = int.tryParse(e.code);
    if (status != null) {
      if (status == 413) {
        return UploadException(UploadErrorKind.payloadTooLarge, httpStatus: status);
      }
      if (status >= 400 && status < 500) {
        return UploadException(UploadErrorKind.clientError, httpStatus: status);
      }
      if (status >= 500) {
        return UploadException(UploadErrorKind.serverError, httpStatus: status);
      }
      return UploadException(UploadErrorKind.unknown, httpStatus: status);
    }
    // Named S3 error codes: no HTTP status available. The named codes are
    // overwhelmingly 4xx; the only 5xx ones are the transient trio below.
    // (S3RequestTimeoutException is a 400 but means "connection stalled
    // mid-upload"; retry is still offered by the UI for all failures.)
    const serverErrorCodes = {'InternalError', 'ServiceUnavailable', 'SlowDown'};
    if (serverErrorCodes.contains(e.code)) {
      return UploadException(UploadErrorKind.serverError, providerErrorCode: e.code);
    }
    return UploadException(UploadErrorKind.clientError, providerErrorCode: e.code);
  }
}
