/// Pure timeout math for browser PUT uploads, kept free of web/JS
/// imports so it is unit-testable on the VM.
///
/// A stalled connection must eventually fail and become retryable instead
/// of hanging the sequential upload queue forever, so the timeout is
/// size-aware: base allowance plus transfer time at a conservative
/// throughput floor, hard-capped so even the single-PUT maximum (2 GB)
/// cannot wait indefinitely.
library;

/// Minimum time any PUT gets, regardless of size.
const uploadTimeoutBase = Duration(minutes: 2);

/// Hard ceiling; even the largest allowed payload must fail eventually.
const uploadTimeoutMax = Duration(minutes: 45);

/// Assumed worst-case throughput the timeout tolerates: 1 Mbit/s, at the
/// low end of a usable event-network connection. Slower-but-alive uploads
/// are indistinguishable from stalls and will eventually fail, which is
/// the intended trade-off.
const _floorBytesPerSecond = 1024 * 1024 ~/ 8;

/// Timeout for a body of [bodyBytes].
Duration uploadTimeoutFor(int bodyBytes) {
  final transferSeconds = bodyBytes ~/ _floorBytesPerSecond;
  final total = uploadTimeoutBase + Duration(seconds: transferSeconds);
  return total > uploadTimeoutMax ? uploadTimeoutMax : total;
}
