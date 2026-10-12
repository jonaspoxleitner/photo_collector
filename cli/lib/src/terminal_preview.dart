import 'package:cli/src/heart_frame.dart';

/// Renders a compact terminal preview of the QR matrix for quick scan
/// testing, using Unicode half-block characters so each terminal row shows
/// two module rows.
///
/// [isDark] receives `(row, col)` — matching `QrImage.isDark` from
/// package:qr. [quietZone] adds light margin modules on all sides (defaults
/// to 2 for terminal readability). When [frame] is set, the decorative
/// heart frame around the matrix is rendered as well.
String renderTerminalPreview({
  required int moduleCount,
  required bool Function(int row, int col) isDark,
  int quietZone = 2,
  HeartFrame? frame,
}) {
  final radius = frame?.resolvedRadius(moduleCount, quietZone);

  // Bounding box of everything drawn (matrix + frame) in matrix coordinates,
  // so the preview gets even margins even when the heart is asymmetric.
  final bounds = frame?.drawnBounds(moduleCount, quietZone, radius!) ?? (0, 0, 0, 0);
  final contentMinRow = bounds.$1 < 0 ? bounds.$1 : 0;
  final contentMaxRow = bounds.$2 > moduleCount ? bounds.$2 : moduleCount;
  final contentMinCol = bounds.$3 < 0 ? bounds.$3 : 0;
  final contentMaxCol = bounds.$4 > moduleCount ? bounds.$4 : moduleCount;
  final originX = quietZone - contentMinCol;
  final originY = quietZone - contentMinRow;
  final canvasWidth = (contentMaxCol - contentMinCol) + 2 * quietZone;
  final canvasHeight = (contentMaxRow - contentMinRow) + 2 * quietZone;

  bool darkAt(int col, int row) {
    final c = col - originX;
    final r = row - originY;
    if (r >= 0 && r < moduleCount && c >= 0 && c < moduleCount) {
      return isDark(r, c);
    }
    if (radius == null) return false;
    return frame!.isFrameModule(moduleCount, quietZone, c, r, radius);
  }

  final buffer = StringBuffer();
  for (var row = 0; row < canvasHeight; row += 2) {
    final line = StringBuffer();
    for (var col = 0; col < canvasWidth; col++) {
      final top = darkAt(col, row);
      final bottom = row + 1 < canvasHeight && darkAt(col, row + 1);
      if (top && bottom) {
        line.write('█'); // both modules dark
      } else if (top) {
        line.write('▀'); // upper module dark
      } else if (bottom) {
        line.write('▄'); // lower module dark
      } else {
        line.write(' ');
      }
    }
    buffer
      ..write(line.toString().trimRight())
      ..write('\n');
  }
  return buffer.toString();
}
