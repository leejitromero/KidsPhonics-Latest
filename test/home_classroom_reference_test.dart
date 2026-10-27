import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'package:kidsphonics/screens/parent_screen.dart';
import 'package:kidsphonics/widgets/day_cycle_background.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'updated_scene_test.dart' show loadArt, capture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({'voice': false});
  });

  test('launcher and Games lock have transparent backgrounds, not black plates',
      () async {
    for (final path in [
      'assets/images/app_icon.png',
      'assets/images/games_locl.png',
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
    ]) {
      final codec =
          await ui.instantiateImageCodec(File(path).readAsBytesSync());
      final frame = await codec.getNextFrame();
      try {
        final image = frame.image;
        final pixels =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        int alpha(int x, int y) =>
            pixels.getUint8((y * image.width + x) * 4 + 3);
        for (final (x, y) in [
          (0, 0),
          (image.width - 1, 0),
          (0, image.height - 1),
          (image.width - 1, image.height - 1),
        ]) {
          expect(alpha(x, y), 0,
              reason: '$path must not have opaque corner plates.');
        }
        expect(alpha(image.width ~/ 2, image.height ~/ 2), greaterThan(240),
            reason: 'Keep the actual illustration visible.');
        if (path.endsWith('games_locl.png')) {
          expect(alpha(image.width ~/ 2, image.height ~/ 4), 0,
              reason: 'The classroom should show through the shackle opening.');
        }
      } finally {
        frame.image.dispose();
        codec.dispose();
      }
    }
    expect(
        File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
            .readAsStringSync(),
        contains('android:inset="16%"'),
        reason:
            'The artwork should fill the launcher mask without the old wide cyan frame.');
  });

  test(
      'current runtime Home artwork stays byte-identical at its approved dimensions',
      () {
    const hashes = {
      'new_bgmornig':
          '07ea266057db487a6a45890335e69b1b0b90dd5bc2081d78add71df3aa5ff0d1',
      'new_bg_sunset':
          '6da868d628bfc6f47160d41f891929ab5e28a3f4c454155d4c7cab1790b7831f',
      'new_bg_night':
          'c10e614dae6f4b5fdebe3d3a38fe812fec5a0ca5168ab9d76b66da1fba8abc77',
    };
    for (final entry in hashes.entries) {
      final source = File('assets/images/home_classroom/${entry.key}.png');
      expect(sha256.convert(source.readAsBytesSync()).toString(), entry.value);
      final header = ByteData.sublistView(source.readAsBytesSync());
      expect(header.getUint32(16), 1024);
      expect(header.getUint32(20), 1536);
    }
    expect(DayCycleBackground.framesFor('home'), [
      for (final name in hashes.keys) 'assets/images/home_classroom/$name.png'
    ]);
  });

  for (final (id, destination) in [
    ('progress', ProgressScreen),
    ('parents', ParentScreen),
  ]) {
    testWidgets('$id remains reachable from bottom navigation', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final p = await mount(t, const HomeScreen());
      expect(find.byKey(ValueKey('home-$id')), findsNothing);
      await t.tap(find.byKey(ValueKey('main-nav-$id')));
      await t.pumpAndSettle();
      expect(find.byType(destination), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('main-nav-home')));
      await t.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets(
      'home artwork stays stationary through fades and lifecycle pauses',
      (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final p =
        await mount(t, RepaintBoundary(key: key, child: const HomeScreen()));
    await loadArt(t);
    final context = t.element(find.byType(DayCycleBackground));
    final frames = DayCycleBackground.framesFor('home');
    await t.runAsync(() => Future.wait(frames.map((asset) =>
        precacheImage(ResizeImage(AssetImage(asset), width: 942), context))));
    await t.pump();
    await t.pump();
    List<String> paintedFrames() => t
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<ResizeImage>()
        .map((image) => image.imageProvider)
        .whereType<AssetImage>()
        .map((image) => image.assetName)
        .where(frames.contains)
        .toList();
    expect(paintedFrames(), [frames[0]]);
    final originalArtwork = find.byKey(const ValueKey('home-lessons-art'));
    final artworkRect = t.getRect(originalArtwork);
    expect(originalArtwork, findsOneWidget);
    await capture(t, key, 'classroom_home_morning');
    await t.pump(const Duration(milliseconds: 4675));
    expect(paintedFrames(), [frames[0], frames[1]]);
    final blends = t
        .widgetList<Opacity>(find.byType(Opacity))
        .where((w) => w.child is Image && w.opacity > 0 && w.opacity < 1)
        .toList();
    expect(blends, hasLength(1));
    expect(blends.single.opacity, closeTo(.5, .0001));
    expect(t.getRect(originalArtwork), artworkRect);
    await t.pump(const Duration(milliseconds: 325));
    expect(paintedFrames(), [frames[1]]);
    await capture(t, key, 'classroom_home_sunset');
    await t.pump(const Duration(seconds: 5));
    expect(paintedFrames(), [frames[2]]);
    await capture(t, key, 'classroom_home_night');
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(seconds: 8));
    expect(paintedFrames(), [frames[2]]);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await t.pump(const Duration(seconds: 5));
    expect(paintedFrames(), [frames[0]]);
    expect(t.getRect(originalArtwork), artworkRect);
    expect(find.byType(ClipPath), findsNothing);
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024)
  ]) {
    testWidgets(
        'locked Games uses the supplied image and blocks access at $size',
        (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      SharedPreferences.setMockInitialValues(
          {'voice': false, 'gameAccess': false});
      final p = await mount(t, const HomeScreen());
      expect(t.widget<InkWell>(find.byKey(const ValueKey('home-games'))).onTap,
          isNull);
      expect(
          t
              .widget<GestureDetector>(
                  find.byKey(const ValueKey('home-games-mascot')))
              .onTap,
          isNull);
      final lock = find.byKey(const ValueKey('home-games-lock-art'));
      final image = t.widget<Image>(lock);
      expect(
          ((image.image as ResizeImage).imageProvider as AssetImage).assetName,
          'assets/images/games_locl.png');
      expect(image.fit, BoxFit.contain);
      final lockRect = t.getRect(lock);
      final buttonRect = t.getRect(find.byKey(const ValueKey('home-games')));
      expect(lockRect.width, inInclusiveRange(32, 60));
      expect(lockRect.height, closeTo(lockRect.width, .000001));
      expect(buttonRect.contains(lockRect.topLeft), isTrue);
      expect(lockRect.right, lessThanOrEqualTo(buttonRect.right));
      expect(lockRect.bottom, lessThanOrEqualTo(buttonRect.bottom));
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
      await close(t, p);
    });
  }
}
