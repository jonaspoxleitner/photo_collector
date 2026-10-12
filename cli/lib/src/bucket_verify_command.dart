import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:cli/src/bucket_config.dart';
import 'package:cli/src/runner.dart';
import 'package:s3_client/s3_client.dart';

/// PNG uploaded by the write probe, relative to the `cli/` working directory
/// (the Makefile always runs the CLI from there).
const String probeAssetPath = 'assets/probe-icon.png';

/// Prefix of the probe objects. The object lingers until teardown because the
/// put-only credential cannot delete it.
const String probeKeyPrefix = '.photo-collector-verify/';

/// One signed HTTP probe request and its outcome.
class ProbeResponse {
  const ProbeResponse({this.statusCode, this.eTag, this.errorCode, this.transportError});

  /// HTTP status code, or null when the request failed before any response.
  final int? statusCode;

  /// ETag returned by a successful write probe.
  final String? eTag;

  /// S3 error code parsed from the error body (e.g. `AccessDenied`), or the
  /// numeric status when the body was not S3 error XML.
  final String? errorCode;

  /// Secret-free description of a failure that produced no HTTP response.
  final String? transportError;

  /// Whether the response was a 2xx.
  bool get isSuccess => statusCode != null && statusCode! >= 200 && statusCode! < 300;
}

/// All probe outcomes of one verification run.
class BucketProbeOutcome {
  const BucketProbeOutcome({required this.write, this.read, this.delete});

  /// Outcome of the signed PUT.
  final ProbeResponse write;

  /// Outcome of the signed GET; null when the write probe failed first.
  final ProbeResponse? read;

  /// Outcome of the signed DELETE; null when the write probe failed first.
  final ProbeResponse? delete;
}

/// Runs the write, read, and delete probes against the event bucket.
///
/// Injectable so [BucketVerifyCommand] can be unit-tested without network
/// access; [probeBucket] is the real, network-backed implementation.
typedef BucketProbe = Future<BucketProbeOutcome> Function(BucketConfig config, String probeKey, Uint8List payload);

/// `bucket-verify` subcommand: behaviorally proves the guest (put-only)
/// credential can write to the event bucket and cannot read from or delete
/// from it.
///
/// No admin credentials are involved and no secret value is ever printed.
class BucketVerifyCommand extends CliCommand {
  BucketVerifyCommand({BucketProbe? probe}) : _probe = probe ?? probeBucket {
    addBucketOptions(argParser);
  }

  final BucketProbe _probe;

  @override
  String get name => 'bucket-verify';

  @override
  String get description =>
      'Verifies that the guest (put-only) credential can write to the event '
      'bucket and cannot read from or delete from it.';

  @override
  String? get usageFooter =>
      'Uses only the guest credential; no admin credentials are involved. '
      'A signed PUT must succeed; a signed GET and a signed DELETE must both '
      'be denied (HTTP 403 AccessDenied).';

  @override
  Future<int> execute(ArgResults args) async {
    final cli = runner! as CliRunner;
    final env = cli.environment;
    final out = cli.out;
    final err = cli.err;

    final resolved = resolveBucketConfig(args, env);
    if (resolved.missing.isNotEmpty) {
      err.writeln('Missing required configuration:');
      for (final item in resolved.missing) {
        err.writeln('  $item');
      }
      err.writeln('Pass flags, or copy .env.example to .env at the repo root.');
      return ExitCodes.usage;
    }
    final config = resolved.config!;

    final Uint8List payload;
    try {
      payload = await File(probeAssetPath).readAsBytes();
    } on FileSystemException catch (e) {
      err.writeln('Error: cannot read the probe asset "$probeAssetPath": ${e.message}');
      return ExitCodes.software;
    }

    final probeKey = probeObjectKey(DateTime.now().toUtc());

    out.writeln(
      'Verifying put-only access to bucket "${config.bucket}" in region "${config.region}"'
      '${config.endpoint == null ? '' : ' via ${config.endpoint}'}.',
    );
    out.writeln('Probe object: $probeKey');

    final BucketProbeOutcome outcome;
    try {
      outcome = await _probe(config, probeKey, payload);
    } on FormatException catch (e) {
      err.writeln('Error: could not build the probe request URL: ${e.message}');
      return ExitCodes.software;
    } catch (e) {
      err.writeln('Write probe (PUT):  ERROR (unexpected ${e.runtimeType}).');
      return ExitCodes.software;
    }

    final write = outcome.write;
    if (!write.isSuccess || write.eTag == null) {
      err.writeln('Write probe (PUT):  ${_describeWrite(write)}');
      for (final hint in _hints(write)) {
        err.writeln(hint);
      }
      return ExitCodes.software;
    }
    out.writeln('Write probe (PUT):  PASS (HTTP ${write.statusCode}, ETag ${write.eTag}).');

    final read = outcome.read;
    if (read == null) {
      err.writeln('Read probe (GET):  ERROR (the probe did not run after a successful write).');
      return ExitCodes.software;
    }
    if (read.isSuccess) {
      err.writeln('Read probe (GET):  FAIL (HTTP ${read.statusCode}); the object was readable.');
      err.writeln('Error: the credential is not put-only: it can read the probe object.');
      err.writeln('Restrict the IAM policy to s3:PutObject only, then re-run.');
      return ExitCodes.data;
    }
    if (read.statusCode != 403 || read.errorCode != 'AccessDenied') {
      err.writeln('Read probe (GET):  ${_describe(read)}');
      for (final hint in _hints(read)) {
        err.writeln(hint);
      }
      return ExitCodes.software;
    }
    out.writeln('Read probe (GET):  PASS (HTTP 403 AccessDenied).');

    final delete = outcome.delete;
    if (delete == null) {
      err.writeln('Delete probe (DELETE):  ERROR (the probe did not run after a denied read).');
      return ExitCodes.software;
    }
    if (delete.isSuccess) {
      err.writeln('Delete probe (DELETE):  FAIL (HTTP ${delete.statusCode}); the object was deleted.');
      err.writeln('Error: the credential is not put-only: it can delete the probe object.');
      err.writeln('Restrict the IAM policy to s3:PutObject only, then re-run.');
      err.writeln('Note: the unexpectedly permitted delete removed the probe object $probeKey.');
      return ExitCodes.data;
    }
    if (delete.statusCode == 403 && delete.errorCode == 'AccessDenied') {
      out.writeln('Delete probe (DELETE):  PASS (HTTP 403 AccessDenied).');
      out.writeln();
      out.writeln(
        'Put-only policy verified: the guest credential can write to the bucket and cannot read from or delete from it.',
      );
      out.writeln('Note: $probeKey stays in the bucket until teardown emptying; put-only access cannot delete it.');
      return ExitCodes.ok;
    }

    err.writeln('Delete probe (DELETE):  ${_describe(delete)}');
    for (final hint in _hints(delete)) {
      err.writeln(hint);
    }
    return ExitCodes.software;
  }
}

/// Probe object key for the verification run at [when]: a timestamped PNG
/// under [probeKeyPrefix] so repeated runs never overwrite each other.
String probeObjectKey(DateTime when) {
  final t = when.toUtc();
  String pad(int value) => value.toString().padLeft(2, '0');
  return '$probeKeyPrefix'
      '${t.year}${pad(t.month)}${pad(t.day)}T${pad(t.hour)}${pad(t.minute)}${pad(t.second)}Z.png';
}

/// Real probe: a signed PUT that must return `200` with an ETag, then a signed
/// GET and a signed DELETE of the same object that must both be denied with
/// `403 AccessDenied`.
///
/// Uses presigned URLs (the same SigV4 signer as the guest upload path) so the
/// raw HTTP status is visible, including the `301` of a region/endpoint
/// mismatch. S3 returns `204` for a permitted delete even when the key is
/// absent, so the delete status is a reliable discriminator. The signed URL is
/// never printed.
Future<BucketProbeOutcome> probeBucket(BucketConfig config, String probeKey, Uint8List payload) async {
  final client = _clientFor(config);
  final putUrl = await client.presignPutObject(bucket: config.bucket, key: probeKey);
  final write = await _send(putUrl, method: 'PUT', body: payload);
  if (!write.isSuccess || write.eTag == null) {
    return BucketProbeOutcome(write: write);
  }
  final getUrl = await client.presignGetObject(bucket: config.bucket, key: probeKey);
  final read = await _send(getUrl, method: 'GET');
  final deleteUrl = await client.presign('DELETE', bucket: config.bucket, key: probeKey);
  final delete = await _send(deleteUrl, method: 'DELETE');
  return BucketProbeOutcome(write: write, read: read, delete: delete);
}

/// Builds the S3 client for [config], mirroring the guest app's endpoint
/// selection: virtual-hosted AWS S3 by default, path style for a custom
/// endpoint.
S3Client _clientFor(BucketConfig config) {
  final credentials = S3CredentialsProvider.static(accessKeyId: config.accessKeyId, secretAccessKey: config.secretKey);
  final endpoint = config.endpoint?.trim();
  if (endpoint == null || endpoint.isEmpty) {
    return S3Client.aws(region: config.region, credentials: credentials);
  }
  final normalized = endpoint.startsWith(RegExp('https?://')) ? endpoint : 'https://$endpoint';
  return S3Client(
    baseEndpoint: Uri.parse(normalized.replaceAll(RegExp(r'/+$'), '')),
    region: config.region,
    credentials: credentials,
    usePathStyle: true,
  );
}

/// Sends one presigned request and captures the raw outcome.
Future<ProbeResponse> _send(Uri url, {required String method, List<int>? body}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.openUrl(method, url);
    // Do not follow redirects: a 301 is a wrong-region/endpoint diagnostic.
    request.followRedirects = false;
    if (body != null) {
      request.headers.contentType = ContentType('image', 'png');
      request.headers.contentLength = body.length;
      request.add(body);
    }
    final response = await request.close();
    final statusCode = response.statusCode;
    final errorBody = statusCode >= 200 && statusCode < 300
        ? null
        : await response.transform(const Utf8Decoder(allowMalformed: true)).join();
    if (errorBody == null) {
      // Success body (empty for PUT, a PNG for a readable GET): no need to keep it.
      await response.drain<void>();
    }
    return ProbeResponse(
      statusCode: statusCode,
      eTag: _stripQuotes(response.headers.value('etag')),
      errorCode: errorBody == null ? null : _errorCode(errorBody, statusCode),
    );
  } on SocketException catch (e) {
    return ProbeResponse(transportError: e.message);
  } on TlsException catch (e) {
    return ProbeResponse(transportError: e.message);
  } on HttpException catch (e) {
    return ProbeResponse(transportError: e.message);
  } finally {
    client.close(force: true);
  }
}

/// S3 error code from an error body, falling back to the numeric status when
/// the body is not S3 error XML.
String _errorCode(String body, int statusCode) {
  try {
    return S3Error.fromXmlDocument(body).code;
  } catch (_) {
    return statusCode.toString();
  }
}

String? _stripQuotes(String? value) => value?.replaceAll('"', '');

/// One-line outcome for a probe, without any secret material.
String _describe(ProbeResponse response) {
  if (response.transportError != null) {
    return 'ERROR (no response: ${response.transportError})';
  }
  final status = response.statusCode;
  final code = response.errorCode;
  return 'FAIL (HTTP $status${code == null || code == status.toString() ? '' : ' $code'})';
}

/// Write-probe outcome: a 2xx without an ETag is still a failure.
String _describeWrite(ProbeResponse response) {
  if (response.isSuccess && response.eTag == null) {
    return 'FAIL (HTTP ${response.statusCode} but the response carried no ETag)';
  }
  return _describe(response);
}

/// Actionable hints for a failed probe, matched on the S3 error code/status.
List<String> _hints(ProbeResponse response) {
  if (response.transportError != null) {
    return ['Check network access, the endpoint URL, and any proxy between this host and the bucket.'];
  }
  final code = response.errorCode;
  final status = response.statusCode;
  if (code == 'AccessDenied') {
    return [
      'Hint: AccessDenied on PUT usually means the IAM policy still contains the',
      '  literal ${r'${BUCKET}'} placeholder instead of the real bucket name.',
      '  Re-apply infra/s3-put-only-policy.template.json with BUCKET substituted.',
    ];
  }
  if (code == 'PermanentRedirect' || status == 301 || status == 307) {
    return [
      'Hint: the request was redirected - REGION or ENDPOINT most likely does not',
      '  match the bucket. Check both values in .env and re-run.',
    ];
  }
  if (code == 'SignatureDoesNotMatch') {
    return [
      'Hint: the signature did not match - SECRET_ACCESS_KEY is probably wrong or',
      '  does not belong to ACCESS_KEY_ID.',
    ];
  }
  if (code == 'InvalidAccessKeyId') {
    return ['Hint: ACCESS_KEY_ID is unknown to the provider; check the event IAM user.'];
  }
  if (code == 'NoSuchBucket' || status == 404) {
    return ['Hint: the bucket does not exist (or the name is misspelled); check BUCKET.'];
  }
  return const [];
}
