import 'package:cli/cli.dart';
import 'package:test/test.dart';

void main() {
  String pathData(String svg) {
    final start = svg.indexOf('d="') + 3;
    return svg.substring(start, svg.indexOf('"/>', start));
  }

  // Synthetic 4x4 matrix, row 0 = [dark, dark, light, dark].
  bool pattern(int row, int col) => row == 0 && (col == 0 || col == 1 || col == 3);

  String svg({HeartMask? mask, SvgCardStyle style = const SvgCardStyle()}) =>
      renderSvgCard(moduleCount: 4, isDark: pattern, mask: mask, style: style);

  group('renderSvgCard structure', () {
    test('is a vector-only SVG with background rect and merged-runs path', () {
      final output = svg();
      expect(output, contains('<svg xmlns="http://www.w3.org/2000/svg"'));
      expect(output, contains('</svg>'));
      expect(output, contains('<rect width="100%" height="100%"'));
      expect(output, contains('<path'));
      expect(output, isNot(contains('<image'))); // no raster dependency
    });

    test('applies the quiet zone to the viewBox and module coordinates', () {
      final output = svg(); // quietZone = 4, moduleSize = 10
      // 4 modules + 2 * 4 quiet zone = 12 units of 10 = 120.
      expect(output, contains('viewBox="0 0 120 120"'));
      // First dark module of row 0 sits at (4, 4) in module space.
      expect(output, contains('M4,4'));
    });

    test('merges horizontal runs instead of emitting one rect per module', () {
      final output = svg();
      // row 0: dark dark light dark -> runs of length 2 and 1.
      expect(output, contains('M4,4h2v1h-2z'));
      expect(output, contains('M7,4h1v1h-1z'));
      final data = pathData(output);
      expect('M'.allMatches(data).length, 2, reason: 'two runs for the synthetic row, merged per run');
    });

    test('uses the configured colors', () {
      final output = svg(
        style: const SvgCardStyle(foreground: '#123456', background: '#fedcba'),
      );
      expect(output, contains('fill="#123456"'));
      expect(output, contains('fill="#fedcba"'));
    });

    test('renders and XML-escapes the optional title', () {
      final output = svg(style: const SvgCardStyle(title: 'A & B "wedding"'));
      expect(output, contains('<text'));
      expect(output, contains('A &amp; B &quot;wedding&quot;</text>'));
      // Title area grows the card.
      expect(output, contains('viewBox="0 0 120 140"'));
    });

    test('omits the text element when no title is given', () {
      expect(svg(), isNot(contains('<text')));
    });

    test('declares absolute mm dimensions for print', () {
      final output = svg(); // 120 units * 0.25 mm/unit = 30 mm
      expect(output, contains('width="30mm"'));
      expect(output, contains('height="30mm"'));
    });

    test('clips modules inside the heart mask', () {
      // 29x29 all-dark matrix: finder zones stay intact, the heart
      // silhouette in the middle gets clipped.
      bool allDark(int row, int col) => true;
      const style = SvgCardStyle();
      final masked = renderSvgCard(
        moduleCount: 29,
        isDark: allDark,
        mask: const HeartMask(scale: 1, padding: 1),
        style: style,
      );
      final unmasked = renderSvgCard(moduleCount: 29, isDark: allDark, style: style);
      final maskedData = pathData(masked);
      // The protected top-left finder run (8 modules) is still there.
      expect(maskedData, contains('M4,4h8v1h-8z'));
      // The heart silhouette in the center is clipped, so the masked card
      // draws strictly fewer modules than the unmasked one.
      int drawnModules(String d) => RegExp(r'h(\d+)v1').allMatches(d).fold(0, (sum, m) => sum + int.parse(m.group(1)!));
      expect(drawnModules(maskedData), lessThan(drawnModules(pathData(unmasked))));
    });
  });

  group('color parsing', () {
    test('accepts #rgb and #rrggbb', () {
      expect(parseHexColor('#000000'), 0x000000);
      expect(parseHexColor('#ffffff'), 0xFFFFFF);
      expect(parseHexColor('#0f0'), 0x00FF00);
      expect(parseHexColor('#Ab12cD'), 0xAB12CD);
      expect(parseHexColor('123456'), 0x123456); // without leading #
    });

    test('rejects malformed colors', () {
      expect(() => parseHexColor('#12'), throwsFormatException);
      expect(() => parseHexColor('#12345'), throwsFormatException);
      expect(() => parseHexColor('#gggggg'), throwsFormatException);
      expect(() => parseHexColor('red'), throwsFormatException);
      expect(() => parseHexColor(''), throwsFormatException);
    });

    test('black on white has contrast ratio 21:1', () {
      expect(contrastRatio(0x000000, 0xFFFFFF), closeTo(21, 0.01));
      expect(contrastRatio(0xFFFFFF, 0x000000), closeTo(21, 0.01));
      expect(contrastRatio(0x000000, 0x000000), closeTo(1, 0.001));
    });
  });
}
