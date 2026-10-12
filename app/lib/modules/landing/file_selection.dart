import 'package:app/modules/landing/file_selection_stub.dart'
    if (dart.library.js_interop) 'package:app/modules/landing/file_selection_web.dart'
    as impl;

/// A file chosen by the guest, already buffered in browser memory.
///
/// The selection contract is images and videos only, multiple selection,
/// and never a restrictive `capture` attribute (guests must be able to
/// pick existing photos and videos); enforced in `file_selection_web.dart`.
///
/// The web platform buffers picked files in memory anyway, so keeping the
/// bytes here keeps the Phase 3 storage contract (`List<int> data`) simple.
class PickedGuestFile {
  const PickedGuestFile({required this.name, required this.sizeBytes, required this.bytes});

  /// Original file name as reported by the browser (display only; object
  /// key generation re-sanitizes it).
  final String name;

  /// File size in bytes as reported by the browser.
  final int sizeBytes;

  final List<int> bytes;
}

/// Reports buffering progress after the guest picked files: [filesRead]
/// of [totalFiles] have been fully read into memory. Reading large
/// selections byte-by-byte into memory takes visible time; without this
/// callback the wait is silent and looks like a frozen app.
typedef SelectionProgress = void Function(int filesRead, int totalFiles);

/// Opens a native file selection dialog and returns the picked files,
/// or an empty list when the guest cancels. [onProgress], when provided,
/// is invoked as each picked file finishes buffering.
typedef FileSelector = Future<List<PickedGuestFile>> Function({SelectionProgress? onProgress});

/// Opens the browser file picker.
///
/// Resolves to the `file_picker` package implementation on web builds
/// and to a no-DOM stub in VM/test environments, where it returns an
/// empty selection instead of crashing.
Future<List<PickedGuestFile>> selectMediaFilesFromBrowser({SelectionProgress? onProgress}) =>
    impl.selectMediaFiles(onProgress: onProgress);
