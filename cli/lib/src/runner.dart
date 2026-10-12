import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'package:cli/src/bucket_verify_command.dart';
import 'package:cli/src/qr_generate_command.dart';

/// Exit codes (BSD sysexits.h conventions).
class ExitCodes {
  static const int ok = 0;
  static const int usage = 64; // bad or missing arguments
  static const int data = 65; // unusable input data (e.g. colors)
  static const int software = 70; // internal failure
  static const int ioErr = 74; // output file could not be written
}

/// A subcommand that reports its outcome as a process exit code instead of
/// throwing.
///
/// The runner dispatches every subcommand through [execute], so a subcommand
/// may be synchronous (local rendering) or asynchronous (network probes).
abstract class CliCommand extends Command<int> {
  /// Runs the command with parsed [args] and returns the process exit code.
  Future<int> execute(ArgResults args);

  @override
  Future<int> run() => execute(argResults!);
}

/// Top-level `cli` dispatcher: routes argv to subcommands and owns the
/// output/error sinks and the environment map subcommands read from.
class CliRunner extends CommandRunner<int> {
  CliRunner({Map<String, String>? environment, StringSink? out, StringSink? err, BucketProbe? bucketProbe})
    : environment = environment ?? Platform.environment,
      out = out ?? stdout,
      err = err ?? stderr,
      super('cli', 'Mints the photo_collector event token and writes a print-ready heart-themed SVG QR card.') {
    addCommand(QrGenerateCommand());
    addCommand(BucketVerifyCommand(probe: bucketProbe));
  }

  /// Configuration source for subcommands; defaults to the process environment.
  final Map<String, String> environment;

  /// Normal output sink; defaults to [stdout].
  final StringSink out;

  /// Error output sink; defaults to [stderr].
  final StringSink err;

  /// Parses [arguments] and runs the selected subcommand, returning a future of
  /// the process exit code.
  ///
  /// [CommandRunner.run] is asynchronous, but the runner dispatches through
  /// [CliCommand.execute]; synchronous subcommands complete without suspending.
  /// Parse and usage errors are reported on [err] and mapped to
  /// [ExitCodes.usage].
  Future<int> dispatch(List<String> arguments) async {
    final ArgResults topLevel;
    try {
      topLevel = parse(arguments);
    } on UsageException catch (e) {
      err.writeln('Error: ${e.message}');
      err.writeln(e.usage);
      return ExitCodes.usage;
    }

    final subcommand = topLevel.command;
    if (subcommand == null) {
      if (topLevel.flag('help')) {
        out.writeln(usage);
        return ExitCodes.ok;
      }
      final requested = topLevel.rest.isEmpty ? null : topLevel.rest.first;
      err.writeln(
        requested == null ? 'Error: no command given.' : 'Error: could not find a command named "$requested".',
      );
      err.writeln(usage);
      return ExitCodes.usage;
    }

    final command = commands[subcommand.name]!;
    if (subcommand.options.contains('help') && subcommand.flag('help')) {
      out.writeln(command.usage);
      return ExitCodes.ok;
    }
    if (command is CliCommand) return await command.execute(subcommand);

    // The only other registered top-level command is the hidden built-in
    // `help`; show the top-level usage for it.
    out.writeln(usage);
    return ExitCodes.ok;
  }
}

/// Runs the host CLI with [arguments] and returns a future of the process
/// exit code.
///
/// Configuration comes from [environment] (defaults to the process
/// environment); see [CliCommand.execute]. Normal output never contains
/// secret values.
Future<int> runCli(
  List<String> arguments, {
  Map<String, String>? environment,
  StringSink? out,
  StringSink? err,
  BucketProbe? bucketProbe,
}) => CliRunner(environment: environment, out: out, err: err, bucketProbe: bucketProbe).dispatch(arguments);
