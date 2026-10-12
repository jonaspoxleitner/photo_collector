import 'package:args/args.dart';

/// Connection settings shared by the CLI subcommands that talk to the event
/// bucket: the guest (put-only) credentials and the bucket they are scoped to.
///
/// Values are read from command-line flags that override the environment (the
/// root Makefile exports the git-ignored `.env` into the process environment).
/// [secretKey] must never reach normal output or diagnostics.
class BucketConfig {
  const BucketConfig({
    required this.accessKeyId,
    required this.secretKey,
    required this.bucket,
    required this.region,
    this.endpoint,
  });

  final String accessKeyId;
  final String secretKey;
  final String bucket;
  final String region;

  /// Custom S3-compatible endpoint URL; null means the AWS S3 endpoint.
  final String? endpoint;
}

/// Registers the bucket connection flags on [parser].
///
/// Every subcommand that talks to the event bucket shares these flags, so
/// `--help` describes them identically everywhere.
void addBucketOptions(ArgParser parser) {
  parser
    ..addOption('access-key', help: 'S3 access key ID. Overrides ACCESS_KEY_ID.')
    ..addOption(
      'secret-key',
      help:
          'S3 secret access key (never printed). '
          'Overrides SECRET_ACCESS_KEY.',
    )
    ..addOption('bucket', help: 'Event bucket name. Overrides BUCKET.')
    ..addOption('region', help: 'S3 signing region. Overrides REGION.')
    ..addOption(
      'endpoint',
      help:
          'Optional custom S3-compatible endpoint URL. '
          'Overrides ENDPOINT.',
    );
}

/// Resolves the shared [BucketConfig] from [args] flags over [env] values.
///
/// Each flag (`--access-key`, `--secret-key`, `--bucket`, `--region`,
/// `--endpoint`) overrides its environment fallback (`ACCESS_KEY_ID`,
/// `SECRET_ACCESS_KEY`, `BUCKET`, `REGION`, `ENDPOINT`). Values are trimmed and
/// blank values count as absent.
///
/// Returns the resolved `config`, plus a `missing` entry for every absent
/// required value so the caller can report them all at once (and append its
/// own required options to the same list). `config` is null when `missing` is
/// non-empty.
({BucketConfig? config, List<String> missing}) resolveBucketConfig(ArgResults args, Map<String, String> env) {
  final missing = <String>[];
  String required(String flag, String envName) {
    final value = _setting(args, env, flag, envName);
    if (value == null) {
      missing.add(missingSettingMessage(flag, envName));
      return '';
    }
    return value;
  }

  final accessKeyId = required('access-key', 'ACCESS_KEY_ID');
  final secretKey = required('secret-key', 'SECRET_ACCESS_KEY');
  final bucket = required('bucket', 'BUCKET');
  final region = required('region', 'REGION');
  final endpoint = _setting(args, env, 'endpoint', 'ENDPOINT');

  if (missing.isNotEmpty) return (config: null, missing: missing);
  return (
    config: BucketConfig(
      accessKeyId: accessKeyId,
      secretKey: secretKey,
      bucket: bucket,
      region: region,
      endpoint: endpoint,
    ),
    missing: const [],
  );
}

/// Wording for one absent required setting, e.g.
/// `--bucket (or set BUCKET in .env)`.
String missingSettingMessage(String flag, String envName) => '--$flag (or set $envName in .env)';

/// A single trimmed setting: the `--flag` value when the flag was passed,
/// otherwise the `envName` fallback; null when absent or blank.
String? _setting(ArgResults args, Map<String, String> env, String flag, String envName) {
  final raw = args.wasParsed(flag) ? args.option(flag) : env[envName];
  final value = raw?.trim();
  return value == null || value.isEmpty ? null : value;
}
