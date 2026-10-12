import 'package:app/util/name_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeGuestName', () {
    test('lowercases, trims, and joins words with dashes', () {
      expect(sanitizeGuestName('  Jonas  Poxleitner '), 'jonas-poxleitner');
      expect(sanitizeGuestName('ANNA'), 'anna');
    });

    test('collapses any run of whitespace into a single dash', () {
      expect(sanitizeGuestName('Max   Maria\tMustermann\nJunior'), 'max-maria-mustermann-junior');
    });

    test('transliterates German umlauts and eszett', () {
      expect(sanitizeGuestName('Müller'), 'mueller');
      expect(sanitizeGuestName('Björn Kästner'), 'bjoern-kaestner');
      expect(sanitizeGuestName('Weiß'), 'weiss');
    });

    test('strips unsupported characters and repeated dashes', () {
      expect(sanitizeGuestName('Anna!!! ???'), 'anna');
      expect(sanitizeGuestName('a--b__c'), 'a-b-c');
      expect(sanitizeGuestName("O'Brien-Smith"), 'o-brien-smith');
    });

    test('never produces leading, trailing, or separator characters', () {
      expect(sanitizeGuestName('--../\\x--'), 'x');
      expect(sanitizeGuestName('-jonas-'), 'jonas');
    });

    test('limits the length', () {
      final long = sanitizeGuestName('a' * 200);
      expect(long.length, lessThanOrEqualTo(maxGuestNameLength));
      expect(long.endsWith('-'), isFalse);
    });

    test('falls back to anonymous for empty or unusable input', () {
      expect(sanitizeGuestName(null), anonymousGuestName);
      expect(sanitizeGuestName(''), anonymousGuestName);
      expect(sanitizeGuestName('   '), anonymousGuestName);
      expect(sanitizeGuestName('!@#\$%^&*()'), anonymousGuestName);
      expect(sanitizeGuestName('📸🎉'), anonymousGuestName);
    });
  });

  group('sanitizeOriginalFileName', () {
    test('keeps ordinary file names intact', () {
      expect(sanitizeOriginalFileName('IMG_0001.JPG'), 'IMG_0001.JPG');
      expect(sanitizeOriginalFileName('party-video.mp4'), 'party-video.mp4');
    });

    test('removes path components and traversal', () {
      expect(sanitizeOriginalFileName('../../etc/passwd'), 'passwd');
      expect(sanitizeOriginalFileName(r'C:\Users\evil\x.png'), 'x.png');
      expect(sanitizeOriginalFileName('/absolute/path/photo.jpg'), 'photo.jpg');
    });

    test('never contains separators or duplicate separators', () {
      final name = sanitizeOriginalFileName(r'a/b\c/d/../e  f.png');
      expect(name.contains('/'), isFalse);
      expect(name.contains(r'\'), isFalse);
      expect(name.contains('..'), isFalse);
    });

    test('replaces whitespace and unsupported characters', () {
      expect(sanitizeOriginalFileName('my photo (1).jpg'), 'my-photo-1-.jpg');
    });

    test('limits length while keeping the extension', () {
      final name = sanitizeOriginalFileName('${'a' * 200}.jpeg');
      expect(name.length, lessThanOrEqualTo(maxFileNameLength + '.jpeg'.length));
      expect(name.endsWith('.jpeg'), isTrue);
    });

    test('falls back to file for empty input', () {
      expect(sanitizeOriginalFileName(null), 'file');
      expect(sanitizeOriginalFileName(''), 'file');
      expect(sanitizeOriginalFileName('...'), 'file');
    });
  });
}
