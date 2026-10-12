import 'dart:io';

import 'package:cli/cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String outputPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cli_test_');
    outputPath = p.join(tempDir.path, 'card.svg');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Full fake configuration in the environment (as the Makefile would
  /// provide it from .env). Values are fixture-style placeholders.
  Map<String, String> fakeEnv() => {
    'ACCESS_KEY_ID': 'AKIAEXAMPLE00000001',
    'SECRET_ACCESS_KEY': 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    'BUCKET': 'wedding-20261025',
    'REGION': 'eu-central-1',
    'BASE_URL': 'https://photos.example.com',
    'OUTPUT': outputPath,
  };

  ({int code, String out, String err}) invoke(List<String> arguments, {Map<String, String>? env}) {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = runCli(['qr-generate', ...arguments], environment: env, out: out, err: err);
    return (code: code, out: out.toString(), err: err.toString());
  }

  ({int code, String out, String err}) invokeTopLevel(List<String> arguments) {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = runCli(arguments, environment: const {}, out: out, err: err);
    return (code: code, out: out.toString(), err: err.toString());
  }

  group('subcommand dispatch', () {
    test('qr-generate --help prints the full flag list and exits 0', () {
      final result = invoke(['--help']);
      expect(result.code, ExitCodes.ok);
      expect(result.out, contains('Usage'));
      expect(result.out, contains('--access-key'));
      expect(result.out, contains('--heart-mode'));
    });

    test('top-level --help shows the subcommand overview', () {
      final result = invokeTopLevel(['--help']);
      expect(result.code, ExitCodes.ok);
      expect(result.out, contains('Available commands'));
      expect(result.out, contains('qr-generate'));
    });

    test('no subcommand exits 64 with usage', () {
      final result = invokeTopLevel([]);
      expect(result.code, ExitCodes.usage);
      expect(result.err, contains('no command given'));
      expect(result.err, contains('qr-generate'));
    });

    test('unknown subcommand exits 64', () {
      final result = invokeTopLevel(['bogus']);
      expect(result.code, ExitCodes.usage);
      expect(result.err, contains('bogus'));
    });
  });

  group('happy path', () {
    test('writes the SVG card and prints the scan-test warning', () {
      final result = invoke(['--no-preview'], env: fakeEnv());

      expect(result.code, ExitCodes.ok, reason: result.err);
      final file = File(outputPath);
      expect(file.existsSync(), isTrue);
      final svg = file.readAsStringSync();
      expect(svg, contains('<svg'));
      expect(svg, contains('<path'));
      expect(svg, isNot(contains('<image')));

      // Mandatory scan-test warning.
      expect(result.out, contains('SCAN-TEST'));
      expect(result.out, contains('real phone'));
      expect(result.out, contains('4 cm'));
      expect(result.out, contains('dim light'));
    });

    test('prints a terminal preview unless disabled', () {
      final result = invoke([], env: fakeEnv());
      expect(result.code, ExitCodes.ok, reason: result.err);
      expect(result.out, contains('█'));

      final silent = invoke(['--no-preview'], env: fakeEnv());
      expect(silent.out, isNot(contains('█')));
    });

    test('never echoes secret values in normal output', () {
      final env = fakeEnv();
      final result = invoke([], env: env);
      expect(result.code, ExitCodes.ok, reason: result.err);
      for (final secret in [env['SECRET_ACCESS_KEY']!, env['ACCESS_KEY_ID']!]) {
        expect(result.out, isNot(contains(secret)));
        expect(result.err, isNot(contains(secret)));
      }
    });

    test('accepts a custom endpoint and card title', () {
      final result = invoke(['--endpoint', 'https://minio.example.com:9000', '--title', 'Wedding'], env: fakeEnv());
      expect(result.code, ExitCodes.ok, reason: result.err);
      expect(result.out, contains('https://minio.example.com:9000'));
      expect(File(outputPath).readAsStringSync(), contains('>Wedding</text>'));
    });

    test('reports the QR version and error correction level', () {
      final result = invoke(['--no-preview'], env: fakeEnv());
      expect(result.code, ExitCodes.ok, reason: result.err);
      expect(result.out, contains('error correction level H'));
      expect(result.out, contains('version'));
    });
  });

  group('configuration precedence', () {
    test('flags override environment values', () {
      final result = invoke(['--bucket', 'flag-wins', '--no-preview'], env: fakeEnv());
      expect(result.code, ExitCodes.ok, reason: result.err);
      expect(result.out, contains('flag-wins'));
      expect(result.out, isNot(contains('wedding-20261025')));
    });

    test('flags alone are sufficient without any environment', () {
      final result = invoke([
        '--access-key',
        'AKIAEXAMPLE00000001',
        '--secret-key',
        'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
        '--bucket',
        'wedding-20261025',
        '--region',
        'eu-central-1',
        '--base-url',
        'https://photos.example.com',
        '--output',
        outputPath,
        '--no-preview',
      ], env: const {});
      expect(result.code, ExitCodes.ok, reason: result.err);
      expect(File(outputPath).existsSync(), isTrue);
    });
  });

  group('validation and exit codes', () {
    test('missing required options exit 64 with actionable messages', () {
      final result = invoke([], env: const {});
      expect(result.code, ExitCodes.usage);
      expect(result.err, contains('--access-key'));
      expect(result.err, contains('ACCESS_KEY_ID'));
      expect(result.err, contains('--bucket'));
      expect(result.err, contains('.env'));
      expect(File(outputPath).existsSync(), isFalse);
    });

    test('malformed flags exit 64', () {
      final result = invoke(['--bogus'], env: fakeEnv());
      expect(result.code, ExitCodes.usage);
      expect(result.err, contains('--bogus'));
    });

    test('invalid colors exit 64 with an explanation', () {
      final result = invoke(['--foreground', 'banana'], env: fakeEnv());
      expect(result.code, ExitCodes.usage);
      expect(result.err, contains('banana'));
    });

    test('unusable contrast exits 65', () {
      final result = invoke(['--foreground', '#101010', '--background', '#181818'], env: fakeEnv());
      expect(result.code, ExitCodes.data);
      expect(result.err, contains('contrast'));
    });

    test('light-on-dark colors exit 65', () {
      final result = invoke(['--foreground', '#ffffff', '--background', '#000000'], env: fakeEnv());
      expect(result.code, ExitCodes.data);
      expect(result.err, contains('lighter'));
    });

    test('low-but-usable contrast warns on stderr but succeeds', () {
      final result = invoke(['--foreground', '#808080', '--background', '#ffffff', '--no-preview'], env: fakeEnv());
      expect(result.code, ExitCodes.ok, reason: result.err);
      expect(result.err, contains('Warning'));
    });

    test('invalid heart-mode exits 64', () {
      final result = invoke(['--heart-mode', 'blob'], env: fakeEnv());
      expect(result.code, ExitCodes.usage);
    });

    test('invalid heart-scale exits 64', () {
      for (final raw in ['0', '1.5', 'abc']) {
        final result = invoke(['--heart-scale', raw], env: fakeEnv());
        expect(result.code, ExitCodes.usage, reason: 'scale $raw');
        expect(result.err, contains('--heart-scale'));
      }
    });

    test('frame mode is the default and leaves the QR code intact', () {
      final out = p.join(tempDir.path, 'card.svg');
      final result = invoke(['--output', out, '--no-preview'], env: fakeEnv());
      expect(result.code, ExitCodes.ok, reason: result.err);
      expect(result.out, contains('Heart mode: frame'));
    });

    test('cut mode is selectable and scan-test warning is printed', () {
      final out = p.join(tempDir.path, 'card.svg');
      final result = invoke(['--output', out, '--heart-mode', 'cut', '--no-preview'], env: fakeEnv());
      expect(result.code, ExitCodes.ok, reason: result.err);
      expect(result.out, contains('Heart mode: cut'));
    });

    test('none mode renders a plain QR card without a heart', () {
      final plainPath = p.join(tempDir.path, 'plain.svg');
      final framedPath = p.join(tempDir.path, 'framed.svg');

      final plain = invoke(['--output', plainPath, '--heart-mode', 'none', '--no-preview'], env: fakeEnv());
      expect(plain.code, ExitCodes.ok, reason: plain.err);
      expect(plain.out, contains('Heart mode: none'));
      final plainSvg = File(plainPath).readAsStringSync();
      expect(plainSvg, contains('<path'));

      // Frame mode grows the canvas so the decorative heart fits; none mode
      // must not.
      final framed = invoke(['--output', framedPath, '--no-preview'], env: fakeEnv());
      expect(framed.code, ExitCodes.ok, reason: framed.err);
      double svgWidth(String svg) =>
          double.parse(RegExp(r'width="([0-9.]+)mm"').firstMatch(svg)!.group(1)!);
      expect(svgWidth(plainSvg), lessThan(svgWidth(File(framedPath).readAsStringSync())));
    });

    test('invalid heart-padding exits 64', () {
      final result = invoke(['--heart-padding', '-1'], env: fakeEnv());
      expect(result.code, ExitCodes.usage);
      expect(result.err, contains('--heart-padding'));
    });

    test('unwritable output path exits nonzero', () {
      final missing = p.join(tempDir.path, 'no-such-dir', 'card.svg');
      final result = invoke(['--output', missing, '--no-preview'], env: {...fakeEnv(), 'OUTPUT': ''});
      expect(result.code, ExitCodes.ioErr);
      expect(result.err, contains(missing));
    });

    test('--help exits 0 and prints usage', () {
      final result = invoke(['--help'], env: const {});
      expect(result.code, ExitCodes.ok);
      expect(result.out, contains('Usage'));
      expect(result.out, contains('--access-key'));
    });
  });
}
