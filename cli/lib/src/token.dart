import 'dart:convert';

/// Thrown when event-token inputs or the base URL are invalid. The message
/// never contains credential values.
class EventTokenFormatException implements Exception {
  const EventTokenFormatException(this.message);

  /// Human-readable problem description (safe to print; no secrets).
  final String message;

  @override
  String toString() => 'EventTokenFormatException: $message';
}

/// Mints the `?d=` event token of the locked QR payload format
/// `{base-url}/?d={base64url-json}` with payload `{k, s, b, r, ep?}`.
///
/// The token is the compact-JSON payload UTF-8 encoded and base64url encoded
/// without padding. It must decode to exactly the shared fixture structure in
/// `test_fixtures/event_token_v1.json` (see `test/token_test.dart`).
///
/// Throws [EventTokenFormatException] for empty or whitespace-containing
/// values.
String mintEventToken({
  required String accessKeyId,
  required String secretKey,
  required String bucket,
  required String region,
  String? endpoint,
}) {
  final k = _requiredValue('access key ID', accessKeyId);
  final s = _requiredValue('secret key', secretKey);
  final b = _requiredValue('bucket', bucket);
  final r = _requiredValue('region', region);
  final ep = endpoint == null ? null : _requiredValue('endpoint', endpoint);
  // Insertion order matters for reproducibility: k, s, b, r, ep?
  final payload = <String, String>{'k': k, 's': s, 'b': b, 'r': r, 'ep': ?ep};

  final bytes = utf8.encode(jsonEncode(payload));
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// Builds the full guest URL `{base-url}/?d={token}` from a [baseUrl] and a
/// [token] produced by [mintEventToken].
///
/// Throws [EventTokenFormatException] unless [baseUrl] is an absolute
/// http(s) URL without query or fragment.
String buildEventUrl(String baseUrl, String token) {
  final trimmed = baseUrl.trim();
  if (trimmed.isEmpty) {
    throw const EventTokenFormatException('base URL must not be empty');
  }
  if (trimmed.contains('?') || trimmed.contains('#')) {
    throw const EventTokenFormatException('base URL must not contain query or fragment parts');
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !(uri.isScheme('https') || uri.isScheme('http')) || uri.host.isEmpty) {
    throw const EventTokenFormatException('base URL must be an absolute http(s) URL');
  }
  final withSlash = trimmed.endsWith('/') ? trimmed : '$trimmed/';
  return '$withSlash?d=$token';
}

/// Decodes a token produced by [mintEventToken] back into its payload map.
/// Used for verification and tests.
///
/// Throws [FormatException] for non-base64url input or non-object payloads.
Map<String, Object?> decodeEventToken(String token) {
  final bytes = base64Url.decode(base64Url.normalize(token.trim()));
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('token payload is not a JSON object');
  }
  return decoded;
}

String _requiredValue(String label, String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw EventTokenFormatException('$label must not be empty');
  }
  if (trimmed.contains(RegExp(r'\s'))) {
    throw EventTokenFormatException('$label must not contain whitespace');
  }
  return trimmed;
}
