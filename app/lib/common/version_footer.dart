import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Loads the semantic app version generated from `pubspec.yaml`.
typedef AppVersionLoader = Future<String> Function();

Future<String> _loadPubspecVersion() async => (await PackageInfo.fromPlatform()).version;

/// Small version label pinned to the bottom of every screen via
/// `Scaffold.bottomNavigationBar`.
class VersionFooter extends StatefulWidget {
  const VersionFooter({super.key, this.loadVersion = _loadPubspecVersion});

  /// Package-info seam for tests; production reads the pubspec-derived
  /// version through `package_info_plus`.
  final AppVersionLoader loadVersion;

  @override
  State<VersionFooter> createState() => _VersionFooterState();
}

class _VersionFooterState extends State<VersionFooter> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    String version;
    try {
      version = (await widget.loadVersion()).trim();
    } catch (_) {
      // Package info can be unavailable in widget tests or unusual embedders;
      // never replace the real pubspec version with a guessed fallback.
      version = '';
    }
    if (!mounted || version == _version) return;
    setState(() => _version = version);
  }

  @override
  Widget build(BuildContext context) {
    final version = _version;
    if (version == null || version.isEmpty) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          'Version $version',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
