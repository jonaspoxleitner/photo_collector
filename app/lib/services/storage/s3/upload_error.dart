/// Typed, retry-aware storage failure classification for guest uploads.
///
/// Every failure the guest can hit while uploading directly to S3-compatible
/// storage maps to one [UploadErrorKind]. The UI keys guest-facing copy off
/// these kinds; raw responses are never shown (they can echo parts of the
/// signed request, e.g. the access key ID).
enum UploadErrorKind {
  /// The transport failed before a response arrived: no connectivity, DNS
  /// failure, request timeout, or — indistinguishable in the browser — a
  /// CORS preflight rejection by the storage provider.
  networkOrCors,

  /// The storage answered with a 4xx status (except payload-size
  /// rejections, mapped to [payloadTooLarge]). Typically a revoked or
  /// invalid credential (`403`), a missing bucket (`404`), or a policy
  /// rejection.
  clientError,

  /// The storage answered with a 5xx status.
  serverError,

  /// S3 specifically rejected the payload because it exceeds the single-PUT
  /// limit (HTTP 413) or the client-side maximum before the request was
  /// even sent.
  payloadTooLarge,

  /// The upload was aborted (guest closed/cancelled or the browser
  /// terminated the request) before a response arrived.
  cancelled,

  /// Anything that does not fit the categories above.
  unknown,
}

/// A storage upload failure with typed classification.
///
/// Deliberately carries no request details that could leak credentials into
/// logs: [toString] exposes only the kind, an optional HTTP status, and an
/// optional provider error code. The provider error code (e.g. S3's
/// `SignatureDoesNotMatch`) contains no secrets.
class UploadException implements Exception {
  const UploadException(this.kind, {this.httpStatus, this.providerErrorCode, this.message});

  /// Machine classification for retry and UI decisions.
  final UploadErrorKind kind;

  /// HTTP status when the storage answered, otherwise null.
  final int? httpStatus;

  /// Provider error code extracted from the response body, when available.
  final String? providerErrorCode;

  /// Additional diagnostic detail; never contains credentials or keys.
  final String? message;

  /// Whether retrying this upload can plausibly succeed.
  ///
  /// Network, CORS, and 5xx failures are transient. Client errors
  /// (revoked credentials, policy rejections) and oversized payloads will
  /// fail again until the configuration changes; retrying them is still
  /// offered to the guest (the host may have fixed the setup), but the UI
  /// copy states the likely cause. Cancellation is user intent.
  bool get isRetryable => switch (kind) {
    UploadErrorKind.clientError || UploadErrorKind.payloadTooLarge => false,
    UploadErrorKind.networkOrCors ||
    UploadErrorKind.serverError ||
    UploadErrorKind.cancelled ||
    UploadErrorKind.unknown => true,
  };

  /// Short, log-safe marker persisted on the failed upload item and mapped
  /// to localized guest copy by the UI.
  String get marker => 'upload-error.${kind.name}';

  @override
  String toString() =>
      'UploadException(kind: ${kind.name}'
      '${httpStatus != null ? ', status: $httpStatus' : ''}'
      '${providerErrorCode != null ? ', code: $providerErrorCode' : ''}'
      '${message != null ? ', $message' : ''})';
}
