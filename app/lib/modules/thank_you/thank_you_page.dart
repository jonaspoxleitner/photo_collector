import 'package:app/blocs/upload/upload_queue_cubit.dart';
import 'package:app/common/router.dart';
import 'package:app/common/version_footer.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Completion screen shown after all queued uploads succeeded.
class ThankYouPage extends StatelessWidget {
  const ThankYouPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.thanksTitle)),
      bottomNavigationBar: const VersionFooter(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.favorite_outline, size: 48),
                const SizedBox(height: 16),
                Text(l10n.thanksMessage, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  l10n.thanksDeliveredHint,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.thanksPrivacyNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<UploadQueueCubit>().reset();
                    context.go(AppRoutes.landing);
                  },
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l10n.uploadMoreButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
