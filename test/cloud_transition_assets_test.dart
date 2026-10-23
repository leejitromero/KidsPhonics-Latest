import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'package:kidsphonics/screens/parent_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/cloud_page_route.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final (family, path) in [
      ('Fredoka', 'assets/fonts/Fredoka-Regular.ttf'),
      ('Nunito', 'assets/fonts/Nunito-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(path))).load();
    }
  });

  test('supplied curtain frames are unchanged, bundled and close in order',
      () async {
    expect(cloudTransitionAssets, hasLength(5));
    const hashes = [
      '7a962f8f46e1caf7bc52bf7b8d4a92da2d00e304d160b9c5b52dcebeeb05b0b4',
      '2d39ed6e87961f8ac7c4a303ced29d1318ef4aa076d9ad5bcbd529d89316df9a',
      '4bdf9c250be17ad4ebdea67dd6a290f2c0ba452f6bf7c61ca27c7a0e2e4258af',
      '869aac4165b6973d5b05daf1fb2b270e0f61bfc5c76225963f76dbf6a8396694',
      'b431ee6477e940cb0c9f101f47e5feded0c84d8d50854255c78062046ad19ce9',
    ];
    var previousCoverage = 0;
    for (var index = 0; index < cloudTransitionAssets.length; index++) {
      final asset = cloudTransitionAssets[index];
      expect(asset, endsWith('curtain_${index + 1}.png'));
      final bytes = await rootBundle.load(asset);
      expect(
          sha256.convert(bytes.buffer.asUint8List()).toString(), hashes[index]);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 1024);
      expect(frame.image.height, 1536);
      final rgba =
          await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      var transparent = 0;
      var visible = 0;
      for (var i = 3; i < rgba!.lengthInBytes; i += 4) {
        if (rgba.getUint8(i) == 0) transparent++;
        if (rgba.getUint8(i) > 0) visible++;
      }
      expect(transparent, index == 4 ? 0 : greaterThan(0), reason: asset);
      expect(visible, greaterThan(previousCoverage),
          reason: 'Curtains must close in the supplied frame order');
      previousCoverage = visible;
      frame.image.dispose();
      codec.dispose();
    }
  });

  for (final destination in ['lessons', 'games', 'progress', 'parents']) {
    testWidgets(
        'Curtain navigation to $destination uses actual frames and returns',
        (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({'sfx': false, 'voice': false});
      mockProgressAudio();
      // School Home now uses the student's classroom-entry animation. Exercise
      // the shared cloud route directly; other lesson flows still use it.
      final p = await mount(
          t,
          Builder(
              builder: (context) => Scaffold(
                      body: Center(
                          child: Material(
                              child: InkWell(
                    key: ValueKey('home-$destination'),
                    onTap: () => LearnerNavigation.open(
                        context,
                        switch (destination) {
                          'lessons' => const LessonsScreen(),
                          'games' => const GamesScreen(),
                          'progress' => const ProgressScreen(),
                          _ => const ParentScreen(),
                        },
                        cloudTransition: true),
                    child: const SizedBox(
                        width: 150, height: 80, child: Text('Open')),
                  ))))));
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
      expect(transition.frames, hasLength(5));
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
            final file = File('build/ui_previews/curtain_transition/$ms.png');
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
