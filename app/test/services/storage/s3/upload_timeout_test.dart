import 'package:app/services/storage/s3/upload_timeout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('uploadTimeoutFor', () {
    test('small payloads get (close to) the base timeout', () {
      expect(uploadTimeoutFor(0), uploadTimeoutBase);
      // 1 MiB at 1 Mbit/s adds 8 s to the 2-minute base.
      expect(uploadTimeoutFor(1024 * 1024), uploadTimeoutBase + const Duration(seconds: 8));
    });

    test('large payloads extend the timeout at the throughput floor', () {
      // 256 MiB at 1 Mbit/s ≈ 2048 s extra, comfortably under the cap so
      // a slow but alive upload is not killed.
      expect(uploadTimeoutFor(256 * 1024 * 1024), uploadTimeoutBase + const Duration(seconds: 2048));
    });

    test('the timeout is capped for very large payloads', () {
      expect(uploadTimeoutFor(2 * 1024 * 1024 * 1024), uploadTimeoutMax);
    });
  });
}
