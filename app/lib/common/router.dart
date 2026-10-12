import 'package:app/common/version_footer.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import 'package:app/models/event_config.dart';
import 'package:app/modules/landing/file_selection.dart';
import 'package:app/modules/landing/landing_page.dart';
import 'package:app/modules/thank_you/thank_you_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Route paths of the guest flow.
abstract final class AppRoutes {
  static const landing = '/';
  static const thanks = '/thanks';
}

/// Builds the guest-flow router with `/` and `/thanks`. Upload progress
/// renders inline on the landing page; there is no dedicated upload route.
///
/// When [eventConfig] is null the landing route renders the controlled
/// invalid-config screen: file selection is impossible and the guest gets an
/// actionable message.
///
/// [fileSelector] is a test seam injected into the landing page; production
/// uses the browser file input from `selectMediaFilesFromBrowser`.
GoRouter createAppRouter({required EventConfig? eventConfig, FileSelector? fileSelector}) => GoRouter(
  initialLocation: AppRoutes.landing,
  routes: [
    GoRoute(
      path: AppRoutes.landing,
      builder: (context, state) => switch (eventConfig) {
        final config? => LandingPage(eventConfig: config, selectFiles: fileSelector ?? selectMediaFilesFromBrowser),
        null => const InvalidConfigScreen(),
      },
    ),
    GoRoute(path: AppRoutes.thanks, builder: (context, state) => const ThankYouPage()),
  ],
);

/// Controlled screen shown when the `?d=` token is missing or malformed.
class InvalidConfigScreen extends StatelessWidget {
  const InvalidConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.invalidConfigTitle)),
      bottomNavigationBar: const VersionFooter(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(l10n.invalidConfigMessage)),
      ),
    );
  }
}
