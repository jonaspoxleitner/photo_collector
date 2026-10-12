import 'package:app/blocs/upload/upload_queue_cubit.dart';
import 'package:app/common/locale_resolution.dart';
import 'package:app/common/router.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import 'package:app/models/event_config.dart';
import 'package:app/modules/landing/file_selection.dart';
import 'package:app/services/storage/s3_client/s3_client_storage_service.dart';
import 'package:app/services/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Root application shell of the photo_collector guest app.
///
/// [eventConfig] is the decoded `?d=` token; `null` means the link was
/// missing or malformed and the controlled invalid-config screen is shown.
class PhotoCollectorApp extends StatelessWidget {
  const PhotoCollectorApp({super.key, this.eventConfig, this.locale, this.storageService, this.fileSelector});

  /// Decoded event/storage configuration, or null for invalid links.
  final EventConfig? eventConfig;

  /// Explicit locale override. Only set by widget tests; production resolves
  /// the locale from the device/browser language instead.
  final Locale? locale;

  /// Storage seam for widget tests. When null (production), the upload
  /// cubit resolves [StorageService.instance] lazily once uploads start.
  final StorageService? storageService;

  /// File-selection seam for widget tests; production opens the browser
  /// file input.
  final FileSelector? fileSelector;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => UploadQueueCubit(
      // Production resolves to direct S3 uploads via package:s3_client
      // (validated against a real event bucket/IAM policy/CORS config).
      // Tests inject a fake through [storageService]. Invalid configs
      // get no storage at all: the cubit's lazy fallback then fails
      // uploads in a controlled, actionable way.
      storageService: storageService ?? (eventConfig != null ? S3ClientStorageService(config: eventConfig!) : null),
    ),
    child: MaterialApp.router(
      routerConfig: createAppRouter(eventConfig: eventConfig, fileSelector: fileSelector),
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      // Flutter Web exposes this through the meta theme-color; keep it the
      // scaffold background so Safari/iOS chrome matches the page. (The
      // scaffold surface is derived from the seed and currently #FFF8F8.)
      color: const Color(0xFFFFF8F8),
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7D5260)), useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      localeResolutionCallback: (deviceLocale, _) => resolveAppLocale(deviceLocale: deviceLocale),
    ),
  );
}
