// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Photo Collector';

  @override
  String get landingTitle => 'Teile deine Fotos';

  @override
  String get landingEventIntro =>
      'Füge deine schönsten Fotos und Videos hinzu — direkt vom Handy, ohne App, ohne Konto.';

  @override
  String get guestNameLabel => 'Dein Name (optional)';

  @override
  String get guestNameHint => 'z. B. Anna Schmidt';

  @override
  String get guestNameOptionalHint => 'Lass das Feld leer, wenn du anonym bleiben möchtest.';

  @override
  String get selectFilesButton => 'Fotos und Videos auswählen';

  @override
  String get preparingFilesWaiting => 'Warte auf die Dateiauswahl…';

  @override
  String get cancelPreparingButton => 'Abbrechen';

  @override
  String preparingFilesProgress(int done, int total) {
    return 'Bereite Datei $done von $total vor…';
  }

  @override
  String uploadProgressSummary(int done, int total) {
    return '$done von $total hochgeladen';
  }

  @override
  String uploadFailuresSummary(int failed, int total) {
    return '$failed von $total Uploads sind fehlgeschlagen — du kannst sie unten erneut versuchen.';
  }

  @override
  String get retryFailedButton => 'Fehlgeschlagene erneut versuchen';

  @override
  String get thanksTitle => 'Danke';

  @override
  String get thanksMessage => 'Danke, dass du deine Fotos und Videos teilst! ❤️';

  @override
  String get thanksDeliveredHint => 'Alles ist sicher angekommen. Der Gastgeber kümmert sich um die Erinnerungen.';

  @override
  String get thanksPrivacyNote =>
      'Deine Uploads werden privat gespeichert und sind nur für den Gastgeber sichtbar. Der von dir eingegebene Name kennzeichnet deinen Upload-Ordner und ist ebenfalls für den Gastgeber sichtbar. Der Event-Speicher wird nach dem Event gelöscht.';

  @override
  String get uploadMoreButton => 'Weitere Fotos hochladen';

  @override
  String get invalidConfigTitle => 'Ungültiger Event-Link';

  @override
  String get invalidConfigMessage =>
      'Dieser Event-Link fehlt oder ist ungültig. Bitte scanne den Event-QR-Code erneut oder frage den Gastgeber nach einem neuen Link.';
}
