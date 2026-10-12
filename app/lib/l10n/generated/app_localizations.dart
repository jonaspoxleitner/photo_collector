import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('de'), Locale('en')];

  /// Application title shown in the browser tab.
  ///
  /// In en, this message translates to:
  /// **'Photo Collector'**
  String get appTitle;

  /// Title of the landing screen.
  ///
  /// In en, this message translates to:
  /// **'Share your photos'**
  String get landingTitle;

  /// Intro line on the landing screen.
  ///
  /// In en, this message translates to:
  /// **'Add your favorite photos and videos — straight from your phone, no app install, no account.'**
  String get landingEventIntro;

  /// Label of the optional guest-name input.
  ///
  /// In en, this message translates to:
  /// **'Your name (optional)'**
  String get guestNameLabel;

  /// Hint text inside the optional guest-name input.
  ///
  /// In en, this message translates to:
  /// **'e.g. Anna Smith'**
  String get guestNameHint;

  /// Explanatory text below the guest-name input.
  ///
  /// In en, this message translates to:
  /// **'Leave it empty if you prefer to stay anonymous.'**
  String get guestNameOptionalHint;

  /// Button that opens the native file picker.
  ///
  /// In en, this message translates to:
  /// **'Select photos and videos'**
  String get selectFilesButton;

  /// Shown below the select button while the native file picker is open.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the file picker…'**
  String get preparingFilesWaiting;

  /// Button that abandons a stuck or slow file-preparation wait on the landing screen.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelPreparingButton;

  /// Shown while picked files are being read into memory before upload starts.
  ///
  /// In en, this message translates to:
  /// **'Preparing file {done} of {total}…'**
  String preparingFilesProgress(int done, int total);

  /// Summary line of the inline upload status on the landing screen.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} uploaded'**
  String uploadProgressSummary(int done, int total);

  /// Single failure line below the inline upload status on the landing screen.
  ///
  /// In en, this message translates to:
  /// **'{failed} of {total} uploads failed — you can retry below.'**
  String uploadFailuresSummary(int failed, int total);

  /// Button that re-uploads only the failed files.
  ///
  /// In en, this message translates to:
  /// **'Retry failed'**
  String get retryFailedButton;

  /// Title of the thank-you screen.
  ///
  /// In en, this message translates to:
  /// **'Thank you'**
  String get thanksTitle;

  /// Main message of the thank-you screen.
  ///
  /// In en, this message translates to:
  /// **'Thank you for sharing your photos and videos!'**
  String get thanksMessage;

  /// Secondary message of the thank-you screen.
  ///
  /// In en, this message translates to:
  /// **'Everything arrived safely. The host will take care of the memories.'**
  String get thanksDeliveredHint;

  /// Privacy note on the thank-you screen; must match the policy documented in docs/security-model.md.
  ///
  /// In en, this message translates to:
  /// **'Your uploads are stored privately and are only visible to the host. The name you entered labels your upload folder and is visible to the host as well. The event storage is deleted after the event.'**
  String get thanksPrivacyNote;

  /// Button on the thank-you screen that starts a new batch.
  ///
  /// In en, this message translates to:
  /// **'Upload more photos'**
  String get uploadMoreButton;

  /// Title shown when the event configuration token is missing or malformed.
  ///
  /// In en, this message translates to:
  /// **'Invalid event link'**
  String get invalidConfigTitle;

  /// Message shown when the event configuration token is missing or malformed.
  ///
  /// In en, this message translates to:
  /// **'This event link is missing or invalid. Please scan the event QR code again or ask the host for a new link.'**
  String get invalidConfigMessage;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
