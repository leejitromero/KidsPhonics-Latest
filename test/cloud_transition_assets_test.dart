import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/widgets/cloud_page_route.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  test('supplied cloud frames are bundled, transparent and close in order',
      () async {
    expect(cloudTransitionAssets, hasLength(4));
    var previousCoverage = 0;
    for (final asset in cloudTransitionAssets) {
      final bytes = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 941);
      expect(frame.image.height, 1672);
      final rgba =
          await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      var transparent = 0;
      var visible = 0;
      for (var i = 3; i < rgba!.lengthInBytes; i += 4) {
        if (rgba.getUint8(i) == 0) transparent++;
        if (rgba.getUint8(i) > 0) visible++;
      }
      expect(transparent, greaterThan(0), reason: asset);
      expect(visible, greaterThan(previousCoverage),
          reason: 'Clouds must close in frame order');
      previousCoverage = visible;
      frame.image.dispose();
      codec.dispose();
    }
  });

  for (final destination in ['lessons', 'games', 'progress', 'parents']) {
    testWidgets('Home $destination uses the actual cloud frames and returns',
        (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({'sfx': false, 'voice': false});
      mockProgressAudio();
      final p = await mount(t, const HomeScreen());
      final app = t.widget<MaterialApp>(find.byType(MaterialApp));
      final boundary = GlobalKey();
      await t.pumpWidget(ChangeNotifierProvider.value(
          value: p, child: RepaintBoundary(key: boundary, child: app)));
      await t.pump();
      Future<void> preloadVisible() => t.runAsync(() async {
            await Future.wait(t.widgetList<Image>(find.byType(Image)).map(
                (image) =>
                    precacheImage(image.image, boundary.currentContext!)));
          });
      final capture =
          const bool.fromEnvironment('CAPTURE_UI') && destination == 'lessons';
      if (capture) {
        await t.runAsync(() async {
          await (FontLoader('Nunito')
                ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
                ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
                ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
                ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
              .load();
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
        await preloadVisible();
      }
      await t.ensureVisible(find.byKey(ValueKey('home-$destination')));
      final repeatedTap =
          t.widget<InkWell>(find.byKey(ValueKey('home-$destination'))).onTap!;
      await t.tap(find.byKey(ValueKey('home-$destination')));
      repeatedTap();
      for (var i = 0;
          i < 100 && find.byType(CloudScreenTransition).evaluate().isEmpty;
          i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await t.pump();
      }
      expect(find.byType(CloudScreenTransition), findsOneWidget);
      final transition =
          t.widget<CloudScreenTransition>(find.byType(CloudScreenTransition));
      expect(transition.frames, hasLength(4));
      final route =
          ModalRoute.of(t.element(find.byType(CloudScreenTransition)))!;
      expect(route, isA<CloudPageRoute<void>>());
      if (capture) await preloadVisible();
      var elapsed = 0;
      for (final ms in [120, 280, 400, 600, 800]) {
        await t.pump(Duration(milliseconds: ms - elapsed));
        elapsed = ms;
        expect(t.takeException(), isNull);
        if (capture) {
          await t.runAsync(() async {
            final image = await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File('build/ui_previews/cloud_transition/$ms.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      expect(find.byKey(const ValueKey('cloud-transition')), findsNothing);
      final context = t.element(find.byType(CloudScreenTransition));
      expect(ModalRoute.isCurrentOf(context), isTrue);
      Navigator.of(context).pop();
      await t.pump();
      await t.pump(const Duration(milliseconds: 850));
      expect(find.byType(CloudScreenTransition), findsNothing);
      expect(find.byKey(ValueKey('home-$destination')), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }
}
