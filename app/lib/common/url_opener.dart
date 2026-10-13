import 'package:app/common/url_opener_stub.dart'
    if (dart.library.js_interop) 'package:app/common/url_opener_web.dart'
    as impl;

/// Opens [url] in a new browser tab.
typedef UrlOpener = void Function(String url);

/// Opens [url] in a new browser tab.
///
/// Resolves to the `package:web` implementation on web builds and to a
/// no-DOM stub in VM/test environments, where the call is ignored instead
/// of crashing.
void openUrlInNewTab(String url) => impl.openUrl(url);
