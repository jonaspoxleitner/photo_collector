import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'package:cli/src/qr_generate_command.dart';

/// Exit codes (BSD sysexits.h conventions).
class ExitCodes {
  static const int ok = 0;
  static const int usage = 64; // bad or missing arguments
  static const int data = 65; // unusable input data (e.g. colors)
  static const int software = 70; // internal failure
  static const int ioErr = 74; // output file could not be written
}

/// Top-level `cli` dispatcher: routes argv to subcommands and owns the
/// output/error sinks and the environment map subcommands read from.
class CliRunner extends CommandRunner<int> {
  CliRunner({Map<String, String>? environment, StringSink? out, StringSink? err})
    : environment = environment ?? Platform.environment,
      out = out ?? stdout,
      err = err ?? stderr,
      super('cli', 'Mints the photo_collector event token and writes a print-ready heart-themed SVG QR card.') {
    addCommand(QrGenerateCommand());
  }

  /// Configuration source for subcommands; defaults to the process environment.
  final Map<String, String> environment;

  /// Normal output sink; defaults to [stdout].
  final StringSink out;

  /// Error output sink; defaults to [stderr].
  final StringSink err;

  /// Parses [arguments] and runs the selected subcommand synchronously,
  /// returning a process exit code.
  ///
  /// [CommandRunner.run] is asynchronous, but the only subcommand completes
  /// synchronously; this wrapper keeps the CLI a plain `int` return so it can
  /// be handed straight to [exitCode]. Parse and usage errors are reported on
  /// [err] and mapped to [ExitCodes.usage].
  int dispatch(List<String> arguments) {
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
    if (command is QrGenerateCommand) return command.execute(subcommand);

    // The only other registered top-level command is the hidden built-in
    // `help`; show the top-level usage for it.
    out.writeln(usage);
    return ExitCodes.ok;
  }
}

/// Runs the QR card CLI with [arguments] and returns a process exit code.
///
/// Configuration comes from [environment] (defaults to the process
/// environment); see [QrGenerateCommand.execute]. Normal output never contains
/// secret values.
int runCli(List<String> arguments, {Map<String, String>? environment, StringSink? out, StringSink? err}) =>
    CliRunner(environment: environment, out: out, err: err).dispatch(arguments);
