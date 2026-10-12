import 'package:cli/src/heart_frame.dart';
import 'package:test/test.dart';

void main() {
  const frame = HeartFrame();
  const n = 69;
  const q = 4;

  final radius = frame.resolvedRadius(n, q);
  final extent = frame.extent(n, q, radius);

  group('HeartFrame', () {
    test('never draws inside the matrix, quiet zone, or gap', () {
      final halfSide = n / 2 + q + frame.gapModules;
      for (var row = -extent; row < n + extent; row++) {
        for (var col = -extent; col < n + extent; col++) {
          final dx = col + 0.5 - n / 2;
          final dy = row + 0.5 - n / 2;
          if (dx.abs() < halfSide && dy.abs() < halfSide) {
            expect(
              frame.isFrameModule(n, q, col, row, radius),
              isFalse,
              reason: '($col,$row) inside the protected square',
            );
          }
        }
      }
    });

    test('draws a nonempty, confined region', () {
      var count = 0;
      for (var row = -extent; row < n + extent; row++) {
        for (var col = -extent; col < n + extent; col++) {
          if (frame.isFrameModule(n, q, col, row, radius)) count++;
        }
      }
      expect(count, greaterThan(100));
      // No frame module outside the claimed extent.
      for (var row = -extent - 3; row <= n + extent + 3; row++) {
        for (final col in [-extent - 3, -extent - 2, -extent - 1]) {
          expect(frame.isFrameModule(n, q, col, row, radius), isFalse);
        }
      }
    });

    test('ring boundary corners stay white; heart hugs the square', () {
      // Ring corner modules (|dx|,|dy| at the square edge) are protected.
      for (final (col, row) in [(-6, -6), (-6, 74), (74, -6), (74, 74)]) {
        expect(frame.isFrameModule(n, q, col, row, radius), isFalse, reason: 'ring corner ($col,$row) must stay white');
      }
      // Lobes above and tip below the ring produce decoration.
      bool anyIn(int row0, int row1, int col0, int col1) {
        for (var row = row0; row <= row1; row++) {
          for (var col = col0; col <= col1; col++) {
            if (frame.isFrameModule(n, q, col, row, radius)) return true;
          }
        }
        return false;
      }

      expect(anyIn(-extent, -7, 10, 60), isTrue, reason: 'heart lobes');
      expect(anyIn(76, n + extent, 20, 48), isTrue, reason: 'heart tip');
    });

    test('is deterministic', () {
      final again = HeartFrame();
      var diffs = 0;
      for (var row = -10; row < n + 10; row++) {
        for (var col = -10; col < n + 10; col++) {
          if (frame.isFrameModule(n, q, col, row, radius) != again.isFrameModule(n, q, col, row, radius)) {
            diffs++;
          }
        }
      }
      expect(diffs, 0);
    });

    test('is mirror-symmetric left/right', () {
      var diffs = 0;
      for (var row = -extent; row < n + extent; row++) {
        for (var col = -extent; col < n ~/ 2; col++) {
          final mirror = n - 1 - col;
          if (frame.isFrameModule(n, q, col, row, radius) != frame.isFrameModule(n, q, mirror, row, radius)) {
            diffs++;
          }
        }
      }
      expect(diffs, 0);
    });

    test('larger scaleBoost grows the heart', () {
      final snug = HeartFrame();
      final wide = HeartFrame(scaleBoost: 0.4);
      expect(wide.resolvedRadius(n, q), greaterThan(snug.resolvedRadius(n, q)));
    });
  });
}
