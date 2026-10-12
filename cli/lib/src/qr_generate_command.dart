import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli/src/heart_frame.dart';
import 'package:cli/src/heart_mask.dart';
import 'package:cli/src/runner.dart';
import 'package:cli/src/svg_card.dart';
import 'package:cli/src/terminal_preview.dart';
import 'package:cli/src/token.dart';
import 'package:qr/qr.dart';

/// Scan-tested defaults: clipping at scale 0.62 failed real-device
/// scanning; 0.3 scans reliably. Frame mode never modifies the code.
const HeartMask _defaultCutMask = HeartMask(scale: 0.3);
const HeartFrame _defaultFrame = HeartFrame();

/// `qr-generate` subcommand: mints the event token and writes a print-ready
/// heart-themed SVG QR card.
class QrGenerateCommand extends Command<int> {
  QrGenerateCommand() {
    argParser
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
      )
      ..addOption(
        'base-url',
        help:
            'Public base URL of the deployed guest app. '
            'Overrides BASE_URL.',
      )
      ..addOption('output', help: 'SVG output path. Overrides OUTPUT (default: card.svg).')
      ..addOption('title', help: 'Optional card title. Overrides TITLE.')
      ..addOption(
        'foreground',
        help:
            'QR module color (#rgb or #rrggbb). '
            'Overrides FOREGROUND (default: #000000).',
      )
      ..addOption(
        'background',
        help:
            'Card background color (#rgb or #rrggbb). '
            'Overrides BACKGROUND (default: #ffffff).',
      )
      ..addOption(
        'heart-mode',
        allowed: const ['frame', 'cut', 'none'],
        defaultsTo: 'frame',
        help:
            'How the heart is applied: `frame` draws decorative fake '
            'modules around the QR code (scan-safe; the code is never '
            'modified), `cut` clips a heart silhouette out of the center, '
            '`none` renders a plain QR code without a heart (default: frame).',
      )
      ..addOption(
        'heart-scale',
        help:
            'Cut mode: heart silhouette size as a fraction of the QR '
            'width, in (0, 1] (default: ${_defaultCutMask.scale}). '
            'Frame mode: extra dilation beyond the minimal enclosing heart, '
            'in (0, 1] (default: ${_defaultFrame.scaleBoost}). '
            'Ignored in none mode.',
      )
      ..addOption(
        'heart-padding',
        help:
            'Cut mode: extra clipped margin around the heart, in modules '
            '(default: ${_defaultCutMask.padding}). '
            'Frame mode: extra white gap between the quiet zone and the '
            'heart, in modules (default: ${_defaultFrame.gapModules}). '
            'Ignored in none mode.',
      )
      ..addOption(
        'heart-vshift',
        help:
            'Frame mode: moves the heart down relative to the QR code so '
            'the code sits higher inside the heart, in curve units '
            '(default: ${_defaultFrame.verticalShift}). '
            'Ignored in none mode.',
      )
      ..addFlag('preview', defaultsTo: true, help: 'Print a terminal QR preview for quick scan testing.');
  }

  @override
  String get name => 'qr-generate';

  @override
  String get description =>
      'Mints the photo_collector event token and writes a print-ready '
      'heart-themed SVG QR card.';

  @override
  String? get usageFooter => 'Values are read from the root .env (via the Makefile) unless overridden by flags.';

  @override
  int run() => execute(argResults!);

  /// Generates the card for [args] and returns a process exit code instead of
  /// throwing.
  ///
  /// Configuration comes from the runner's [CliRunner.environment] (defaults
  /// to the process environment, which the root Makefile populates from the
  /// git-ignored `.env`); command-line flags take precedence over environment
  /// values.
  ///
  /// Normal output never contains secret values: the minted token and the
  /// guest URL (which embeds the credentials) are not printed.
  int execute(ArgResults args) {
    final cli = runner! as CliRunner;
    final env = cli.environment;
    final out = cli.out;
    final err = cli.err;

    String? opt(String flag, String envName) => args.wasParsed(flag) ? args.option(flag) : env[envName];

    final missing = <String>[];
    String required(String flag, String envName) {
      final value = opt(flag, envName)?.trim();
      if (value == null || value.isEmpty) {
        missing.add('--$flag (or set $envName in .env)');
        return '';
      }
      return value;
    }

    final accessKey = required('access-key', 'ACCESS_KEY_ID');
    final secretKey = required('secret-key', 'SECRET_ACCESS_KEY');
    final bucket = required('bucket', 'BUCKET');
    final region = required('region', 'REGION');
    final baseUrl = required('base-url', 'BASE_URL');

    if (missing.isNotEmpty) {
      err.writeln('Missing required configuration:');
      for (final item in missing) {
        err.writeln('  $item');
      }
      err.writeln('Pass flags, or copy .env.example to .env at the repo root.');
      return ExitCodes.usage;
    }

    final endpoint = opt('endpoint', 'ENDPOINT')?.trim();
    final output = opt('output', 'OUTPUT')?.trim().isNotEmpty == true ? opt('output', 'OUTPUT')!.trim() : 'card.svg';
    final title = opt('title', 'TITLE')?.trim().isNotEmpty == true ? opt('title', 'TITLE')!.trim() : null;
    final foreground = opt('foreground', 'FOREGROUND') ?? '#000000';
    final background = opt('background', 'BACKGROUND') ?? '#ffffff';

    // Flag semantics depend on the heart mode; both stay in (0, 1] / >= 0.
    final heartMode = args.option('heart-mode')!;
    final HeartMask? mask;
    final HeartFrame? frame;
    try {
      if (heartMode == 'none') {
        // Plain QR card: heart tuning flags do not apply.
        mask = null;
        frame = null;
      } else if (heartMode == 'frame') {
        final scale = _parseFraction('heart-scale', args.option('heart-scale'), _defaultFrame.scaleBoost);
        final padding = _parsePadding('heart-padding', args.option('heart-padding'), _defaultFrame.gapModules.toDouble());
        final vshift = _parsePadding('heart-vshift', args.option('heart-vshift'), _defaultFrame.verticalShift);
        frame = HeartFrame(gapModules: padding.round(), scaleBoost: scale, verticalShift: vshift);
        mask = null;
      } else {
        final scale = _parseFraction('heart-scale', args.option('heart-scale'), _defaultCutMask.scale);
        final padding = _parsePadding('heart-padding', args.option('heart-padding'), _defaultCutMask.padding);
        mask = HeartMask(scale: scale, padding: padding);
        frame = null;
      }
    } on FormatException catch (e) {
      err.writeln('Error: ${e.message}');
      return ExitCodes.usage;
    }

    final int fgRgb;
    final int bgRgb;
    try {
      fgRgb = parseHexColor(foreground);
      bgRgb = parseHexColor(background);
    } on FormatException catch (e) {
      err.writeln('Error: ${e.message}');
      return ExitCodes.usage;
    }

    final ratio = contrastRatio(fgRgb, bgRgb);
    if (relativeLuminance(fgRgb) > relativeLuminance(bgRgb)) {
      err.writeln(
        'Error: foreground "$foreground" is lighter than background '
        '"$background" — QR scanners expect dark modules on a light card.',
      );
      return ExitCodes.data;
    }
    if (ratio < 2.0) {
      err.writeln(
        'Error: foreground/background contrast ratio '
        '${ratio.toStringAsFixed(2)}:1 is unusable for QR scanning.',
      );
      return ExitCodes.data;
    }
    if (ratio < 4.5) {
      err.writeln(
        'Warning: foreground/background contrast ratio '
        '${ratio.toStringAsFixed(2)}:1 is low; scannability may suffer, '
        'especially in dim light.',
      );
    }

    final String url;
    try {
      final token = mintEventToken(
        accessKeyId: accessKey,
        secretKey: secretKey,
        bucket: bucket,
        region: region,
        endpoint: endpoint == null || endpoint.isEmpty ? null : endpoint,
      );
      url = buildEventUrl(baseUrl, token);
    } on EventTokenFormatException catch (e) {
      err.writeln('Error: ${e.message}');
      return ExitCodes.usage;
    }

    // Error correction level H is mandatory: it recovers up to ~30% damaged
    // modules. Frame mode never damages any modules; in cut mode it is what
    // makes the heart silhouette mask safe.
    final QrImage qrImage;
    try {
      final qrCode = QrCode(payload: QrPayload.fromString(url), errorCorrectLevel: QrErrorCorrectLevel.high);
      qrImage = QrImage(qrCode);
    } on InputTooLongException catch (e) {
      err.writeln(
        'Error: guest URL is too long for a QR code '
        '(${e.inputBits} bits > ${e.inputLimit} bits).',
      );
      return ExitCodes.data;
    }

    final svg = renderSvgCard(
      moduleCount: qrImage.moduleCount,
      isDark: qrImage.isDark,
      mask: mask,
      frame: frame,
      style: SvgCardStyle(title: title, foreground: foreground, background: background),
    );

    try {
      File(output).writeAsStringSync(svg);
    } on FileSystemException catch (e) {
      err.writeln('Error: could not write "$output": ${e.message}');
      return ExitCodes.ioErr;
    }

    out.writeln(
      'Bucket "$bucket" in region "$region"'
      '${endpoint == null || endpoint.isEmpty ? '' : ' via $endpoint'}.',
    );
    out.writeln(
      'QR code: version ${qrImage.typeNumber}, '
      '${qrImage.moduleCount}x${qrImage.moduleCount} modules, '
      'error correction level H.',
    );
    out.writeln('Card written to $output.');

    out.writeln(
      'Heart mode: $heartMode'
      '${heartMode == 'frame' ? ' (decorative ring; QR code untouched)' : ''}'
      '${heartMode == 'none' ? ' (plain QR code, no heart)' : ''}.',
    );

    if (args.flag('preview')) {
      out.writeln();
      out.write(renderTerminalPreview(moduleCount: qrImage.moduleCount, isDark: qrImage.isDark, frame: frame));
    }

    out.writeln();
    out.writeln('SCAN-TEST THIS CARD BEFORE PRINTING:');
    out.writeln('  1. Scan it from a real phone (not an emulator).');
    out.writeln(
      '  2. Test at the final print size - the QR must be at least '
      '4 cm wide.',
    );
    out.writeln('  3. Test in dim light (candles, evening venue lighting).');
    return ExitCodes.ok;
  }
}

double _parseFraction(String name, String? raw, double fallback) {
  if (raw == null || raw.trim().isEmpty) return fallback;
  final value = double.tryParse(raw.trim());
  if (value == null || value <= 0 || value > 1) {
    throw FormatException('--$name must be a number in (0, 1], got "$raw"');
  }
  return value;
}

double _parsePadding(String name, String? raw, double fallback) {
  if (raw == null || raw.trim().isEmpty) return fallback;
  final value = double.tryParse(raw.trim());
  if (value == null || value < 0) {
    throw FormatException('--$name must be a number >= 0, got "$raw"');
  }
  return value;
}
