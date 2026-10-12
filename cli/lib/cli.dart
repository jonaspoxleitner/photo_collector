/// photo_collector host CLI.
///
/// Mints the `?d=` event token shared with the guest app, renders a
/// heart-masked QR code (error correction level H, intact finder patterns),
/// and writes a print-ready SVG card.
library;

export 'src/heart_mask.dart';
export 'src/qr_generate_command.dart';
export 'src/runner.dart';
export 'src/svg_card.dart';
export 'src/terminal_preview.dart';
export 'src/token.dart';
