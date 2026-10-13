import 'package:web/web.dart' as web;

/// Opens [url] in a new browser tab.
///
/// Only compiled for web (see `url_opener.dart`).
void openUrl(String url) {
  web.window.open(url, '_blank');
}
