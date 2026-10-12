import 'package:args/args.dart';
import 'package:cli/cli.dart';
import 'package:test/test.dart';

void main() {
  ArgParser parser() {
    final parser = ArgParser();
    addBucketOptions(parser);
    return parser;
  }

  ArgResults parse(List<String> arguments) => parser().parse(arguments);

  /// Full fake bucket configuration in the environment, as the root Makefile
  /// exports it from `.env`. Values are fixture-style placeholders.
  Map<String, String> fakeEnv() => {
    'ACCESS_KEY_ID': 'AKIAEXAMPLE00000001',
    'SECRET_ACCESS_KEY': 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    'BUCKET': 'wedding-20261025',
    'REGION': 'eu-central-1',
    'ENDPOINT': 'https://minio.example.com:9000',
  };

  group('resolveBucketConfig', () {
    test('falls back to environment values when no flags are passed', () {
      final resolved = resolveBucketConfig(parse(const []), fakeEnv());

      expect(resolved.missing, isEmpty);
      final config = resolved.config!;
      expect(config.accessKeyId, 'AKIAEXAMPLE00000001');
      expect(config.secretKey, 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY');
      expect(config.bucket, 'wedding-20261025');
      expect(config.region, 'eu-central-1');
      expect(config.endpoint, 'https://minio.example.com:9000');
    });

    test('flag values override environment values', () {
      final resolved = resolveBucketConfig(
        parse(const [
          '--access-key',
          'AKIAFLAG0000000001',
          '--secret-key',
          'flag-secret',
          '--bucket',
          'flag-bucket',
          '--region',
          'us-east-1',
          '--endpoint',
          'https://flag.example.com',
        ]),
        fakeEnv(),
      );

      expect(resolved.missing, isEmpty);
      final config = resolved.config!;
      expect(config.accessKeyId, 'AKIAFLAG0000000001');
      expect(config.secretKey, 'flag-secret');
      expect(config.bucket, 'flag-bucket');
      expect(config.region, 'us-east-1');
      expect(config.endpoint, 'https://flag.example.com');
    });

    test('flags alone are sufficient without any environment', () {
      final resolved = resolveBucketConfig(
        parse(const [
          '--access-key',
          'AKIAEXAMPLE00000001',
          '--secret-key',
          'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
          '--bucket',
          'wedding-20261025',
          '--region',
          'eu-central-1',
        ]),
        const {},
      );

      expect(resolved.missing, isEmpty);
      expect(resolved.config!.endpoint, isNull);
    });

    test('endpoint is optional and defaults to null', () {
      final env = fakeEnv()..remove('ENDPOINT');
      final resolved = resolveBucketConfig(parse(const []), env);

      expect(resolved.missing, isEmpty);
      expect(resolved.config!.endpoint, isNull);
    });

    test('values are trimmed', () {
      final resolved = resolveBucketConfig(parse(const ['--bucket', '  spaced  ']), fakeEnv());

      expect(resolved.missing, isEmpty);
      expect(resolved.config!.bucket, 'spaced');
    });

    test('missing required values are reported together', () {
      final resolved = resolveBucketConfig(parse(const []), const {});

      expect(resolved.config, isNull);
      expect(resolved.missing, [
        '--access-key (or set ACCESS_KEY_ID in .env)',
        '--secret-key (or set SECRET_ACCESS_KEY in .env)',
        '--bucket (or set BUCKET in .env)',
        '--region (or set REGION in .env)',
      ]);
    });

    test('an empty env value counts as missing', () {
      final env = fakeEnv()..['BUCKET'] = '   ';
      final resolved = resolveBucketConfig(parse(const []), env);

      expect(resolved.config, isNull);
      expect(resolved.missing, ['--bucket (or set BUCKET in .env)']);
    });

    test('a flag passed empty overrides the environment fallback', () {
      final resolved = resolveBucketConfig(parse(const ['--bucket', '']), fakeEnv());

      expect(resolved.config, isNull);
      expect(resolved.missing, ['--bucket (or set BUCKET in .env)']);
    });
  });
}
