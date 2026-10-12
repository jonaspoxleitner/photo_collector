import 'dart:convert';

import 'package:app/models/event_config.dart';

/// Thrown when the `?d=` event token cannot be decoded into a valid
/// [EventConfig]. Callers must treat this as a controlled invalid-config
/// state, never as an unhandled exception.
class EventTokenException implements Exception {
  const EventTokenException(this.reason);

  /// Machine-readable rejection reason (never contains token contents).
  final String reason;

  @override
  String toString() => 'EventTokenException: $reason';
}

/// Decodes the `?d=` token of the QR payload format
/// `{base-url}/?d={base64url-json}` into an [EventConfig].
///
/// Returns `null` when [token] is null, empty, or whitespace only (missing
/// token is a controlled invalid-config state, not a malformed one).
///
/// Throws [EventTokenException] for non-base64url input, non-JSON content,
/// missing fields, or empty required values. The payload format is
/// `{k, s, b, r, ep?}` and is tested against
/// `test_fixtures/event_token_v1.json`, shared with the QR CLI.
EventConfig? decodeEventToken(String? token) {
  if (token == null || token.trim().isEmpty) {
    return null;
  }

  final String jsonString;
  try {
    final bytes = base64Url.decode(base64Url.normalize(token.trim()));
    jsonString = utf8.decode(bytes);
  } on FormatException {
    throw const EventTokenException('token is not valid base64url');
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(jsonString);
  } on FormatException {
    throw const EventTokenException('token payload is not valid JSON');
  }
  if (decoded is! Map<String, Object?>) {
    throw const EventTokenException('token payload is not a JSON object');
  }

  final accessKeyId = _requiredNonEmpty(decoded, 'k');
  final secretKey = _requiredNonEmpty(decoded, 's');
  final bucket = _requiredNonEmpty(decoded, 'b');
  final region = _requiredNonEmpty(decoded, 'r');

  final endpointRaw = decoded['ep'];
  String? endpoint;
  if (endpointRaw != null) {
    if (endpointRaw is! String || endpointRaw.isEmpty) {
      throw const EventTokenException('field "ep" must be a non-empty string');
    }
    endpoint = endpointRaw;
  }

  return EventConfig(
    accessKeyId: accessKeyId,
    secretKey: secretKey,
    bucket: bucket,
    region: region,
    endpoint: endpoint,
  );
}

/// Extracts and decodes the `?d=` token from a full app [url].
///
/// Returns `null` when the URL carries no `d` query parameter.
EventConfig? decodeEventTokenFromUrl(Uri url) => decodeEventToken(url.queryParameters['d']);

String _requiredNonEmpty(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) {
    throw EventTokenException('missing required field "$key"');
  }
  if (value is! String || value.isEmpty) {
    throw EventTokenException('field "$key" must be a non-empty string');
  }
  return value;
}
