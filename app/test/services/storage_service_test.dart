import 'package:app/services/storage/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorageService extends StorageService {
  @override
  Future<void> uploadObject({
    required String objectKey,
    required List<int> data,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async {}
}

void main() {
  group('StorageService.instance', () {
    test('can be replaced in tests', () {
      final fake = _FakeStorageService();
      StorageService.instance = fake;
      expect(StorageService.instance, same(fake));
    });
  });
}
