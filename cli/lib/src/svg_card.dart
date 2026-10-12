import 'dart:math' as math;

import 'package:cli/src/heart_frame.dart';
import 'package:cli/src/heart_mask.dart';

/// Visual style of the print-ready SVG card.
class SvgCardStyle {
  const SvgCardStyle({
    this.title,
    this.foreground = '#000000',
    this.background = '#ffffff',
    this.moduleSize = 10,
    this.quietZoneModules = 4,
    this.mmPerUnit = 0.25,
  });

  /// Optional card title rendered above the QR code. No title area is
  /// reserved when null.
  final String? title;

  /// QR module (dark) color, `#rgb` or `#rrggbb`.
  final String foreground;

  /// Card background color, `#rgb` or `#rrggbb`.
  final String background;

  /// Size of one QR module in SVG user units.
  final double moduleSize;

  /// Quiet zone around the QR matrix, in modules (4 per ISO/IEC 18004).
  final int quietZoneModules;

  /// Millimeters per SVG user unit, for print-ready absolute dimensions.
  final double mmPerUnit;
}

/// Parses a `#rgb` or `#rrggbb` color string (the leading `#` is optional)
/// into `0xRRGGBB`. Throws [FormatException] for anything else.
int parseHexColor(String input) {
  var hex = input.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length != 6) {
    throw FormatException('color must be #rgb or #rrggbb, got "$input"', input);
  }
  final value = int.tryParse(hex, radix: 16);
  if (value == null) {
    throw FormatException('color must be #rgb or #rrggbb, got "$input"', input);
  }
  return value;
}

/// WCAG relative luminance of an `0xRRGGBB` color, in [0, 1].
double relativeLuminance(int rgb) {
  double channel(int c) {
    final v = c / 255;
    return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel((rgb >> 16) & 0xFF) + 0.7152 * channel((rgb >> 8) & 0xFF) + 0.0722 * channel(rgb & 0xFF);
}

/// WCAG contrast ratio between two `0xRRGGBB` colors, in [1, 21].
double contrastRatio(int a, int b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Whether the QR module at ([row], [col]) is drawn in the card output.
/// Dark modules inside the heart mask are clipped, except inside the
/// protected finder/separator zones, which always render intact.
bool isVisibleModule({
  required HeartMask? mask,
  required bool Function(int row, int col) isDark,
  required int moduleCount,
  required int row,
  required int col,
}) {
  if (!isDark(row, col)) return false;
  if (mask == null) return true;
  if (HeartMask.isFinderRegion(moduleCount, col, row)) return true;
  return !mask.isInside(moduleCount, col, row);
}

/// Renders the print-ready SVG card as pure vector output (no raster
/// dependencies): one merged-runs `<path>` for all dark modules, a
/// background `<rect>`, and an optional `<text>` title. Consecutive dark
/// modules in a row are merged into single horizontal run segments.
///
/// [isDark] receives `(row, col)` — matching `QrImage.isDark` from
/// package:qr. Pass either [mask] (clips a heart-shaped hole out of the
/// code) or [frame] (draws a heart-shaped frame of decorative modules
/// around the untouched code), or neither. Frame mode grows the canvas so
/// the heart always fits; the QR code itself is never modified.
String renderSvgCard({
  required int moduleCount,
  required bool Function(int row, int col) isDark,
  HeartMask? mask,
  HeartFrame? frame,
  SvgCardStyle style = const SvgCardStyle(),
}) {
  assert(mask == null || frame == null, 'mask and frame are exclusive');

  final q = style.quietZoneModules;
  final frameRadius = frame?.resolvedRadius(moduleCount, q);

  // Content bounding box in matrix coordinates: QR matrix unioned with the
  // drawn frame. Framing by content (instead of a fixed symmetric extension)
  // yields even margins even when the heart is vertically asymmetric.
  final bounds = frame?.drawnBounds(moduleCount, q, frameRadius!) ?? (0, 0, 0, 0);
  final contentMinRow = math.min(0, bounds.$1);
  final contentMaxRow = math.max(moduleCount, bounds.$2);
  final contentMinCol = math.min(0, bounds.$3);
  final contentMaxCol = math.max(moduleCount, bounds.$4);
  final offsetX = q - contentMinCol;
  final offsetY = q - contentMinRow;

  bool visibleAt(int row, int col) {
    final insideMatrix = row >= 0 && row < moduleCount && col >= 0 && col < moduleCount;
    if (insideMatrix) {
      return isVisibleModule(mask: mask, isDark: isDark, moduleCount: moduleCount, row: row, col: col);
    }
    if (frame == null) return false;
    return frame.isFrameModule(moduleCount, q, col, row, frameRadius!);
  }

  final segments = StringBuffer();
  for (var row = contentMinRow; row < contentMaxRow; row++) {
    var col = contentMinCol;
    while (col < contentMaxCol) {
      if (!visibleAt(row, col)) {
        col++;
        continue;
      }
      final start = col;
      while (col < contentMaxCol && visibleAt(row, col)) {
        col++;
      }
      final length = col - start;
      segments.write(
        'M${start + offsetX},${row + offsetY}h$length'
        'v1h${-length}z',
      );
    }
  }

  final qrWidth = contentMaxCol - contentMinCol + 2 * q;
  final qrHeight = contentMaxRow - contentMinRow + 2 * q;
  final hasTitle = style.title != null && style.title!.isNotEmpty;
  final titleAreaUnits = hasTitle ? 2 * style.moduleSize : 0.0;
  final widthUnits = qrWidth * style.moduleSize;
  final heightUnits = qrHeight * style.moduleSize + titleAreaUnits;
  final widthMm = widthUnits * style.mmPerUnit;
  final heightMm = heightUnits * style.mmPerUnit;

  final buffer = StringBuffer()
    ..writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'width="${_formatNumber(widthMm)}mm" '
      'height="${_formatNumber(heightMm)}mm" '
      'viewBox="0 0 ${_formatNumber(widthUnits)} '
      '${_formatNumber(heightUnits)}" '
      'role="img">',
    )
    ..writeln(
      '  <rect width="100%" height="100%" '
      'fill="${style.background}"/>',
    );

  if (hasTitle) {
    buffer.writeln(
      '  <text x="${_formatNumber(widthUnits / 2)}" '
      'y="${_formatNumber(style.moduleSize * 1.4)}" '
      'text-anchor="middle" font-family="sans-serif" '
      'font-size="${_formatNumber(style.moduleSize * 1.1)}" '
      'fill="${style.foreground}">'
      '${escapeXml(style.title!)}</text>',
    );
  }

  buffer
    ..writeln(
      '  <g transform="translate(0, ${_formatNumber(titleAreaUnits)}) '
      'scale(${_formatNumber(style.moduleSize)})">',
    )
    ..writeln(
      '    <path fill="${style.foreground}" '
      'd="${segments.toString()}"/>',
    )
    ..writeln('  </g>')
    ..writeln('</svg>');
  return buffer.toString();
}

/// Escapes XML special characters for use in text and attribute content.
String escapeXml(String input) => input
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  var s = value.toStringAsFixed(2);
  while (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return s;
}
