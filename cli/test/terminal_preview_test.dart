import 'package:cli/cli.dart';
import 'package:test/test.dart';

void main() {
  group('renderTerminalPreview', () {
    test('renders two module rows per terminal line', () {
      bool allDark(int row, int col) => true;
      final preview = renderTerminalPreview(moduleCount: 2, isDark: allDark, quietZone: 0);
      // 2x2 all dark: one terminal line of two full blocks.
      expect(preview, '██\n');
    });

    test('uses half blocks for partially dark row pairs', () {
      bool topOnly(int row, int col) => row == 0;
      bool bottomOnly(int row, int col) => row == 1;
      expect(renderTerminalPreview(moduleCount: 2, isDark: topOnly, quietZone: 0), '▀▀\n');
      expect(renderTerminalPreview(moduleCount: 2, isDark: bottomOnly, quietZone: 0), '▄▄\n');
    });

    test('renders all-light matrices as whitespace', () {
      bool allLight(int row, int col) => false;
      final preview = renderTerminalPreview(moduleCount: 2, isDark: allLight, quietZone: 0);
      expect(preview.trim(), isEmpty);
    });

    test('adds the quiet zone around the matrix', () {
      bool allDark(int row, int col) => true;
      final preview = renderTerminalPreview(moduleCount: 21, isDark: allDark);
      final lines = preview.split('\n');
      // 21 + 2*2 = 25 module rows -> 13 terminal lines (the odd last row is
      // half-height), plus the empty remainder after the trailing newline.
      expect(lines.length, 14);
      expect(lines[0], isEmpty); // top quiet zone is light
      expect(lines[2].length, 23); // 2 light + 21 dark, trailing trimmed
    });

    test('includes a finder-like pattern from real QR images', () {
      // Sanity: the delegate signature matches QrImage.isDark(row, col).
      bool isDark(int row, int col) => row < 7 && col < 7 && row != 3;
      final preview = renderTerminalPreview(moduleCount: 7, isDark: isDark);
      expect(preview, contains('█'));
    });
  });
}
