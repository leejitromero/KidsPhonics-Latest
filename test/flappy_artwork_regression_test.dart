import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/widgets/flappy_letters_design.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'bundled airplane is the exact historical illustration with transparency',
      () async {
    final data = await rootBundle.load('assets/images/new_ui/airplane.webp');
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    expect(sha256.convert(bytes).toString(),
        '05d981096028a1b41868a5b5b02d6f2315433adffa694af5224ba94c9dc37b84');
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(image.width, greaterThan(0));
    expect(image.height, greaterThan(0));
    expect([for (var i = 3; i < rgba!.lengthInBytes; i += 4) rgba.getUint8(i)],
        contains(0));
    image.dispose();
    codec.dispose();
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1024)
  ]) {
    testWidgets(
        'shared ready, pause, hit, win and loss panel decodes artwork at $size',
        (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      for (final (title, label) in [
        ('Ready to fly?', 'Start flying'),
        ('Taking a little break', 'Resume'),
        ('Oops! Keep going!', 'Continue'),
        ('A to Z! You did it!', 'Play again'),
        ('Nice flying! Try again!', 'Play again'),
      ]) {
        var activated = false;
        await t.pumpWidget(MaterialApp(
            home: Scaffold(
                body: FlappyFlightPanel(
          title: title,
          detail: '0 of 26 letters cleared',
          buttonLabel: label,
          celebrate: title.startsWith('A to Z'),
          onPressed: () => activated = true,
        ))));
        final art = find.byKey(const ValueKey('flappy-airplane-art'));
        expect(art, findsOneWidget);
        final image = t.widget<Image>(art);
        ImageProvider provider = image.image;
        if (provider is ResizeImage) provider = provider.imageProvider;
        expect((provider as AssetImage).assetName,
            'assets/images/new_ui/airplane.webp');
        expect(image.fit, BoxFit.contain);
        await t.runAsync(() => precacheImage(image.image, t.element(art)));
        final action = find.byKey(const ValueKey('flappy-flight-action'));
        await t.ensureVisible(action);
        await t.pump();
        expect(t.getSize(action).height, greaterThanOrEqualTo(48));
        await t.tap(action);
        expect(activated, isTrue);
        expect(t.takeException(), isNull);
      }
      await t.pumpWidget(const SizedBox());
    });
  }
}
