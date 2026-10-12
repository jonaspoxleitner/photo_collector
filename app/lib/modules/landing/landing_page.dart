import 'dart:async';

import 'package:app/blocs/upload/upload_queue_cubit.dart';
import 'package:app/common/router.dart';
import 'package:app/common/version_footer.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import 'package:app/models/event_config.dart';
import 'package:app/modules/landing/file_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Guest entry point: optional name entry, native file selection, and
/// inline upload status.
///
/// Selecting files creates a new upload batch in [UploadQueueCubit] and
/// starts it; progress, failures, and retry are shown inline on this page
/// (the guest never leaves `/`). Full success moves the guest to `/thanks`.
/// Entering a name is optional; empty names map to an anonymous archive
/// folder during object-key generation.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key, required this.eventConfig, this.selectFiles = selectMediaFilesFromBrowser});

  /// Decoded event/storage configuration.
  final EventConfig eventConfig;

  /// File-selection seam. Production opens the browser file input; tests
  /// inject canned selections.
  final FileSelector selectFiles;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _nameController = TextEditingController();
  bool _picking = false;

  /// Buffering progress after the picker closes: `filesRead` of
  /// `totalFiles` are in memory. Null while the picker is open or idle.
  /// Shown as a determinate indicator so long reads never look frozen.
  ({int filesRead, int totalFiles})? _prepareProgress;

  /// Completes when the guest taps Cancel while preparing; abandons the
  /// selection wait. The underlying picker/read future keeps running
  /// harmlessly in the background — the browser offers no way to abort
  /// it — but its result is simply ignored.
  Completer<void>? _cancelPicking;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectFiles() async {
    if (_picking) return;
    setState(() => _picking = true);
    final cancel = Completer<void>();
    _cancelPicking = cancel;
    try {
      final selection = widget.selectFiles(
        onProgress: (filesRead, totalFiles) {
          if (mounted) {
            setState(() => _prepareProgress = (filesRead: filesRead, totalFiles: totalFiles));
          }
        },
      );
      final files = await Future.any<List<PickedGuestFile>?>([selection, cancel.future.then((_) => null)]);
      // null: guest cancelled the preparation wait.
      if (files == null || !mounted || files.isEmpty) return;
      final cubit = context.read<UploadQueueCubit>();
      cubit.prepareBatch(_nameController.text, files);
      unawaited(cubit.start());
      // No navigation: upload progress renders inline in the status slot.
    } finally {
      _cancelPicking = null;
      if (mounted) {
        setState(() {
          _picking = false;
          _prepareProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.landingTitle)),
      bottomNavigationBar: const VersionFooter(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: BlocBuilder<UploadQueueCubit, UploadQueueState>(
              builder: (context, uploadState) {
                // A running or finished batch occupies the status slot; a
                // new batch is impossible until the thank-you/reset flow.
                final busy = _picking || uploadState.isUploading || uploadState.hasItems;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.landingEventIntro,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      enabled: !busy,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.guestNameLabel,
                        hintText: l10n.guestNameHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.guestNameOptionalHint, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: busy ? null : _selectFiles,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(l10n.selectFilesButton),
                    ),
                    ..._statusSlot(context, l10n, uploadState),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Status slot below the select button: preparing UI while [_picking],
  /// otherwise the inline upload status once a batch exists.
  List<Widget> _statusSlot(BuildContext context, AppLocalizations l10n, UploadQueueState uploadState) {
    if (_picking) {
      return [
        const SizedBox(height: 24),
        LinearProgressIndicator(
          // Determinate once the picker closes and buffering
          // counts arrive; indeterminate while the picker is
          // still open (no files read yet).
          value: switch (_prepareProgress) {
            final progress? when progress.totalFiles > 0 => progress.filesRead / progress.totalFiles,
            _ => null,
          },
        ),
        const SizedBox(height: 8),
        Text(
          switch (_prepareProgress) {
            final progress? => l10n.preparingFilesProgress(progress.filesRead, progress.totalFiles),
            null => l10n.preparingFilesWaiting,
          },
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: () => _cancelPicking?.complete(), child: Text(l10n.cancelPreparingButton)),
      ];
    }
    if (!uploadState.hasItems) return const [];

    final total = uploadState.items.length;
    final succeeded = uploadState.succeededItems.length;
    if (uploadState.allSucceeded && !uploadState.isUploading) {
      _navigateToThanksWhenSettled(context);
    }
    return [
      const SizedBox(height: 24),
      // Determinate: one aggregate bar over succeeded files; uploads
      // finish one after another, so this always advances in steps.
      LinearProgressIndicator(value: succeeded / total),
      const SizedBox(height: 8),
      Text(
        l10n.uploadProgressSummary(succeeded, total),
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
      if (uploadState.hasFailures && !uploadState.isUploading) ...[
        const SizedBox(height: 8),
        Text(
          l10n.uploadFailuresSummary(uploadState.failedItems.length, total),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: context.read<UploadQueueCubit>().retryFailed,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retryFailedButton),
        ),
      ],
    ];
  }

  /// Schedules the `/thanks` navigation after the current frame, guarded
  /// so it only fires while the guest is still on the landing route (same
  /// settled-check pattern the upload page used).
  void _navigateToThanksWhenSettled(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = GoRouter.of(context);
      if (context.mounted && router.state.uri.path == AppRoutes.landing) {
        context.go(AppRoutes.thanks);
      }
    });
  }
}
