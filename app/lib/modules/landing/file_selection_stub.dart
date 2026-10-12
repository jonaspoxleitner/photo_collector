import 'package:app/modules/landing/file_selection.dart';
import 'package:flutter/foundation.dart';

/// VM/test fallback: no DOM exists, so no files are ever picked.
Future<List<PickedGuestFile>> selectMediaFiles({SelectionProgress? onProgress}) {
  debugPrint('File selection requires a browser; returning none.');
  return Future.value(const <PickedGuestFile>[]);
}
