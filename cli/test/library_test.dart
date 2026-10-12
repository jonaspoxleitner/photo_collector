import 'package:cli/cli.dart';
import 'package:test/test.dart';

void main() {
  test('library exports the CLI API', () {
    // Smoke test: core entry points exist and the defaults are sane.
    const mask = HeartMask();
    expect(mask.scale, greaterThan(0));
    expect(mask.padding, greaterThanOrEqualTo(0));
    expect(ExitCodes.ok, 0);
    expect(() => mintEventToken(accessKeyId: 'k', secretKey: 's', bucket: 'b', region: 'r'), returnsNormally);
  });
}
