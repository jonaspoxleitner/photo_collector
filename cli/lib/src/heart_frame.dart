import 'package:cli/src/heart_mask.dart';

/// Heart-shaped decorative frame of pseudo-random "fake" modules drawn
/// *around* the QR matrix, shaped by the same implicit curve as [HeartMask]
/// (`(x² + y² − 1)³ − x²y³ < 0`).
///
/// Unlike [HeartMask], the frame never touches the QR matrix or its quiet
/// zone: the code stays fully intact, so frame mode is scannability-safe at
/// any size. The heart is auto-sized to enclose the quiet-zone square;
/// [scaleBoost] dilates it further.
class HeartFrame {
  /// Creates a frame.
  ///
  /// [gapModules] is the white gap between the QR quiet zone and the first
  /// frame module, in modules (default 2).
  ///
  /// [scaleBoost] dilates the heart beyond the minimal enclosing size, as a
  /// fraction of the minimal radius (0 < boost <= 1; default 0.15).
  ///
  /// [verticalShift] moves the heart outline down relative to the QR code
  /// (in curve units), so the code sits higher inside the heart — the
  /// visual center of a heart is its wide upper lobe region, not its
  /// bounding-box center. Default 0.1; 0 bbox-centers the code.
  ///
  /// [seed] drives the deterministic fake-module pattern.
  const HeartFrame({this.gapModules = 2, this.scaleBoost = 0.15, this.verticalShift = 0.1, this.seed = 0x9e3779b9})
    : assert(gapModules >= 0, 'gapModules must be >= 0'),
      assert(scaleBoost > 0 && scaleBoost <= 1, 'scaleBoost must be in (0, 1]'),
      assert(verticalShift >= 0, 'verticalShift must be >= 0');

  /// White gap between the QR quiet zone and the frame, in modules.
  final int gapModules;

  /// Extra heart dilation beyond the minimal enclosing radius.
  final double scaleBoost;

  /// Downward shift of the heart relative to the QR code, in curve units.
  final double verticalShift;

  /// Seed for the deterministic fake-module pattern.
  final int seed;

  /// Maximum distance from the heart center that any interior point can
  /// reach, in curve units (curve extends to about |x|,|y| <= 1.13).
  static const double _curveHalfExtent = 1.16;

  /// Curve radius in modules: the smallest radius for which the quiet-zone
  /// square's edges lie strictly inside the heart interior, times
  /// `1 + scaleBoost`. The square's corners may lie outside the silhouette —
  /// they stay white regardless, because protection is geometric and does not
  /// depend on the heart. This keeps the QR code proportionally large.
  double resolvedRadius(int moduleCount, int quietZoneModules) {
    final halfSide = moduleCount / 2 + quietZoneModules + gapModules;
    var r = halfSide / 1.1;
    while (!_fitsEdges(halfSide, r)) {
      r *= 1.05;
    }
    return r * (1 + scaleBoost);
  }

  /// Maximum module distance from the matrix center that can contain frame
  /// modules (i.e. how far the heart reaches, in modules).
  int extent(int moduleCount, int quietZoneModules, double radius) => (_curveHalfExtent * radius).ceil() + 1;

  /// Bounding box in matrix coordinates of all drawn frame modules, as
  /// (minRow, maxRowExclusive, minCol, maxColExclusive). Used to frame the
  /// card content with even margins regardless of the heart's asymmetry.
  (int, int, int, int) drawnBounds(int moduleCount, int quietZoneModules, double radius) {
    final ext = extent(moduleCount, quietZoneModules, radius);
    final lo = moduleCount ~/ 2 - ext;
    final hi = (moduleCount + 1) ~/ 2 + ext;
    var minRow = hi, maxRow = lo, minCol = hi, maxCol = lo;
    for (var row = lo; row < hi; row++) {
      for (var col = lo; col < hi; col++) {
        if (isFrameModule(moduleCount, quietZoneModules, col, row, radius)) {
          if (row < minRow) minRow = row;
          if (row + 1 > maxRow) maxRow = row + 1;
          if (col < minCol) minCol = col;
          if (col + 1 > maxCol) maxCol = col + 1;
        }
      }
    }
    return maxRow >= minRow ? (minRow, maxRow, minCol, maxCol) : (0, 0, 0, 0);
  }

  /// Whether a decorative module is drawn at matrix coordinate ([col], [row]).
  /// Coordinates may be negative or >= moduleCount. The QR matrix, its quiet
  /// zone (ISO 4 modules), and [gapModules] additional white modules are
  /// always left untouched. [radius] comes from [resolvedRadius].
  bool isFrameModule(int moduleCount, int quietZoneModules, int col, int row, double radius) {
    final center = moduleCount / 2;
    final dx = col + 0.5 - center;
    final dy = row + 0.5 - center;
    final halfSide = moduleCount / 2 + quietZoneModules + gapModules;
    // Modules whose center lies exactly on the square boundary are kept
    // white too: they would otherwise intrude half a module into the gap.
    if (dx.abs() <= halfSide && dy.abs() <= halfSide) return false;
    if (!_isInsideHeart(dx, dy, radius, margin: 0.0)) return false;
    return _pseudoRandom(dx, dy);
  }

  bool _isInsideHeart(double dx, double dy, double r, {double margin = 0.0}) =>
      HeartMask.heartCurveValue(dx / r, -dy / r + HeartMask.verticalCenterOffset + verticalShift) < margin;

  /// The edge mid-regions of the quiet-zone square (not the corner tails)
  /// must lie strictly inside the heart (margin < 0) so the white ring
  /// around the QR reads continuously where the heart wraps the square.
  bool _fitsEdges(double halfSide, double r) {
    const samples = 64;
    const cornerTail = 0.45; // outer 45% of each edge may exit the heart
    final reach = halfSide * (1 - cornerTail);
    for (var i = 0; i <= samples; i++) {
      final t = -reach + (2 * reach * i) / samples;
      if (!_isInsideHeart(t, -halfSide, r, margin: -0.02) ||
          !_isInsideHeart(t, halfSide, r, margin: -0.02) ||
          !_isInsideHeart(-halfSide, t, r, margin: -0.02) ||
          !_isInsideHeart(halfSide, t, r, margin: -0.02)) {
        return false;
      }
    }
    return true;
  }

  /// Deterministic, mirror-symmetric (left/right) noise so the decoration
  /// reads as one coherent QR-like texture.
  bool _pseudoRandom(double dx, double dy) {
    final ax = (dx.abs() * 2).round();
    final ay = (dy * 2).round();
    var h = (ax * 0x85ebca6b) ^ (ay * 0xc2b2ae35) ^ seed;
    h = (h ^ (h >> 13)) * 0x27d4eb2d;
    h = h ^ (h >> 15);
    return (h & 1) == 0;
  }
}
