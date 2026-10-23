import 'package:kidsphonics/widgets/scene_dialogue.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/updated_scene.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/welcome_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'package:kidsphonics/screens/parent_screen.dart';
import 'package:kidsphonics/widgets/animated_screen_art.dart';
import 'package:kidsphonics/widgets/category_navigation.dart';
import 'package:kidsphonics/widgets/kids_navigation_bar.dart';
import 'package:kidsphonics/widgets/day_cycle_background.dart';
import 'package:kidsphonics/widgets/school_home_scene.dart';
import 'package:kidsphonics/widgets/scene_controls.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

Future<void> loadArt(WidgetTester t) async {
  await t.runAsync(() async {
    final context = t.element(find.byType(Scaffold).first);
    final images = t.widgetList<Image>(find.byType(Image)).where((image) {
      final provider = image.image is ResizeImage
          ? (image.image as ResizeImage).imageProvider
          : image.image;
      return provider is! AssetImage || !provider.assetName.endsWith('.gif');
    });
    await Future.wait(images.map((image) => precacheImage(image.image, context)
        .timeout(const Duration(seconds: 30))));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await t.pump();
}

Future<void> capture(WidgetTester t, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  await loadArt(t);
  await t.runAsync(() async {
    for (final (family, path) in [
      ('Fredoka', 'assets/fonts/Fredoka-Regular.ttf'),
      ('Nunito', 'assets/fonts/Nunito-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(path))).load();
    }
  });
  await t.pump();
  await t.runAsync(() async {
    final render =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/ui_previews/update_$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({'voice': false});
  });

  test('welcome and selected profile persist without replacing learning data',
      () async {
    final p = AppProvider();
    await p.ready;
    expect(p.welcomeCompleted, false);
    expect(await p.completeWelcome('girl', '   '), false);
    expect(p.welcomeCompleted, false);
    await p.completeJourneyLesson('letter_recognition', 4, 5);
    expect(await p.completeWelcome('girl', '  Mia  '), true);
    expect(p.studentName, 'Mia');
    final restored = AppProvider();
    await restored.ready;
    expect(restored.welcomeCompleted, true);
    expect(restored.studentCharacter, 'girl');
    expect(restored.studentName, 'Mia');
    expect(restored.journeyScore('letter_recognition'), 80);
    await restored.setStudentCharacter('boy', 'Leo');
    expect(restored.journeyScore('letter_recognition'), 80);
    expect(restored.welcomeCompleted, true);
    restored.dispose();
    p.dispose();
  });

  testWidgets('introductions precede required character and name setup',
      (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final p =
        await mount(t, RepaintBoundary(key: key, child: const WelcomeScreen()));
    expect(find.byKey(const ValueKey('home-student')), findsNothing);
    expect(find.byKey(const ValueKey('scene-dialogue-text')), findsNothing);
    await t.pump(const Duration(milliseconds: 1499));
    expect(find.byKey(const ValueKey('scene-dialogue-text')), findsNothing);
    await t.pump(const Duration(milliseconds: 1));
    expect(
        find.byWidgetPredicate((widget) =>
            widget is SceneDialogue &&
            widget.text == homeIntroduction.first.text),
        findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await capture(t, key, 'welcome_lessons');
    for (var i = 1; i <= 5; i++) {
      await t.ensureVisible(find.byKey(const ValueKey('welcome-next')));
      await t.tap(find.byKey(const ValueKey('welcome-next')));
      await t.pump(const Duration(milliseconds: 200));
      await t.pump();
      expect(
          find.byWidgetPredicate((widget) =>
              widget is SceneDialogue &&
              widget.text == homeIntroduction[i].text),
          findsOneWidget);
    }
    await t.pump(const Duration(milliseconds: 200));
    await capture(t, key, 'welcome_games');
    for (var i = 6; i < homeIntroduction.length; i++) {
      await t.tap(find.byKey(const ValueKey('welcome-next')));
      await t.pump(const Duration(milliseconds: 200));
      await t.pump();
    }
    expect(find.text('Get Started'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('welcome-next')));
    await t.pump(const Duration(milliseconds: 200));
    await t.pump();
    expect(find.byType(TextField), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('save-student')));
    await t.pump();
    expect(find.text('Please choose your character.'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('choose-girl')));
    await t.tap(find.byKey(const ValueKey('save-student')));
    await t.pump();
    expect(find.text('Please enter your name.'), findsOneWidget);
    expect(p.welcomeCompleted, false);
    await t.tap(find.byKey(const ValueKey('choose-girl')));
    await t.enterText(find.byType(TextField), 'Mia');
    await capture(t, key, 'profile_setup');
    await t.runAsync(() async {
      await t.tap(find.byKey(const ValueKey('save-student')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await t.pump();
    await t.pump(const Duration(milliseconds: 1600));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(p.welcomeCompleted, true);
    expect(p.studentName, 'Mia');
    expect(p.studentCharacter, 'girl');
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024)
  ]) {
    testWidgets('courtyard and category pages fit ${size.width}', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final p =
          await mount(t, RepaintBoundary(key: key, child: const HomeScreen()));
      await t.pump(const Duration(milliseconds: 1200));
      expect(find.byType(CategoryNavigation), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      final student = t.getRect(find.byKey(const ValueKey('home-student')));
      final lesson = t.getRect(find.byKey(const ValueKey('home-lessons')));
      final games = t.getRect(find.byKey(const ValueKey('home-games')));
      expect(lesson.center.dx, lessThan(student.center.dx));
      expect(games.center.dx, greaterThan(student.center.dx));
      expect(student.bottom, lessThan(lesson.top));
      expect(student.bottom, lessThan(games.top));
      await capture(t, key, 'home_${size.width.toInt()}');
      for (final page in [
        const LessonsScreen(),
        const GamesScreen(),
        const ProgressScreen(),
        const ParentScreen()
      ]) {
        await t.pumpWidget(ChangeNotifierProvider.value(
            value: p,
            child: MaterialApp(home: RepaintBoundary(key: key, child: page))));
        await t.pump();
        final mainSection = page is ProgressScreen ||
            page is ParentScreen ||
            page is LessonsScreen ||
            page is GamesScreen;
        expect(find.byType(CategoryNavigation),
            mainSection ? findsNothing : findsOneWidget);
        expect(find.byType(KidsNavigationBar),
            mainSection ? findsOneWidget : findsNothing);
        expect(find.byType(AppBar), findsNothing);
        expect(find.byType(LearnerProfileCard),
            page is ProgressScreen ? findsOneWidget : findsNothing);
        final room = switch (page) {
          LessonsScreen() => 'lessons',
          GamesScreen() => 'games',
          ProgressScreen() => 'progress',
          _ => 'parents',
        };
        expect(t.getRect(find.byKey(ValueKey('room-$room-background'))),
            Offset.zero & size);
        for (final image in t.widgetList<Image>(find.descendant(
            of: find.byKey(ValueKey('room-$room-background')),
            matching: find.byType(Image)))) {
          expect(
              image.fit,
              page is LessonsScreen || page is GamesScreen
                  ? BoxFit.cover
                  : BoxFit.fill);
        }
        expect(t.getRect(find.byKey(ValueKey('room-$room-content'))).height,
            greaterThan(size.height * (mainSection ? .65 : .9)));
        expect(find.byKey(const ValueKey('category-nav-home')), findsNothing);
        await capture(t, key, '${page.runtimeType}_${size.width.toInt()}');
        expect(t.takeException(), isNull);
      }
      await close(t, p);
    });
  }

  for (final left in [true, false]) {
    testWidgets(
        'walk ${left ? 'left' : 'right'} stops behind the guide before opening',
        (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final p = await mount(t, const HomeScreen());
      await loadArt(t);
      await t.pump(const Duration(milliseconds: 1200));
      final start = t.getRect(find.byKey(const ValueKey('home-student')));
      await t.tap(find.byKey(ValueKey('home-${left ? 'lessons' : 'games'}')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 900));
      expect(find.byType(SchoolHomeScene), findsOneWidget);
      final walk =
          t.widget<AnimatedScreenArt>(find.byKey(ValueKey('walk-boy-$left')));
      expect(walk.frames, studentWalkingFrames('boy', left: left));
      final rect = t.getRect(find.byKey(const ValueKey('home-student')));
      expect(left ? rect.center.dx < 195 : rect.center.dx > 195, true);
      expect(rect.width, closeTo(start.width, .001));
      expect(rect.height, closeTo(start.height, .001));
      expect(rect.top, start.top);
      expect(
          t
              .widget<Opacity>(
                  find.byKey(const ValueKey('home-student-visibility')))
              .opacity,
          1);
      await t.pump(const Duration(milliseconds: 880));
      final stopped = t.getRect(find.byKey(const ValueKey('home-student')));
      expect(stopped.width, closeTo(start.width, .001));
      expect(stopped.height, closeTo(start.height, .001));
      final mascot = t.getRect(
          find.byKey(ValueKey('home-${left ? 'lessons' : 'games'}-mascot')));
      expect(
          left
              ? stopped.center.dx > mascot.center.dx
              : stopped.center.dx < mascot.center.dx,
          true);
      expect(stopped.left, greaterThanOrEqualTo(0));
      expect(stopped.right, lessThanOrEqualTo(390));
      expect(find.byKey(ValueKey('walk-boy-$left')), findsNothing);
      expect(find.byType(SchoolHomeScene), findsOneWidget);
      await t.pump(const Duration(milliseconds: 120));
      await t.pump();
      // The character remains at the stop during the cloud and route fade.
      expect(
          t
              .widget<SchoolHomeScene>(
                  find.byType(SchoolHomeScene, skipOffstage: false))
              .selected
              ?.name,
          left ? 'lessons' : 'games');
      await t.pump(const Duration(milliseconds: 351));
      await t.pump();
      await t.pump(const Duration(milliseconds: 350));
      expect(left ? find.byType(LessonsScreen) : find.byType(GamesScreen),
          findsOneWidget);
      await t.tap(find.byKey(const ValueKey('main-nav-progress')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 170));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byType(ProgressScreen), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('main-nav-home')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 170));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(CategoryNavigation), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets('day cycle follows morning sunset night and pauses in background',
      (t) async {
    final p = await mount(
        t, const Scaffold(body: DayCycleBackground(category: 'lesson')));
    await loadArt(t);
    // The cycle starts after all three skies are decoded. Await those exact
    // providers instead of assuming background preloading finished in 100ms.
    final context = t.element(find.byType(DayCycleBackground));
    final width = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, 942);
    await t.runAsync(() => Future.wait(DayCycleBackground.framesFor('lesson')
        .map((asset) => precacheImage(
            ResizeImage(AssetImage(asset), width: width), context))));
    await t.pump();
    await t
        .pump(); // Seed the ticker's first frame before measuring elapsed time.
    expect(t.hasRunningAnimations, true);
    String visible() =>
        ((t.widget<Image>(find.byType(Image).first).image as ResizeImage)
                .imageProvider as AssetImage)
            .assetName;
    expect(visible(), endsWith('lesson_new_bg_1.png'));
    await t.pump(const Duration(milliseconds: 3500));
    expect(visible(), endsWith('lesson_new_bg_2.png'));
    await t.pump(const Duration(milliseconds: 3500));
    expect(visible(), endsWith('lesson_new_bg_3.png'));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(seconds: 8));
    expect(visible(), endsWith('lesson_new_bg_3.png'));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await t.pump(const Duration(milliseconds: 3500));
    expect(visible(), endsWith('lesson_new_bg_1.png'));
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
