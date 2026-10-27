import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:kidsphonics/data/home_village.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/widgets/animated_screen_art.dart';
import 'package:kidsphonics/widgets/home_character_visit.dart';
import 'package:kidsphonics/widgets/cloud_page_route.dart';
import 'package:kidsphonics/widgets/kids_navigation_bar.dart';
import 'package:kidsphonics/widgets/school_home_scene.dart';
import 'package:kidsphonics/widgets/student_wave.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'updated_scene_test.dart' show capture;

Future<void> waitForHomeCurtain(WidgetTester t) async {
  for (var i = 0;
      i < 100 && find.byType(CloudScreenTransition).evaluate().isEmpty;
      i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await t.pump();
  }
  expect(find.byType(CloudScreenTransition), findsOneWidget,
      reason:
          'visit=${t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene)).visit.value}, '
          'busy=${t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene)).busy}, '
          'lessons=${find.byType(LessonsScreen).evaluate().length}');
}

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
        final p = await mount(t, const HomeScreen());
        final app = t.widget<MaterialApp>(find.byType(MaterialApp));
        await t.pumpWidget(ChangeNotifierProvider.value(
            value: p, child: RepaintBoundary(key: key, child: app)));
        await t.pump();
        await t.runAsync(() => prepareCloudTransition(
            t.element(find.byType(HomeScreen)),
            cloudTransitionImages(t.element(find.byType(HomeScreen)))));
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
        expect(
            find.byKey(const ValueKey('home-character-cloud')), findsNothing);

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
        expect(
            find.byKey(const ValueKey('home-character-cloud')), findsNothing);
        expect(find.byType(LessonsScreen), findsNothing);
        expect(find.byType(GamesScreen), findsNothing);

        await t.pump(const Duration(milliseconds: 2));
        await waitForHomeCurtain(t);
        final transition =
            t.widget<CloudScreenTransition>(find.byType(CloudScreenTransition));
        final route =
            ModalRoute.of(t.element(find.byType(CloudScreenTransition)))!;
        expect(route.transitionDuration, HomeCharacterVisitTiming.curtain);
        expect(route.transitionDuration.inMilliseconds,
            greaterThanOrEqualTo(1500));
        await t.pump(const Duration(milliseconds: 360));
        expect(t.getRect(student), stopped);
        expect(
            find.byKey(const ValueKey('home-character-cloud')), findsNothing);
        final opacity = t
            .widget<Opacity>(
                find.byKey(const ValueKey('home-student-visibility')))
            .opacity;
        expect(opacity, 1);
        expect(find.byKey(const ValueKey('cloud-transition')), findsOneWidget);
        if (size.width == 390) {
          await capture(t, key, 'home_${category.name}_curtain_closing');
        }
        // Busy targets cannot start a second journey or reverse the approach.
        expect(
            t.widget<InkWell>(find.byKey(const ValueKey('home-lessons'))).onTap,
            isNull);
        expect(
            t.widget<InkWell>(find.byKey(const ValueKey('home-games'))).onTap,
            isNull);
        final destination = left ? LessonsScreen : GamesScreen;
        expect(find.byType(destination).hitTestable(), findsNothing);
        await t.pump(const Duration(milliseconds: 540));
        expect(transition.animation.value, closeTo(.5, .02));
        expect(find.byType(destination).hitTestable(), findsNothing);
        if (size.width == 390) {
          await capture(t, key, 'home_${category.name}_curtain_closed');
        }
        await t.pump(const Duration(milliseconds: 500));
        if (size.width == 390) {
          await capture(t, key, 'home_${category.name}_curtain_opening');
        }
        await t.pump(const Duration(milliseconds: 450));
        expect(find.byKey(const ValueKey('cloud-transition')), findsNothing);
        expect(find.byType(destination), findsOneWidget);
        Navigator.of(t.element(find.byType(destination))).pop();
        await t.pump();
        await t.pump(const Duration(milliseconds: 1850));
        await t.pump();
        expect(t.getRect(student), start);
        expect(
            find.byKey(const ValueKey('home-character-cloud')), findsNothing);
        expect(t.takeException(), isNull);
        await close(t, p);
      });
    }
  }

  for (final elapsed in [1250, 1450]) {
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
      expect(find.byKey(const ValueKey('home-character-cloud')), findsNothing);
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
    expect(find.byKey(const ValueKey('home-character-cloud')), findsNothing);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
