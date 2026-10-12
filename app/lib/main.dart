import 'package:app/app.dart';
import 'package:app/models/event_config.dart';
import 'package:app/util/event_token.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  // Static hosting: serve extensionless URLs so deep links work.
  usePathUrlStrategy();

  // Parse the `?d=` event token. Missing or malformed input becomes a
  // controlled invalid-config state instead of an unhandled exception.
  EventConfig? eventConfig;
  try {
    eventConfig = decodeEventToken(Uri.base.queryParameters['d']);
  } on EventTokenException catch (error) {
    debugPrint('Invalid event token (${error.reason}).');
    eventConfig = null;
  }
  if (eventConfig == null) {
    debugPrint('No valid event configuration; showing invalid-config state.');
  }

  runApp(PhotoCollectorApp(eventConfig: eventConfig));
}
