import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'package:kidsphonics/screens/parent_screen.dart';
import 'package:kidsphonics/widgets/parent_pin_form.dart';
import 'package:kidsphonics/widgets/animated_screen_art.dart';
import 'package:kidsphonics/widgets/home_flight_menu.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all thirteen current frames are bundled at their original dimensions',
      () async {
    expect(homeFrames.length, 3);
    for (final asset in [...skyFrames, ...homeFrames]) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.getUint32(16), 941, reason: asset);
      expect(bytes.getUint32(20), 1672, reason: asset);
    }
    for (final asset in parentsFrames) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.getUint32(16), 1254, reason: asset);
      expect(bytes.getUint32(20), 1254, reason: asset);
    }
  });

  for (final (key, destination) in [
    ('home-lessons', LessonsScreen),
    ('home-games', GamesScreen),
    ('home-progress', ProgressScreen),
    ('home-parents', ParentScreen),
  ]) {
    testWidgets('artwork $key opens the corresponding screen', (t) async {
      SharedPreferences.setMockInitialValues({});
      mockProgressAudio();
      t.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await t.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final p = await mount(t, const HomeScreen());
      final target = find.byKey(ValueKey(key));
      for (final menu in ['lessons', 'games', 'progress']) {
        expect(find.byKey(ValueKey('home-$menu-tap-mark')), findsNothing);
      }
      await t.ensureVisible(target);
      await t.pumpAndSettle();
      final rect = t.getRect(target);
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
      await t.tap(target);
      await t.pumpAndSettle();
      expect(find.byType(destination), findsOneWidget);
      if (destination == ParentScreen) {
        expect(find.byType(ParentPinForm), findsOneWidget);
        expect(p.parentAuth.isAuthenticated, isFalse);
      }
      expect(p.masteredLetterCount, 0);
      await close(t, p);
    });
  }

  testWidgets('artwork respects the parent game-access setting', (t) async {
    SharedPreferences.setMockInitialValues({'gameAccess': false});
    mockProgressAudio();
    t.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
        t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final p = await mount(t, const HomeScreen());
    expect(
        t.widget<HomeFlightMenu>(find.byType(HomeFlightMenu)).onGames, isNull);
    expect(find.byKey(const ValueKey('home-games-tap-mark')), findsNothing);
    await t.ensureVisible(find.byKey(const ValueKey('home-games')));
    await t.tap(find.byKey(const ValueKey('home-games')));
    await t.pumpAndSettle();
    expect(find.byType(GamesScreen), findsNothing);
    await close(t, p);
  });

  for (final (name, frames) in [
    ('Home', homeFrames),
    ('Parents', parentsFrames)
  ]) {
    testWidgets('$name plays at the slower pace and respects motion settings',
        (t) async {
      var reduced = false;
      Future<void> render() async => t.pumpWidget(MaterialApp(
              home: MediaQuery(
            data: MediaQueryData(
                size: const Size(200, 300), disableAnimations: reduced),
            child: SizedBox(
                width: 200,
                height: 300,
                child: AnimatedScreenArt(
                    frames: frames, frameDuration: homeFrameDuration)),
          )));
      int visibleFrame() {
        final opacities = t
            .widgetList<Opacity>(find.descendant(
                of: find.byType(AnimatedScreenArt),
                matching: find.byType(Opacity)))
            .toList();
        return opacities.indexWhere((opacity) => opacity.opacity == 1);
      }

      await render();
      await t.runAsync(() async {
        for (final asset in frames) {
          await precacheImage(ResizeImage(AssetImage(asset), width: 200),
              t.element(find.byType(AnimatedScreenArt)));
          await rootBundle.load(asset);
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await t.pump();
      await t.pump(const Duration(milliseconds: 220));
      expect(visibleFrame(), 0);
      await t.pump(homeFrameDuration - const Duration(milliseconds: 210));
      expect(visibleFrame(), 1);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final paused = visibleFrame();
      await t.pump(const Duration(milliseconds: 400));
      expect(visibleFrame(), paused);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      await t.pump(homeFrameDuration + const Duration(milliseconds: 10));
      expect(visibleFrame(), isNot(paused));
      reduced = true;
      await render();
      await t.pump(const Duration(milliseconds: 400));
      expect(visibleFrame(), 0);
      await t.pumpWidget(const SizedBox());
    });
  }
}
