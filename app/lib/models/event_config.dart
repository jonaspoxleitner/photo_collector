import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_config.freezed.dart';

/// Parsed event and storage configuration decoded from the QR code token.
///
/// The credentials are write-only and bucket-scoped: they may create objects
/// in [bucket] but never read, list, update, or delete.
@freezed
class EventConfig with _$EventConfig {
  const factory EventConfig({
    /// Access key ID of the per-event storage credentials (`k`).
    required String accessKeyId,

    /// Secret key of the per-event storage credentials (`s`).
    required String secretKey,

    /// Bucket named after the event, e.g. `wedding-20261025` (`b`).
    required String bucket,

    /// Signing region of the bucket (`r`).
    required String region,

    /// Optional custom S3-compatible endpoint (`ep?`). Null targets AWS S3.
    String? endpoint,
  }) = _EventConfig;

  const EventConfig._();

  /// True when a custom S3-compatible endpoint is configured.
  bool get hasCustomEndpoint => endpoint != null;
}
