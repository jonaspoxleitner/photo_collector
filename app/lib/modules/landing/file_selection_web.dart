import 'package:app/modules/landing/file_selection.dart';
import 'package:file_picker/file_picker.dart';

/// Common image/video extensions replacing the `image/*,video/*` MIME
/// wildcard from the previous hand-rolled input: `file_picker` cannot
/// express MIME wildcards, so the picker is restricted to this list.
/// Formats outside of it (uncommon) can no longer be selected; extend
/// here if guests report missing formats.
const _mediaExtensions = [
  // images
  'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tif', 'tiff', 'heic', 'heif', 'avif',
  // videos
  'mp4', 'mov', 'm4v', 'webm', 'mkv', 'avi', '3gp', 'wmv', 'mpg', 'mpeg', 'ts',
];

/// Diagnostics prefix greppable in the browser console. Uses plain
/// `print` (not `debugPrint`) because it must also work in release builds:
/// the deployed app is silent otherwise.
void _log(String message) {
  // ignore: avoid_print -- deliberate: release builds must stay diagnosable.
  print('[photo-collector:pick] $message');
}

/// Opens the browser file picker via the `file_picker` package.
///
/// The package maintains the browser-input plumbing (input element,
/// event listeners, byte buffering) instead of hand-rolled
/// `package:web` code: the previous implementation hung on some mobile
/// browsers (picker opens, selection never returns) due to fragile
/// event/JsInterop handling, which the package handles for us.
///
/// Only compiled for web (see `file_selection.dart`).
Future<List<PickedGuestFile>> selectMediaFiles({SelectionProgress? onProgress}) async {
  _log('opening file picker (file_picker, ${_mediaExtensions.length} media extensions)');
  // file_picker 13: pickFiles is always multiple-selection; a cancelled
  // picker returns an empty list (not null). Bytes are deliberately not
  // preloaded by the package (no withData web option) so buffering can
  // report per-file progress below.
  final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: _mediaExtensions);
  _log('picker closed with ${files.length} file(s)');
  if (files.isEmpty) return const <PickedGuestFile>[];

  // Buffer files one at a time and report per-file completion; large
  // selections take visible time and the landing page must not look
  // frozen.
  final picked = <PickedGuestFile>[];
  for (var i = 0; i < files.length; i++) {
    final file = files[i];
    final bytes = await file.readAsBytes();
    picked.add(PickedGuestFile(name: file.name, sizeBytes: file.lengthSync() ?? bytes.length, bytes: bytes));
    onProgress?.call(i + 1, files.length);
    _log('file ${i + 1}/${files.length} buffered: ${file.name} (${bytes.length} bytes)');
  }
  _log('all ${picked.length} file(s) buffered');
  return picked;
}
