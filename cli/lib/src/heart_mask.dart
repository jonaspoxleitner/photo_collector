/// Heart-shaped silhouette mask for QR modules, based on the implicit heart
/// curve `(x² + y² − 1)³ − x²y³ < 0` evaluated over the module grid.
///
/// Modules whose center falls inside the curve are clipped from the output.
/// Finder patterns and separators are never clipped (see [isFinderRegion]),
/// and error correction level H recovers the removed modules.
class HeartMask {
  /// Creates a mask.
  ///
  /// [scale] is the fraction of the QR matrix width the heart silhouette
  /// spans (0 < scale <= 1). Real-device scan testing showed large
  /// silhouettes defeating phone cameras despite error correction H, so the
  /// CLI uses a scan-tested 0.3, and frame mode (see HeartFrame) is the
  /// recommended default because it never modifies the QR code at all.
  ///
  /// [padding] is an extra safety margin around the heart, in modules,
  /// dilating the clipped region (default 0.8).
  const HeartMask({this.scale = 0.62, this.padding = 0.8})
    : assert(scale > 0 && scale <= 1, 'scale must be in (0, 1]'),
      assert(padding >= 0, 'padding must be >= 0');

  /// Fraction of the QR matrix width covered by the heart silhouette.
  final double scale;

  /// Extra clipped margin around the heart, in modules.
  final double padding;

  /// Bounding-box extent of the heart curve (width ≈ 2.33, height ≈ 2.26
  /// curve units) with headroom.
  static const double _unitExtent = 2.4;

  /// Vertical center of the heart bounding box in curve units; the curve
  /// spans y ∈ [−1, ~1.26], so its box center is ≈ 0.13. This offset keeps
  /// the silhouette visually centered on the QR matrix. Public because
  /// `HeartFrame` reuses the same convention.
  static const double verticalCenterOffset = 0.13;

  /// Evaluates the implicit heart curve at curve coordinates ([x], [y]).
  /// Points with a result < 0 are inside the heart.
  static double heartCurveValue(double x, double y) {
    final xx = x * x;
    final yy = y * y;
    final a = xx + yy - 1;
    return a * a * a - xx * y * yy; // (x² + y² − 1)³ − x²y³
  }

  /// Returns the finder pattern and separator protection zones: an 8x8
  /// module square (7x7 finder pattern plus 1-module separator) in the
  /// top-left, top-right, and bottom-left corners of the matrix. These
  /// modules always render intact regardless of the mask configuration.
  static bool isFinderRegion(int moduleCount, int col, int row) {
    const k = 8; // 7-module finder pattern + 1-module separator
    final left = col < k;
    final right = col >= moduleCount - k;
    final top = row < k;
    final bottom = row >= moduleCount - k;
    return (top && left) || (top && right) || (bottom && left);
  }

  /// Returns whether the module at ([col], [row]) in a QR matrix of
  /// [moduleCount] x [moduleCount] lies inside the heart silhouette.
  bool isInside(int moduleCount, int col, int row) {
    // One curve unit, in modules. Larger scale and padding dilate the heart.
    final r = (scale * moduleCount) / _unitExtent + padding;
    final center = moduleCount / 2;
    final hx = (col + 0.5 - center) / r;
    final hy = (center - (row + 0.5)) / r + verticalCenterOffset;
    return heartCurveValue(hx, hy) < 0;
  }
}
