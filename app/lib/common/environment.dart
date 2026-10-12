import 'package:flutter/foundation.dart';

/// Build/environment helpers for the fully static guest app.
abstract final class Environment {
  static const bool isRelease = kReleaseMode;
  static const bool isDebug = kDebugMode;
  static const bool isProfile = kProfileMode;

  /// True when running on the web. The guest app is web-first, but keeping
  /// this explicit avoids assumptions in shared code.
  static const bool isWeb = kIsWeb;

  /// v1 maximum payload size for a single direct PUT upload: 2 GB.
  ///
  /// Multipart/resumable uploads are an explicit v1 exclusion, so every
  /// file is uploaded as one SigV4-signed PUT. AWS S3 allows up to 5 GB per
  /// PUT, but picked files are fully buffered in browser memory (the web
  /// platform does that for picked files anyway), so phones are the
  /// practical limit. 2 GB is the documented conservative v1 ceiling until
  /// browser testing justifies a different value. Enforced by the active
  /// [StorageService] implementation before any bytes leave the device.
  static const int maxSinglePutBytes = 2 * 1024 * 1024 * 1024;
}
