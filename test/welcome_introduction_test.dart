import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/updated_scene.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/welcome_screen.dart';
import 'package:kidsphonics/widgets/scene_dialogue.dart';
import 'package:kidsphonics/widgets/student_character_picker.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'updated_scene_test.dart' show capture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({'voice': false});
  });

  for (final (size, textScale) in [
    (const Size(320, 568), 2.5),
    (const Size(390, 844), 2.5),
    (const Size(430, 932), 2.5),
    (const Size(768, 1024), 2.5),
    (const Size(844, 390), 2.5),
    (const Size(390, 844), 1.0),
    (const Size(768, 1024), 1.0),
  ]) {
    testWidgets(
        'intro text and controls stay contained at $size, text=$textScale',
        (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      if (const bool.fromEnvironment('CAPTURE_UI')) {
        await t.runAsync(() async {
          final loader = FontLoader('Nunito');
          for (final weight in ['Regular', 'Bold', 'ExtraBold', 'Black']) {
            loader.addFont(rootBundle.load('assets/fonts/Nunito-$weight.ttf'));
          }
          await loader.load();
        });
      }
      final boundary = GlobalKey();
      final p = await mount(
          t,
          Builder(
              builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      padding: const EdgeInsets.only(top: 24, bottom: 24),
                      textScaler: TextScaler.linear(textScale),
                      disableAnimations: true),
                  child: RepaintBoundary(
                      key: boundary, child: const WelcomeScreen()))));
      expect(find.byKey(const ValueKey('welcome-skip')), findsOneWidget);
      expect(find.byKey(const ValueKey('welcome-next')).hitTestable(),
          findsOneWidget);
      expect(
          t
              .getRect(find.byKey(const ValueKey('welcome-skip')))
              .overlaps(t.getRect(find.byKey(const ValueKey('welcome-next')))),
          false);
      for (final (key, background, foreground) in [
        ('welcome-skip', const Color(0xFFFFF0D8), const Color(0xFF7445C7)),
        ('welcome-next', const Color(0xFFFFD441), const Color(0xFF633012)),
      ]) {
        final button = t.widget<ElevatedButton>(find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(ElevatedButton)));
        expect(button.style!.backgroundColor!.resolve({}), background);
        expect(button.style!.foregroundColor!.resolve({}), foreground);
        expect(button.style!.backgroundColor!.resolve({WidgetState.disabled}),
            background);
      }
      expect(find.byKey(const ValueKey('home-start-adventure')), findsNothing);
      expect(find.byKey(const ValueKey('home-practice-art')), findsNothing);
      await t.pump(const Duration(milliseconds: 1500));
      for (var step = 0; step < homeIntroduction.length; step++) {
        expect(t.widget<SceneDialogue>(find.byType(SceneDialogue)).text,
            homeIntroduction[step].text);
        final content = t
            .getRect(find.byKey(const ValueKey('scene-dialogue-content')))
            .inflate(.1);
        for (final key in ['scene-dialogue-text', 'scene-dialogue-detail']) {
          final finder = find.byKey(ValueKey(key));
          if (finder.evaluate().isEmpty) continue;
          expect(content.contains(t.getTopLeft(finder)), true);
          expect(content.contains(t.getBottomRight(finder)), true);
        }
        for (final key in ['welcome-skip', 'welcome-next']) {
          final finder = find.byKey(ValueKey(key));
          expect(finder.hitTestable(), findsOneWidget);
          final rect = t.getRect(finder);
          expect(rect.top, greaterThanOrEqualTo(24));
          expect(rect.bottom, lessThanOrEqualTo(size.height - 24));
          expect(rect.height, greaterThanOrEqualTo(48));
        }
        expect(
            find.byKey(const ValueKey('home-start-adventure')), findsNothing);
        final arrow = find.byKey(const ValueKey('home-guide-arrow'));
        if (step == 2 || step == 7) {
          expect(arrow, findsOneWidget);
          expect(t.widget<Image>(arrow).fit, BoxFit.contain);
          final rect = t.getRect(arrow);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.bottom, lessThanOrEqualTo(size.height - 24));
          expect(rect.overlaps(content), false);
          expect(rect.center.dx < size.width / 2, step == 2);
          final transform = t.widget<Transform>(
              find.byKey(const ValueKey('home-guide-arrow-direction')));
          expect(transform.transform.storage[0], step == 7 ? -1 : 1);
        } else {
          expect(arrow, findsNothing);
        }
        if (step == 2 &&
            textScale == 1 &&
            [390.0, 768.0].contains(size.width)) {
          await capture(t, boundary, 'introduction_${size.width.toInt()}');
        }
        if (step == 7 && textScale == 1 && size.width == 390) {
          await capture(t, boundary, 'introduction_games_arrow_390');
        }
        await t.tap(find.byKey(const ValueKey('welcome-next')));
        await t.pump(const Duration(milliseconds: 200));
        await t.pump();
      }
      expect(find.byType(StudentCharacterPicker), findsOneWidget);
      expect(p.welcomeCompleted, false);
      expect(find.byKey(const ValueKey('home-start-adventure')), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets('Skip opens required setup; Practice appears only after saving',
      (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final p = await mount(t, const WelcomeScreen());
    // Skip is available even during the opening pause.
    await t.tap(find.byKey(const ValueKey('welcome-skip')));
    await t.pumpAndSettle();
    expect(find.byType(StudentCharacterPicker), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome-next')), findsNothing);
    expect(find.byKey(const ValueKey('home-practice-art')), findsNothing);
    expect(p.welcomeCompleted, false);
    await t.pump(const Duration(seconds: 5));
    expect(find.byType(SceneDialogue), findsNothing);
    await t.tap(find.byKey(const ValueKey('save-student')));
    await t.pump();
    expect(find.text('Please choose your character.'), findsOneWidget);
    await t.ensureVisible(find.byKey(const ValueKey('choose-girl')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('choose-girl')));
    await t.enterText(find.byType(TextField), 'Mia');
    await t.ensureVisible(find.byKey(const ValueKey('save-student')));
    await t.pumpAndSettle();
    await t.runAsync(() async {
      await t.tap(find.byKey(const ValueKey('save-student')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await t.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('home-start-adventure')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-practice-art')), findsOneWidget);
    expect(p.welcomeCompleted, true);
    expect(p.studentCharacter, 'girl');
    expect(p.studentName, 'Mia');
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
