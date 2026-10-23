import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/home_village.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'package:kidsphonics/screens/parent_screen.dart';
import 'package:kidsphonics/widgets/school_home_scene.dart';
import 'package:kidsphonics/widgets/student_wave.dart';
import 'package:kidsphonics/widgets/student_character_picker.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({'voice': false});
  });

  Future<void> capture(WidgetTester t, GlobalKey boundary, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    await t.runAsync(() async {
      for (final (family, filenames) in [
        (
          'Nunito',
          [
            'Nunito-Regular.ttf',
            'Nunito-Bold.ttf',
            'Nunito-ExtraBold.ttf',
            'Nunito-Black.ttf'
          ]
        ),
        ('Fredoka', ['Fredoka-Regular.ttf']),
      ]) {
        final loader = FontLoader(family);
        for (final filename in filenames) {
          loader.addFont(rootBundle.load('assets/fonts/$filename'));
        }
        await loader.load();
      }
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
      await Future.wait(t
          .widgetList<Image>(find.byType(Image))
          .map((w) => precacheImage(w.image, boundary.currentContext!)));
    });
    await t.pump();
    await t.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/ui_previews/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  test('school artwork and transparent five-frame atlases are bundled',
      () async {
    for (final asset in [
      ...SchoolHomeScene.buttonAssets,
      StudentWave.assetFor('boy'),
      StudentWave.assetFor('girl'),
      'assets/images/school_home/lessons_mascot.png',
      'assets/images/school_home/games_mascot.png',
    ]) {
      final codec = await ui.instantiateImageCodec(
          (await rootBundle.load(asset)).buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      if (asset.contains('_wave')) {
        expect(Size(image.width.toDouble(), image.height.toDouble()),
            const Size(2172, 724));
      }
      {
        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(rgba!.getUint8(3), 0, reason: asset);
      }
      image.dispose();
      codec.dispose();
    }
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024),
    const Size(568, 320)
  ]) {
    testWidgets('school positions and tap targets fit $size', (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final boundary = GlobalKey();
      final p = await mount(
          t, RepaintBoundary(key: boundary, child: const HomeScreen()));
      await t.pumpAndSettle();
      final student = t.getRect(find.byKey(const ValueKey('home-student')));
      expect(find.byKey(const ValueKey('home-lessons-mascot')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-games-mascot')), findsOneWidget);
      expect(student.center.dx, closeTo(size.width / 2, 1));
      for (final id in ['home-lessons', 'home-games', 'home-start-adventure']) {
        final target = find.byKey(ValueKey(id));
        await t.ensureVisible(target);
        await t.pumpAndSettle();
        expect(t.getRect(target).width, greaterThanOrEqualTo(48));
        // Allow sub-pixel rounding when converting a positioned rect.
        expect(t.getRect(target).height, greaterThanOrEqualTo(48 - .001));
        expect(student.bottom, lessThan(t.getRect(target).top));
      }
      expect(find.byKey(const ValueKey('category-navigation')), findsNothing);
      expect(find.byKey(const ValueKey('home-progress')), findsNothing);
      expect(find.byKey(const ValueKey('home-parents')), findsNothing);
      for (final id in ['lessons', 'games', 'practice']) {
        final image = t.widget<Image>(find.byKey(ValueKey('home-$id-art')));
        expect(image.fit, BoxFit.contain);
      }
      expect(find.text('Letter A'), findsWidgets);
      expect(t.takeException(), isNull);
      if (size.height > size.width) {
        await capture(t, boundary, 'school_home_${size.width.toInt()}');
      }
      await close(t, p);
    });
  }

  for (final (category, destination) in [
    (HomeCategory.lessons, LessonsScreen),
    (HomeCategory.games, GamesScreen),
  ]) {
    testWidgets('${category.title} moves student toward classroom then opens',
        (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final p = await mount(t, const HomeScreen());
      await t.pump(const Duration(milliseconds: 1200));
      final start = t.getRect(find.byKey(const ValueKey('home-student')));
      final before = start.center;
      await t.tap(find.byKey(ValueKey('home-${category.name}')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 700));
      final after = t.getCenter(find.byKey(const ValueKey('home-student')));
      expect(after.dx < before.dx, category == HomeCategory.lessons);
      expect(after.dy, before.dy);
      final walkingSize =
          t.getRect(find.byKey(const ValueKey('home-student'))).size;
      expect(walkingSize.width, closeTo(start.width, .001));
      expect(walkingSize.height, closeTo(start.height, .001));
      expect(find.byType(destination), findsNothing);
      expect(
          t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene)).busy, true);
      await t.pump(const Duration(milliseconds: 600));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      await t.pump();
      await t.pump(const Duration(milliseconds: 350));
      expect(find.byType(destination), findsOneWidget);
      Navigator.of(t.element(find.byType(destination))).pop();
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      expect(t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene)).selected,
          isNull);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  for (final character in ['boy', 'girl']) {
    testWidgets(
        '$character waves and respects background, routes and reduced motion',
        (t) async {
      var reduced = false;
      Future<void> render() => t.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Center(
                  child: SizedBox(
                      width: 160,
                      height: 280,
                      child: StudentWave(character: character))))));
      int frame() {
        for (var i = 0; i < 5; i++) {
          if (find
              .byKey(ValueKey('student-wave-frame-$i'))
              .evaluate()
              .isNotEmpty) {
            return i;
          }
        }
        throw StateError('Missing frame');
      }

      await render();
      await t.pump();
      expect(frame(), 0);
      await t.pump(const Duration(milliseconds: 850));
      expect(frame(), 2);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      final paused = frame();
      await t.pump(const Duration(seconds: 1));
      expect(frame(), paused);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      expect(frame(), isNot(paused));
      final context = t.element(find.byType(StudentWave));
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Other screen'))));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      await t.pumpAndSettle();
      expect(t.hasRunningAnimations, isFalse);
      Navigator.of(context).pop();
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      reduced = true;
      await render();
      await t.pumpAndSettle();
      expect(frame(), 0);
      await t.pump(const Duration(seconds: 2));
      expect(frame(), 0);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets('backgrounding cancels classroom visit', (t) async {
    final p = await mount(t, const HomeScreen());
    await t.pump(const Duration(milliseconds: 1200));
    await t.ensureVisible(find.byKey(const ValueKey('home-lessons')));
    await t.tap(find.byKey(const ValueKey('home-lessons')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(seconds: 2));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump(const Duration(seconds: 2));
    expect(find.byType(LessonsScreen), findsNothing);
    expect(t.widget<InkWell>(find.byKey(const ValueKey('home-lessons'))).onTap,
        isNotNull);
    await close(t, p);
  });

  testWidgets(
      'saved girl and nickname preserve progress and restore on restart',
      (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final p = await mount(t, const HomeScreen());
    await t.runAsync(
        () => p.completeAdventure('A', List.filled(5, true), 'school-a'));
    await t.pumpAndSettle();
    final before = (p.xp, p.stars, p.adventureAssessments);
    await t.tap(find.byKey(const ValueKey('home-student')));
    await t.pumpAndSettle();
    expect(find.byType(StudentCharacterPicker), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('choose-girl')));
    await t.enterText(find.byType(TextField), 'Mia');
    await t.tap(find.byKey(const ValueKey('save-student')));
    await t.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await t.pumpAndSettle();
    expect(p.studentCharacter, 'girl');
    expect(p.studentName, 'Mia');
    expect(t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene)).character,
        'girl');
    expect((p.xp, p.stars, p.adventureAssessments), before);
    final boundary = GlobalKey();
    await close(t, p);
    final restored = await mount(
        t, RepaintBoundary(key: boundary, child: const HomeScreen()));
    await t.pumpAndSettle();
    expect(restored.studentCharacter, 'girl');
    expect(restored.studentName, 'Mia');
    expect(
        (restored.xp, restored.stars, restored.adventureAssessments), before);
    expect(
        t
            .widget<Semantics>(
                find.byKey(const ValueKey('home-practice-label')))
            .properties
            .label,
        'Practice This Letter B');
    expect(restored.recommendedAdventureLetter, 'B');
    await capture(t, boundary, 'school_home_girl');
    for (final (id, destination) in [
      ('progress', ProgressScreen),
      ('parents', ParentScreen)
    ]) {
      await t.tap(find.byKey(const ValueKey('home-lessons')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(ValueKey('main-nav-$id')));
      await t.pumpAndSettle();
      expect(find.byType(destination), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('main-nav-home')));
      await t.pumpAndSettle();
    }
    expect(
        (restored.xp, restored.stars, restored.adventureAssessments), before);
    await close(t, restored);
  });

  testWidgets('system insets protect logo and bottom navigation', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final p = await mount(
        t,
        Builder(
            builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    padding: const EdgeInsets.only(top: 24, bottom: 24)),
                child: const HomeScreen())));
    await t.pumpAndSettle();
    expect(t.getRect(find.byKey(const ValueKey('home-logo-art'))).top,
        greaterThanOrEqualTo(24));
    expect(t.getRect(find.byKey(const ValueKey('home-start-adventure'))).bottom,
        lessThanOrEqualTo(820));
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
