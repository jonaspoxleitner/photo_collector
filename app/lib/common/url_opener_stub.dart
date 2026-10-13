import 'package:flutter/foundation.dart';

/// VM/test fallback: no browser window exists, so no tab is opened.
void openUrl(String url) {
  debugPrint('Opening a URL requires a browser; ignoring $url.');
}
