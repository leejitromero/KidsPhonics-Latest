import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

Future<
    ({
      String pixels,
      Uint8List rgba,
      int width,
      int height,
      int microseconds
    })> _decode(String path) async {
  final bytes = await File(path).readAsBytes();
  final clock = Stopwatch()..start();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  clock.stop();
  try {
    expect(codec.frameCount, 1, reason: path);
    final data =
        await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return (
      pixels:
          sha256.convert(data!.buffer.asUint8List()).toString().toUpperCase(),
      rgba: data.buffer.asUint8List(),
      width: frame.image.width,
      height: frame.image.height,
      microseconds: clock.elapsedMicroseconds
    );
  } finally {
    frame.image.dispose();
    codec.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const staged = bool.fromEnvironment('VERIFY_STAGED_IMAGES');
  test(
      'release images preserve canvas, alpha and colors with bounded codec rounding',
      () async {
    final report = jsonDecode(File(staged
            ? 'build/release_image_optimization/manifest.json'
            : 'tools/release_image_optimization.json')
        .readAsStringSync()) as Map;
    final verified = <Map<String, Object>>[];
    var beforeTime = 0, afterTime = 0;
    for (final row in report['images'] as List) {
      final target = staged
          ? 'build/release_image_optimization/${row['optimized']}'
          : row['optimized'] as String;
      expect(
          sha256
              .convert(await File(target).readAsBytes())
              .toString()
              .toUpperCase(),
          row['optimizedSHA256'],
          reason: target);
      final current = await _decode(target);
      afterTime += current.microseconds;
      expect((current.width, current.height), (row['width'], row['height']),
          reason: target);
      if (staged) {
        final original = await _decode(row['original']);
        beforeTime += original.microseconds;
        var differingBytes = 0,
            maxDelta = 0,
            opaqueDifferences = 0,
            alphaDifferences = 0;
        for (var i = 0; i < current.rgba.length; i++) {
          final delta = (current.rgba[i] - original.rgba[i]).abs();
          if (delta == 0) continue;
          differingBytes++;
          if (delta > maxDelta) maxDelta = delta;
          if (i % 4 == 3) alphaDifferences++;
          if (original.rgba[(i ~/ 4) * 4 + 3] == 255) opaqueDifferences++;
        }
        verified.add({
          'original': row['original'],
          'optimized': row['optimized'],
          'flutterRGBA_SHA256': current.pixels,
          'pixelsIdentical': current.pixels == original.pixels,
          'differingBytes': differingBytes,
          'maxDelta': maxDelta,
          'opaqueDifferences': opaqueDifferences,
          'alphaDifferences': alphaDifferences,
          'originalDecodeMicroseconds': original.microseconds,
          'optimizedDecodeMicroseconds': current.microseconds
        });
      } else {
        expect(current.pixels, row['flutterRGBA_SHA256'], reason: target);
        expect(File(row['original']).existsSync(), false,
            reason:
                'The APK must contain one active encoding, not duplicate PNGs.');
      }
    }
    expect(report['images'], hasLength(report['count']));
    if (staged) {
      File('build/release_image_optimization/flutter_verification.json')
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
        'allPixelsIdentical':
            verified.every((row) => row['pixelsIdentical'] == true),
        'allFlutterCompatible': verified.every((row) =>
            (row['maxDelta'] as int) <= 1 &&
            row['opaqueDifferences'] == 0 &&
            row['alphaDifferences'] == 0),
        'count': verified.length,
        'originalDecodeMicroseconds': beforeTime,
        'optimizedDecodeMicroseconds': afterTime,
        'images': verified
      }));
      // Flutter's PNG and WebP decoders round premultiplied transparent RGB
      // differently. Stored straight RGBA is verified byte-for-byte separately.
      // Permit at most 1/255 on translucent RGB only, never alpha or opaque RGB.
      for (final row in verified) {
        expect(row['maxDelta'], lessThanOrEqualTo(1),
            reason: row['original'] as String);
        expect(row['opaqueDifferences'], 0, reason: row['original'] as String);
        expect(row['alphaDifferences'], 0, reason: row['original'] as String);
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
