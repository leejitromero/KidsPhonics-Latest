import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/widgets/day_cycle_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final frames = DayCycleBackground.framesFor('home');

  test('home uses the three unmodified supplied images in day order', () {
    const hashes = [
      '07ea266057db487a6a45890335e69b1b0b90dd5bc2081d78add71df3aa5ff0d1',
      '6da868d628bfc6f47160d41f891929ab5e28a3f4c454155d4c7cab1790b7831f',
      'c10e614dae6f4b5fdebe3d3a38fe812fec5a0ca5168ab9d76b66da1fba8abc77',
    ];
    for (var i = 0; i < frames.length; i++) {
      final bytes = File(frames[i]).readAsBytesSync();
      expect(sha256.convert(bytes).toString(), hashes[i]);
      final header = ByteData.sublistView(bytes);
      expect(header.getUint32(16), 1024);
      expect(header.getUint32(20), 1536);
    }
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024),
    const Size(1024, 1366),
    const Size(1024, 768),
  ]) {
    testWidgets('centered cover fills $size through the entire fade cycle',
        (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(const MaterialApp(
          home: Scaffold(body: DayCycleBackground(category: 'home'))));
      final context = t.element(find.byType(DayCycleBackground));
      final decodeWidth = size.width.ceil().clamp(1, 942);
      await t.runAsync(() => Future.wait(frames.map((asset) => precacheImage(
          ResizeImage(AssetImage(asset), width: decodeWidth), context))));
      await t.pump();
      await t.pump();

      void checkImages(List<String> expectedFrames) {
        final images = find.byType(Image);
        expect(images, findsNWidgets(expectedFrames.length));
        final names = <String>[];
        for (final element in images.evaluate()) {
          final image = element.widget as Image;
          names.add(((image.image as ResizeImage).imageProvider as AssetImage)
              .assetName);
          expect(image.fit, BoxFit.cover);
          expect(image.alignment, Alignment.center);
          final finder = find.byWidget(image);
          expect(t.getRect(finder), Offset.zero & size);
          final render = t.renderObject<RenderImage>(
              find.descendant(of: finder, matching: find.byType(RawImage)));
          expect(render.image, isNotNull);
          // Confirm that the actual decoded image covers the viewport while
          // retaining a single scale factor and a centered source crop.
          final source = Size(
              render.image!.width.toDouble(), render.image!.height.toDouble());
          final fitted = applyBoxFit(render.fit!, source, render.size);
          expect(fitted.destination, size);
          expect(fitted.source.width / fitted.source.height,
              closeTo(size.aspectRatio, .000001));
          final crop = render.alignment
              .resolve(TextDirection.ltr)
              .inscribe(fitted.source, Offset.zero & source);
          expect(crop.center.dx, closeTo(source.width / 2, .000001));
          expect(crop.center.dy, closeTo(source.height / 2, .000001));
        }
        expect(names, expectedFrames);
        expect(t.takeException(), isNull);
      }

      checkImages([frames[0]]);
      await t.pump(const Duration(milliseconds: 4349));
      checkImages([frames[0]]);
      await t.pump(const Duration(milliseconds: 326));
      checkImages([frames[0], frames[1]]);
      final fade = t.widget<Opacity>(find.byType(Opacity));
      expect(fade.opacity, closeTo(.5, .000001));
      await t.pump(const Duration(milliseconds: 325));
      checkImages([frames[1]]);
      await t.pump(const Duration(seconds: 5));
      checkImages([frames[2]]);
      await t.pump(const Duration(milliseconds: 4675));
      checkImages([frames[2], frames[0]]);
      await t.pump(const Duration(milliseconds: 325));
      checkImages([frames[0]]);
      await t.pumpWidget(const SizedBox());
    });
  }
}
