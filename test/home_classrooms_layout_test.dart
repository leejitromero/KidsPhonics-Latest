import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/updated_scene.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/welcome_screen.dart';
import 'package:kidsphonics/widgets/scene_dialogue.dart';
import 'package:kidsphonics/widgets/student_wave.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'updated_scene_test.dart' show capture;

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
    const Size(768, 1024)
  ]) {
    for (final firstTime in [false, true]) {
      testWidgets(
          'full artwork and safe buttons at $size, onboarding=$firstTime',
          (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final p = await mount(
            t,
            Builder(
                builder: (context) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                        padding: const EdgeInsets.only(top: 44, bottom: 24)),
                    child: firstTime
                        ? const WelcomeScreen()
                        : const HomeScreen())));
        expect(t.getRect(find.byKey(const ValueKey('school-background'))),
            Offset.zero & size);
        for (final key in [
          'home-lessons',
          if (!firstTime) 'home-start-adventure',
          'home-games'
        ]) {
          final rect = t.getRect(find.byKey(ValueKey(key)));
          expect(rect.top, greaterThanOrEqualTo(44));
          expect(rect.bottom, lessThanOrEqualTo(size.height - 24));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
        }
        final lessons = t.getRect(find.byKey(const ValueKey('home-lessons')));
        final practice = firstTime
            ? Rect.zero
            : t.getRect(find.byKey(const ValueKey('home-start-adventure')));
        if (firstTime) {
          expect(
              find.byKey(const ValueKey('home-start-adventure')), findsNothing);
        }
        final games = t.getRect(find.byKey(const ValueKey('home-games')));
        expect(lessons.right, lessThan(games.left));
        if (!firstTime) {
          expect(lessons.bottom, lessThan(practice.top));
          expect(games.bottom, lessThan(practice.top));
        }
        expect(
            t
                .widget<Image>(find
                    .descendant(
                        of: find.byKey(const ValueKey('school-background')),
                        matching: find.byType(Image))
                    .first)
                .fit,
            BoxFit.cover);
        if (!firstTime) {
          final student = t.getRect(find.byKey(const ValueKey('home-student')));
          expect(student.overlaps(lessons), false);
          expect(student.overlaps(practice), false);
          expect(student.overlaps(games), false);
          final logo = t.getRect(find.byKey(const ValueKey('home-logo-art')));
          expect(logo.bottom, lessThan(student.top));
        }
        expect(find.byType(AppBar), findsNothing);
        expect(find.byKey(const ValueKey('home-student')),
            firstTime ? findsNothing : findsOneWidget);
        expect(t.takeException(), isNull);
        await close(t, p);
      });
    }
  }

  testWidgets('Home waves the chosen girl with guides behind the buttons',
      (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(
        {'voice': false, 'studentCharacter': 'girl'});
    final key = GlobalKey();
    final p =
        await mount(t, RepaintBoundary(key: key, child: const HomeScreen()));
    expect(t.widget<StudentWave>(find.byType(StudentWave)).character, 'girl');
    await t.pump(const Duration(milliseconds: 850));
    expect(find.byKey(const ValueKey('student-wave-frame-2')), findsOneWidget);
    for (final mascot in ['lessons', 'games']) {
      final guide = find.byKey(ValueKey('home-$mascot-mascot'));
      expect(guide, findsOneWidget);
      final button = find.byKey(ValueKey('home-$mascot'));
      expect(t.getRect(guide).top, lessThan(t.getRect(button).top));
      expect(t.getRect(guide).bottom, greaterThan(t.getRect(button).top));
    }
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('student-wave-frame-2')), findsOneWidget);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await capture(t, key, 'home_layout_girl_390');
    await close(t, p);
  });

  for (final size in [const Size(320, 568), const Size(430, 932)]) {
    testWidgets(
        'every introduction fits the speech bubble at $size with large text',
        (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      for (final dialogue in homeIntroduction) {
        await t.pumpWidget(MaterialApp(
            home: MediaQuery(
                data: MediaQueryData(
                    size: size, textScaler: const TextScaler.linear(2.5)),
                child: Scaffold(
                    body: Center(
                        child: SizedBox(
                            width: size.width * .95,
                            height: size.height * .29,
                            child: SceneDialogue(
                                text: dialogue.text,
                                art:
                                    'dialogue_box_${dialogue.games ? 1 : 2}.png',
                                flip: dialogue.games)))))));
        final content = t
            .getRect(find.byKey(const ValueKey('scene-dialogue-content')))
            .inflate(.1);
        final text =
            t.getRect(find.byKey(const ValueKey('scene-dialogue-text')));
        expect(content.contains(text.topLeft), true);
        expect(content.contains(text.bottomRight), true);
        expect(t.takeException(), isNull);
      }
      await t.pumpWidget(const SizedBox());
    });
  }
}
