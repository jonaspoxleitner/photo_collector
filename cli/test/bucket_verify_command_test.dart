import 'package:cli/cli.dart';
import 'package:test/test.dart';

void main() {
  /// Full fake bucket configuration in the environment, as the root Makefile
  /// exports it from `.env`. Values are fixture-style placeholders.
  Map<String, String> fakeEnv() => {
    'ACCESS_KEY_ID': 'AKIAEXAMPLE00000001',
    'SECRET_ACCESS_KEY': 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    'BUCKET': 'wedding-20261025',
    'REGION': 'eu-central-1',
  };

  /// A probe that always reports [write] (and optionally [read]/[delete]).
  BucketProbe fixedProbe(ProbeResponse write, [ProbeResponse? read, ProbeResponse? delete]) =>
      (config, probeKey, payload) async => BucketProbeOutcome(write: write, read: read, delete: delete);

  const okWrite = ProbeResponse(statusCode: 200, eTag: 'abc123');
  const deniedRead = ProbeResponse(statusCode: 403, errorCode: 'AccessDenied');
  const deniedDelete = ProbeResponse(statusCode: 403, errorCode: 'AccessDenied');

  Future<({int code, String out, String err, String? probeKey, BucketConfig? config})> invoke(
    List<String> arguments, {
    Map<String, String>? env,
    BucketProbe? probe,
  }) async {
    final out = StringBuffer();
    final err = StringBuffer();
    String? probeKey;
    BucketConfig? capturedConfig;
    final effective =
        probe ??
        (config, key, payload) async =>
            const BucketProbeOutcome(write: okWrite, read: deniedRead, delete: deniedDelete);
    final code = await runCli(
      ['bucket-verify', ...arguments],
      environment: env,
      out: out,
      err: err,
      bucketProbe: (config, key, payload) {
        probeKey = key;
        capturedConfig = config;
        return effective(config, key, payload);
      },
    );
    return (code: code, out: out.toString(), err: err.toString(), probeKey: probeKey, config: capturedConfig);
  }

  group('happy path', () {
    test('write 200 + read 403 + delete 403 exits 0 and reports PASS three times', () async {
      final result = await invoke([], env: fakeEnv());

      expect(result.code, ExitCodes.ok, reason: result.err);
      expect(result.out, contains('Write probe (PUT):  PASS (HTTP 200, ETag abc123).'));
      expect(result.out, contains('Read probe (GET):  PASS (HTTP 403 AccessDenied).'));
      expect(result.out, contains('Delete probe (DELETE):  PASS (HTTP 403 AccessDenied).'));
      expect(result.out, contains('Put-only policy verified'));
      expect(result.out, contains('wedding-20261025'));
      expect(result.out, contains('eu-central-1'));
      expect(result.err, isEmpty);
    });

    test('reports the timestamped probe object and its lingering note', () async {
      final result = await invoke([], env: fakeEnv());

      expect(result.code, ExitCodes.ok, reason: result.err);
      expect(result.probeKey, matches(RegExp(r'^\.photo-collector-verify/\d{8}T\d{6}Z\.png$')));
      expect(result.out, contains('Probe object: ${result.probeKey}'));
      expect(result.out, contains('${result.probeKey} stays in the bucket until teardown emptying'));
    });

    test('flags override environment values and reach the config', () async {
      final result = await invoke(['--bucket', 'flag-bucket', '--region', 'us-east-1'], env: fakeEnv());

      expect(result.code, ExitCodes.ok, reason: result.err);
      expect(result.config!.bucket, 'flag-bucket');
      expect(result.config!.region, 'us-east-1');
      expect(result.out, contains('flag-bucket'));
      expect(result.out, isNot(contains('wedding-20261025')));
    });

    test('never echoes the secret key or access key id', () async {
      final env = fakeEnv();
      final result = await invoke([], env: env);

      expect(result.code, ExitCodes.ok, reason: result.err);
      for (final secret in [env['SECRET_ACCESS_KEY']!, env['ACCESS_KEY_ID']!]) {
        expect(result.out, isNot(contains(secret)));
        expect(result.err, isNot(contains(secret)));
      }
    });
  });

  group('exit codes', () {
    test('missing configuration exits 64 without probing', () async {
      final result = await invoke([], env: const {});

      expect(result.code, ExitCodes.usage);
      expect(result.err, contains('--access-key'));
      expect(result.err, contains('ACCESS_KEY_ID'));
      expect(result.err, contains('--bucket'));
      expect(result.err, contains('.env'));
      expect(result.probeKey, isNull);
    });

    test('write AccessDenied exits 70 with the ${r"${BUCKET}"} placeholder hint', () async {
      final result = await invoke(
        [],
        env: fakeEnv(),
        probe: fixedProbe(const ProbeResponse(statusCode: 403, errorCode: 'AccessDenied')),
      );

      expect(result.code, ExitCodes.software);
      expect(result.err, contains('403 AccessDenied'));
      expect(result.err, contains(r'${BUCKET}'));
      expect(result.err, contains('s3-put-only-policy.template.json'));
    });

    test('write without an ETag exits 70 even on 200', () async {
      final result = await invoke([], env: fakeEnv(), probe: fixedProbe(const ProbeResponse(statusCode: 200)));

      expect(result.code, ExitCodes.software);
      expect(result.err, contains('ETag'));
    });

    test('write permanent redirect exits 70 with the region/endpoint hint', () async {
      final result = await invoke([], env: fakeEnv(), probe: fixedProbe(const ProbeResponse(statusCode: 301)));
      final redirect = await invoke(
        [],
        env: fakeEnv(),
        probe: fixedProbe(const ProbeResponse(statusCode: 301, errorCode: 'PermanentRedirect')),
      );

      expect(result.code, ExitCodes.software);
      expect(result.err, contains('301'));
      expect(result.err, contains('REGION or ENDPOINT'));
      expect(redirect.code, ExitCodes.software);
      expect(redirect.err, contains('PermanentRedirect'));
    });

    test('write signature mismatch exits 70 with the secret hint', () async {
      final result = await invoke(
        [],
        env: fakeEnv(),
        probe: fixedProbe(const ProbeResponse(statusCode: 403, errorCode: 'SignatureDoesNotMatch')),
      );

      expect(result.code, ExitCodes.software);
      expect(result.err, contains('SignatureDoesNotMatch'));
      expect(result.err, contains('SECRET_ACCESS_KEY'));
    });

    test('write transport failure exits 70 and reports no response', () async {
      final result = await invoke(
        [],
        env: fakeEnv(),
        probe: fixedProbe(const ProbeResponse(transportError: 'connection refused')),
      );

      expect(result.code, ExitCodes.software);
      expect(result.err, contains('ERROR (no response: connection refused)'));
    });

    test('read that succeeds exits 65 and flags the policy as too wide', () async {
      final result = await invoke([], env: fakeEnv(), probe: fixedProbe(okWrite, const ProbeResponse(statusCode: 200)));

      expect(result.code, ExitCodes.data);
      expect(result.err, contains('not put-only'));
      expect(result.err, contains('s3:PutObject'));
    });

    test('unexpected read failure exits 70', () async {
      final result = await invoke(
        [],
        env: fakeEnv(),
        probe: fixedProbe(okWrite, const ProbeResponse(statusCode: 500, errorCode: 'InternalError')),
      );

      expect(result.code, ExitCodes.software);
      expect(result.err, contains('500 InternalError'));
    });

    test('delete that succeeds exits 65, flags the policy as too wide, and notes the cleanup', () async {
      final result = await invoke(
        [],
        env: fakeEnv(),
        probe: fixedProbe(okWrite, deniedRead, const ProbeResponse(statusCode: 204)),
      );

      expect(result.code, ExitCodes.data);
      expect(result.err, contains('Delete probe (DELETE):  FAIL (HTTP 204)'));
      expect(result.err, contains('not put-only'));
      expect(result.err, contains('s3:PutObject'));
      expect(result.err, contains('removed the probe object'));
      expect(result.err, contains(result.probeKey!));
    });

    test('delete transport failure exits 70 and reports no response', () async {
      final result = await invoke(
        [],
        env: fakeEnv(),
        probe: fixedProbe(okWrite, deniedRead, const ProbeResponse(transportError: 'connection refused')),
      );

      expect(result.code, ExitCodes.software);
      expect(result.err, contains('Delete probe (DELETE):  ERROR (no response: connection refused)'));
    });

    test('unexpected delete failure exits 70', () async {
      final result = await invoke(
        [],
        env: fakeEnv(),
        probe: fixedProbe(okWrite, deniedRead, const ProbeResponse(statusCode: 500, errorCode: 'InternalError')),
      );

      expect(result.code, ExitCodes.software);
      expect(result.err, contains('Delete probe (DELETE):  FAIL (HTTP 500 InternalError)'));
    });
  });

  group('usage', () {
    test('--help exits 0 and lists the shared bucket flags', () async {
      final result = await invoke(['--help'], env: const {});

      expect(result.code, ExitCodes.ok);
      expect(result.out, contains('Usage'));
      expect(result.out, contains('bucket-verify'));
      expect(result.out, contains('--access-key'));
      expect(result.out, contains('--bucket'));
    });

    test('unknown flag exits 64', () async {
      final result = await invoke(['--bogus'], env: fakeEnv());

      expect(result.code, ExitCodes.usage);
      expect(result.err, contains('--bogus'));
    });
  });

  group('probeObjectKey', () {
    test('formats a UTC timestamp under the verify prefix', () {
      expect(probeObjectKey(DateTime.utc(2026, 10, 25, 14, 30, 5)), '.photo-collector-verify/20261025T143005Z.png');
    });

    test('converts local times to UTC', () {
      final local = DateTime(2026, 1, 2, 3, 4, 5);
      final utc = local.toUtc();
      String pad(int value) => value.toString().padLeft(2, '0');
      expect(
        probeObjectKey(local),
        '.photo-collector-verify/${utc.year}${pad(utc.month)}${pad(utc.day)}T'
        '${pad(utc.hour)}${pad(utc.minute)}${pad(utc.second)}Z.png',
      );
    });
  });
}
