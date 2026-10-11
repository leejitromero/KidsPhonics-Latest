import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Flutter decodes every losslessly optimized image', () async {
    final images = Directory('assets/images')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.webp'))
        .toList();
    expect(images, isNotEmpty);
    for (final file in images) {
      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      try {
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(0), reason: file.path);
        expect(frame.image.height, greaterThan(0), reason: file.path);
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
    }
  });
}
