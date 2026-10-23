import 'dart:io';
import 'dart:typed_data';
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

  test('supplied composition stays unchanged and exports have 8K dimensions',
      () {
    const hashes = {
      'morning':
          '2ece0982a9657d277b989fcde86cd2c6db74934625066ebd89fcf4b89b171c04',
      'sunset':
          '6dfe0eea3002a1f5445ea1f5a64138e14d6bc6f55714b0158cacee2b3f87667e',
      'night':
          '45030644d37c844d1b1fb61bad684dd682942d9ddcd80ba06b509510da076d01',
    };
    for (final entry in hashes.entries) {
      final source = File('assets/images/home_classroom/${entry.key}.png');
      expect(sha256.convert(source.readAsBytesSync()).toString(), entry.value);
      final file =
          File('output/home_classroom/8k/${entry.key}-8k.png').openSync();
      try {
        final header = ByteData.sublistView(file.readSync(24));
        expect(header.getUint32(16), 5120);
        expect(header.getUint32(20), 7680);
      } finally {
        file.closeSync();
      }
    }
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
