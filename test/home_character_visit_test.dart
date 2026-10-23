import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/home_village.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/widgets/animated_screen_art.dart';
import 'package:kidsphonics/widgets/home_character_visit.dart';
import 'package:kidsphonics/widgets/kids_navigation_bar.dart';
import 'package:kidsphonics/widgets/school_home_scene.dart';
import 'package:kidsphonics/widgets/student_wave.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'updated_scene_test.dart' show capture, loadArt;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({'voice': false});
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024),
    const Size(1024, 1366),
  ]) {
    for (final category in [HomeCategory.lessons, HomeCategory.games]) {
      testWidgets(
          '${category.name} approaches and stops behind its guide at $size',
          (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final key = GlobalKey();
        final p = await mount(
            t, RepaintBoundary(key: key, child: const HomeScreen()));
        final student = find.byKey(const ValueKey('home-student'));
        final start = t.getRect(student);
        final mascot = find.byKey(ValueKey('home-${category.name}-mascot'));
        final guide = t.getRect(mascot);
        final left = category == HomeCategory.lessons;
        final footer =
            KidsNavigationGeometry.reservedHeight(size, EdgeInsets.zero);
        expect(start.height, closeTo((size.height - footer) * .32, .001));
        expect(start.center.dx, closeTo(size.width / 2, .001));
        final lessons = t.getRect(find.byKey(const ValueKey('home-lessons')));
        final games = t.getRect(find.byKey(const ValueKey('home-games')));
        expect(start.overlaps(lessons), false);
        expect(start.overlaps(games), false);
        // The source rug center maps through the full-screen cover crop,
        // independently of the dock's reserved content area.
        final fitted = applyBoxFit(BoxFit.cover, const Size(1024, 1536), size);
        final crop = Alignment.center
            .inscribe(fitted.source, const Rect.fromLTWH(0, 0, 1024, 1536));
        final matY = (1008 - crop.top) * size.height / crop.height;
        expect(start.bottom, closeTo(matY, .001));
        expect(lessons.width, closeTo(games.width, .001));
        expect(lessons.height, closeTo(games.height, .001));
        expect(lessons.left, closeTo(size.width - games.right, .001));
        final practice =
            t.getRect(find.byKey(const ValueKey('home-start-adventure')));
        expect(practice.center.dx, closeTo(size.width / 2, .001));
        expect(practice.top, greaterThan(lessons.bottom));
        expect(
            t.widget<StudentWave>(find.byType(StudentWave)).character, 'boy');
        if (size.width == 390) {
          await capture(t, key, 'boy_reference_size');
        }

        // The common scene stack must paint the student first and guide later.
        final stack = t.widget<Stack>(
            find.ancestor(of: mascot, matching: find.byType(Stack)).first);
        expect(stack.children.first, isA<AnimatedBuilder>());
        expect(stack.children[1], isA<Positioned>());

        await t.tap(find.byKey(ValueKey('home-${category.name}')));
        await t.pump();
        await t.pump(const Duration(milliseconds: 550));
        final halfway = t.getRect(student);
        expect(
            left
                ? halfway.center.dx < start.center.dx
                : halfway.center.dx > start.center.dx,
            true);
        final art =
            t.widget<AnimatedScreenArt>(find.byKey(ValueKey('walk-boy-$left')));
        expect(art.fit, BoxFit.contain);
        expect(halfway.width, closeTo(start.width, .001));
        expect(halfway.height, closeTo(start.height, .001));
        expect(find.byType(HomeCharacterCloud), findsNothing);

        await t.pump(const Duration(milliseconds: 550));
        final stopped = t.getRect(student);
        expect(find.byKey(ValueKey('walk-boy-$left')), findsNothing);
        expect(find.byType(StudentWave), findsOneWidget);
        expect(t.widget<StudentWave>(find.byType(StudentWave)).animate, true);
        expect(stopped.top, start.top);
        expect(stopped.left, greaterThanOrEqualTo(0));
        expect(stopped.right, lessThanOrEqualTo(size.width));
        expect(
            left
                ? stopped.center.dx > guide.center.dx
                : stopped.center.dx < guide.center.dx,
            true);
        expect(
            left
                ? stopped.center.dx < guide.right
                : stopped.center.dx > guide.left,
            true);
        // The face stays clear while the lower body can be naturally occluded.
        expect(stopped.top + stopped.height * .4, lessThan(guide.top));
        if (size.width == 390) {
          await capture(t, key, 'boy_${category.name}_stop');
        }
        await t.pump(const Duration(milliseconds: 399));
        expect(t.getRect(student), stopped);
        expect(find.byType(HomeCharacterCloud), findsNothing);
        expect(find.byType(LessonsScreen), findsNothing);
        expect(find.byType(GamesScreen), findsNothing);

        await t.pump(const Duration(milliseconds: 376));
        expect(t.getRect(student), stopped);
        expect(find.byType(HomeCharacterCloud), findsOneWidget);
        final opacity = t
            .widget<Opacity>(
                find.byKey(const ValueKey('home-student-visibility')))
            .opacity;
        expect(opacity, inExclusiveRange(0, 1));
        expect(find.byType(LessonsScreen), findsNothing);
        expect(find.byType(GamesScreen), findsNothing);
        if (size.width == 390) {
          await loadArt(t);
          await capture(t, key, 'boy_${category.name}_cloud');
        }
        // Busy targets cannot start a second journey or reverse the approach.
        expect(
            t.widget<InkWell>(find.byKey(const ValueKey('home-lessons'))).onTap,
            isNull);
        expect(
            t.widget<InkWell>(find.byKey(const ValueKey('home-games'))).onTap,
            isNull);
        await t.pump(const Duration(milliseconds: 374));
        expect(find.byType(LessonsScreen), findsNothing);
        expect(find.byType(GamesScreen), findsNothing);
        await t.pump(const Duration(milliseconds: 2));
        await t.pump();
        await t.pump(const Duration(milliseconds: 350));
        final destination = left ? LessonsScreen : GamesScreen;
        expect(find.byType(destination), findsOneWidget);
        Navigator.of(t.element(find.byType(destination))).pop();
        await t.pump();
        await t.pump(const Duration(milliseconds: 350));
        await t.pump();
        expect(t.getRect(student), start);
        expect(find.byType(HomeCharacterCloud), findsNothing);
        expect(t.takeException(), isNull);
        await close(t, p);
      });
    }
  }

  for (final elapsed in [1250, 1800]) {
    testWidgets('backgrounding cancels the journey at ${elapsed}ms', (t) async {
      final p = await mount(t, const HomeScreen());
      await t.tap(find.byKey(const ValueKey('home-lessons')));
      await t.pump();
      await t.pump(Duration(milliseconds: elapsed));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump(const Duration(seconds: 3));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(find.byType(LessonsScreen), findsNothing);
      expect(find.byType(HomeCharacterCloud), findsNothing);
      expect(
          t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene)).busy, false);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets('reduced motion opens the destination without a walking delay',
      (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final p = await mount(t, const HomeScreen());
    await t.tap(find.byKey(const ValueKey('home-lessons')));
    await t.pumpAndSettle();
    expect(find.byType(LessonsScreen), findsOneWidget);
    expect(find.byType(HomeCharacterCloud), findsNothing);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
