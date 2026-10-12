import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web shell uses the scaffold background for the iOS/Safari tint', () {
    final indexHtml = File('web/index.html').readAsStringSync();
    final manifest = jsonDecode(File('web/manifest.json').readAsStringSync()) as Map<String, Object?>;

    expect(indexHtml, contains('<meta name="theme-color" content="#FFF8F8">'));
    expect(indexHtml, contains('background-color: #FFF8F8'));
    expect(manifest['background_color'], '#FFF8F8');
    expect(manifest['theme_color'], '#FFF8F8');
  });
}
