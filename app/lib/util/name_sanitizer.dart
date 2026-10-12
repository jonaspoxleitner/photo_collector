/// Archive-safe guest-name and file-name conversion for storage object keys.
///
/// Object keys follow `{sanitized-name}-{batch-uuid}/{safe-original-filename}`.
/// All helpers here guarantee that caller-controlled text can never introduce
/// path separators, traversal, or attacker-controlled key prefixes.
library;

/// Fallback used when a guest provides no usable name.
const anonymousGuestName = 'anonymous';

/// Maximum length of a sanitized guest name segment.
const maxGuestNameLength = 40;

/// Maximum length of a sanitized file name.
const maxFileNameLength = 120;

const _umlauts = {'ä': 'ae', 'ö': 'oe', 'ü': 'ue', 'Ä': 'ae', 'Ö': 'oe', 'Ü': 'ue', 'ß': 'ss'};

final _allowedNameChars = RegExp(r'[^a-z0-9]+');
final _repeatedDashes = RegExp(r'-{2,}');
final _allowedFileChars = RegExp(r'[^A-Za-z0-9._-]');

/// Sanitizes a guest-provided name into a lowercase, archive-safe key
/// segment: trims, transliterates German umlauts, collapses whitespace and
/// unsupported characters into single dashes, limits length, and falls back
/// to [anonymousGuestName] when nothing usable remains.
String sanitizeGuestName(String? name) {
  final buffer = StringBuffer();
  for (final rune in (name ?? '').trim().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_umlauts[char] ?? char);
  }
  var sanitized = buffer.toString().toLowerCase();
  // Collapse any run of whitespace or unsupported characters into one dash.
  sanitized = sanitized.replaceAll(_allowedNameChars, '-');
  sanitized = sanitized.replaceAll(_repeatedDashes, '-');
  sanitized = sanitized.replaceAll(RegExp(r'^-+|-+$'), '');
  if (sanitized.length > maxGuestNameLength) {
    sanitized = sanitized.substring(0, maxGuestNameLength);
    sanitized = sanitized.replaceAll(RegExp(r'-+$'), '');
  }
  if (sanitized.isEmpty) {
    return anonymousGuestName;
  }
  return sanitized;
}

/// Sanitizes an original file name so it is safe inside a storage object
/// key. Path segments and traversal are removed, unsafe characters are
/// replaced with `-`, and the result is length-limited. Falls back to
/// `file` when nothing usable remains.
String sanitizeOriginalFileName(String? fileName) {
  var name = (fileName ?? '').trim();
  // Remove any directory components regardless of separator style.
  name = name.replaceAll(r'\', '/');
  name = name.split('/').where((segment) => segment.isNotEmpty).lastOrNull ?? '';
  // Neutralize traversal segments and dots-only names.
  name = name.replaceAll('..', '-');
  name = name.replaceAll(RegExp(r'\s+'), '-');
  name = name.replaceAll(_allowedFileChars, '-');
  name = name.replaceAll(_repeatedDashes, '-');
  name = name.replaceAll(RegExp(r'^[.-]+|[.-]+$'), '');
  if (name.length > maxFileNameLength) {
    // Keep the extension when trimming very long names.
    final dotIndex = name.lastIndexOf('.');
    final extension = dotIndex > 0 ? name.substring(dotIndex) : '';
    final keep = maxFileNameLength - extension.length;
    name = (keep > 0 ? name.substring(0, keep) : '') + extension;
    name = name.replaceAll(RegExp(r'[-.]+$'), '') + extension;
  }
  if (name.isEmpty) {
    return 'file';
  }
  return name;
}

/// Builds the storage object key for one guest file following the locked
/// format `{sanitized-name}-{batch-uuid}/{safe-original-filename}`.
///
/// [guestName] may be null or empty and then maps to [anonymousGuestName].
/// Neither the guest name nor the original file name can introduce path
/// separators or traversal into the key. The batch segment is exactly
/// [batchId], which callers generate once per guest upload session (UUID4)
/// so retries remain safe and collisions or overwrites are impossible.
String buildObjectKey({required String? guestName, required String batchId, required String originalFileName}) =>
    '${sanitizeGuestName(guestName)}-$batchId/'
    '${sanitizeOriginalFileName(originalFileName)}';
