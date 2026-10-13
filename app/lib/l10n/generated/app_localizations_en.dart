// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Photo Collector';

  @override
  String get landingTitle => 'Share your photos';

  @override
  String get landingEventIntro =>
      'Add your favorite photos and videos — straight from your phone, no app install, no account.';

  @override
  String get guestNameLabel => 'Your name (optional)';

  @override
  String get guestNameHint => 'e.g. Anna Smith';

  @override
  String get guestNameOptionalHint => 'Leave it empty if you prefer to stay anonymous.';

  @override
  String get selectFilesButton => 'Select photos and videos';

  @override
  String get preparingFilesWaiting => 'Waiting for the file picker…';

  @override
  String get cancelPreparingButton => 'Cancel';

  @override
  String preparingFilesProgress(int done, int total) {
    return 'Preparing file $done of $total…';
  }

  @override
  String uploadProgressSummary(int done, int total) {
    return '$done of $total uploaded';
  }

  @override
  String uploadFailuresSummary(int failed, int total) {
    return '$failed of $total uploads failed — you can retry below.';
  }

  @override
  String get retryFailedButton => 'Retry failed';

  @override
  String get thanksTitle => 'Thank you';

  @override
  String get thanksMessage => 'Thank you for sharing your photos and videos!';

  @override
  String get thanksDeliveredHint => 'Everything arrived safely. The host will take care of the memories.';

  @override
  String get thanksPrivacyNote =>
      'Your uploads are stored privately and are only visible to the host. The name you entered labels your upload folder and is visible to the host as well. The event storage is deleted after the event.';

  @override
  String get uploadMoreButton => 'Upload more photos';

  @override
  String get invalidConfigTitle => 'Invalid event link';

  @override
  String get invalidConfigMessage =>
      'This event link is missing or invalid. Please scan the event QR code again or ask the host for a new link.';

  @override
  String get invalidConfigSetupHint =>
      'Are you the host? Configure an event link by running the CLI QR-code generator from the photo_collector repository — it creates a QR card that guests scan to upload photos.';

  @override
  String get invalidConfigSetupLinkLabel => 'Setup instructions on GitHub';
}
