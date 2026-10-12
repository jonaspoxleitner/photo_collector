import 'package:cli/cli.dart';
import 'package:test/test.dart';

void main() {
  group('heart curve', () {
    test('origin is inside, distant points are outside', () {
      expect(HeartMask.heartCurveValue(0, 0), lessThan(0));
      expect(HeartMask.heartCurveValue(2, 2), greaterThan(0));
      // Just above the top dip (x=0, y=1) lies outside.
      expect(HeartMask.heartCurveValue(0, 1.25), greaterThan(0));
      // A lobe point lies inside.
      expect(HeartMask.heartCurveValue(0.6, 1.2), lessThan(0));
    });

    test('is horizontally symmetric', () {
      for (final y in [-0.9, -0.5, 0.0, 0.5, 1.0]) {
        for (final x in [0.2, 0.7, 1.1]) {
          expect(HeartMask.heartCurveValue(x, y), HeartMask.heartCurveValue(-x, y));
        }
      }
    });
  });

  group('HeartMask.isInside', () {
    for (final n in [21, 25, 33, 41]) {
      test('grid center of $n modules is inside with the default mask', () {
        const mask = HeartMask();
        expect(mask.isInside(n, n ~/ 2, n ~/ 2), isTrue);
      });

      test('corners of $n modules are outside with the default mask', () {
        const mask = HeartMask();
        expect(mask.isInside(n, 0, 0), isFalse);
        expect(mask.isInside(n, n - 1, 0), isFalse);
        expect(mask.isInside(n, 0, n - 1), isFalse);
        expect(mask.isInside(n, n - 1, n - 1), isFalse);
      });

      test('mask is horizontally symmetric for $n modules', () {
        const mask = HeartMask(scale: 0.55, padding: 0.5);
        for (var row = 0; row < n; row++) {
          for (var col = 0; col < n; col++) {
            expect(mask.isInside(n, col, row), mask.isInside(n, n - 1 - col, row));
          }
        }
      });
    }

    test('larger scale clips a superset of modules', () {
      const small = HeartMask(scale: 0.3, padding: 0.5);
      const large = HeartMask(scale: 0.8, padding: 0.5);
      const n = 33;
      var clipped = 0;
      for (var row = 0; row < n; row++) {
        for (var col = 0; col < n; col++) {
          if (small.isInside(n, col, row)) {
            clipped++;
            expect(large.isInside(n, col, row), isTrue, reason: 'module ($col, $row)');
          }
        }
      }
      expect(clipped, greaterThan(0));
    });

    test('larger padding clips a superset of modules', () {
      const tight = HeartMask(scale: 0.55, padding: 0);
      const loose = HeartMask(scale: 0.55, padding: 2);
      const n = 33;
      for (var row = 0; row < n; row++) {
        for (var col = 0; col < n; col++) {
          if (tight.isInside(n, col, row)) {
            expect(loose.isInside(n, col, row), isTrue, reason: 'module ($col, $row)');
          }
        }
      }
    });
  });

  group('finder and separator protection', () {
    test('covers the 8x8 corner zones of the matrix', () {
      const n = 25;
      // Inside each protected zone.
      expect(HeartMask.isFinderRegion(n, 7, 7), isTrue); // top-left edge
      expect(HeartMask.isFinderRegion(n, n - 8, 0), isTrue); // top-right
      expect(HeartMask.isFinderRegion(n, 0, n - 1), isTrue); // bottom-left
      // Just outside.
      expect(HeartMask.isFinderRegion(n, 8, 0), isFalse);
      expect(HeartMask.isFinderRegion(n, 0, 8), isFalse);
      // Bottom-right corner has no finder pattern.
      expect(HeartMask.isFinderRegion(n, n - 1, n - 1), isFalse);
    });

    test('finder patterns and separators stay intact for every mask '
        'configuration', () {
      for (final n in [21, 25, 33]) {
        for (final mask in <HeartMask>[
          const HeartMask(),
          const HeartMask(scale: 1, padding: 0),
          const HeartMask(scale: 1, padding: 4),
        ]) {
          // All-dark synthetic matrix: worst case for clipping.
          bool allDark(int row, int col) => true;
          for (var row = 0; row < n; row++) {
            for (var col = 0; col < n; col++) {
              final visible = isVisibleModule(mask: mask, isDark: allDark, moduleCount: n, row: row, col: col);
              if (HeartMask.isFinderRegion(n, col, row)) {
                expect(
                  visible,
                  isTrue,
                  reason:
                      'protected module ($col, $row) of $n '
                      'with scale=${mask.scale}, padding=${mask.padding}',
                );
              }
            }
          }
        }
      }
    });

    test('the mask actually clips something outside protected zones', () {
      const n = 33;
      const mask = HeartMask(scale: 1, padding: 3);
      bool allDark(int row, int col) => true;
      var clipped = 0;
      for (var row = 0; row < n; row++) {
        for (var col = 0; col < n; col++) {
          if (!HeartMask.isFinderRegion(n, col, row) &&
              !isVisibleModule(mask: mask, isDark: allDark, moduleCount: n, row: row, col: col)) {
            clipped++;
          }
        }
      }
      expect(clipped, greaterThan(0));
    });
  });
}
