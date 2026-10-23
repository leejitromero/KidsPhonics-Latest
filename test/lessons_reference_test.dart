import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/word_lesson_progress.dart';
import 'package:kidsphonics/controllers/cvc_lesson_controller.dart';
import 'package:kidsphonics/controllers/blending_lesson_controller.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/cvc_words_screen.dart';
import 'package:kidsphonics/screens/blending_sounds_screen.dart';
import 'package:kidsphonics/screens/letter_recognition_screen.dart';
import 'package:kidsphonics/screens/letter_sounds_screen.dart';
import 'package:kidsphonics/screens/alphabet_pictures_screen.dart';
import 'package:kidsphonics/widgets/lesson_menu_card.dart';
import 'package:kidsphonics/widgets/kids_navigation_bar.dart';
import 'package:kidsphonics/widgets/main_navigation_scope.dart';
import 'package:kidsphonics/widgets/student_character_picker.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'updated_scene_test.dart' show capture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({
      'voice': false,
      'sfx': false,
      'studentCharacter': 'girl',
      'studentName': 'Mia'
    });
  });
  void reduced(WidgetTester t) {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  const ids = [
    'letter_recognition',
    'letter_sounds',
    'vowel_sounds',
    'alphabet_pictures',
    'cvc_words',
    'blending_sounds'
  ];
  Finder card(String id) => find.byKey(ValueKey('lesson-card-$id'));
  Finder action(String id) => find.byKey(ValueKey('lesson-action-$id'));
  for (final scenario in [
    (size: const Size(320, 568), scale: 1.0),
    (size: const Size(390, 844), scale: 1.0),
    (size: const Size(430, 932), scale: 1.0),
    (size: const Size(768, 1024), scale: 1.0),
    (size: const Size(1024, 1366), scale: 1.0),
    (size: const Size(844, 390), scale: 1.0),
    (size: const Size(320, 568), scale: 2.0),
  ]) {
    testWidgets('six lessons in two columns and safe footer at $scenario',
        (t) async {
      reduced(t);
      t.view.physicalSize = scenario.size;
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = scenario.scale;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final boundary = GlobalKey();
      final p = await mount(
          t,
          Builder(
              builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      padding: const EdgeInsets.only(top: 24, bottom: 24)),
                  child: RepaintBoundary(
                      key: boundary, child: const LessonsScreen()))));
      await t.pumpAndSettle();
      expect(find.byType(LessonMenuCard), findsNWidgets(6));
      expect(find.byType(KidsNavigationBar), findsOneWidget);
      expect(find.byKey(const ValueKey('category-menu')), findsNothing);
      for (final image in t.widgetList<Image>(find.descendant(
          of: find.byKey(const ValueKey('room-lessons-background')),
          matching: find.byType(Image)))) {
        expect(image.fit, BoxFit.cover);
        expect(image.alignment, Alignment.center);
      }
      final rects = ids.map((id) => t.getRect(card(id))).toList();
      for (final rect in rects) {
        expect(rect.width, closeTo(rects.first.width, .001));
        expect(rect.height, closeTo(rects.first.height, .001));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(scenario.size.width));
      }
      expect(rects[0].top, closeTo(rects[1].top, .001));
      expect(rects[2].top, closeTo(rects[3].top, .001));
      expect(rects[0].right, lessThan(rects[1].left));
      expect(rects[2].top - rects[0].bottom, closeTo(12, .001));
      expect(rects[4].top - rects[2].bottom, closeTo(12, .001));
      expect(rects[4].top, closeTo(rects[5].top, .001));
      expect(rects[4].right, lessThan(rects[5].left));
      final back = t.getRect(find.byKey(const ValueKey('lessons-back')));
      final profile = t.getRect(find.byKey(const ValueKey('lessons-profile')));
      final banner = t.getRect(find.byKey(const ValueKey('lessons-banner')));
      expect(back.right, lessThanOrEqualTo(banner.left));
      expect(profile.left, greaterThanOrEqualTo(banner.right));
      expect(
          find.byKey(const ValueKey('lessons-profile-girl')), findsOneWidget);
      final dock = t.getRect(find.byKey(const ValueKey('kids-navigation-bar')));
      expect(dock.bottom, lessThanOrEqualTo(scenario.size.height - 24));
      for (final id in ids) {
        final image = t.widget<Image>(find.byKey(ValueKey('lesson-art-$id')));
        expect(image.fit, BoxFit.contain);
        await t.ensureVisible(action(id));
        await t.pumpAndSettle();
        expect(action(id).hitTestable(), findsOneWidget);
        expect(t.getRect(action(id)).bottom, lessThan(dock.top));
        expect(t.takeException(), isNull);
      }
      await t.drag(find.byKey(const PageStorageKey('lessons-scroll')),
          const Offset(0, 3000));
      await t.pumpAndSettle();
      if (scenario.scale == 1 && [390.0, 768.0].contains(scenario.size.width)) {
        await capture(
            t, boundary, 'lessons_reference_${scenario.size.width.toInt()}');
      }
      await close(t, p);
    });
  }
  test('word records survive reopening, ignore replays, validate and reset',
      () async {
    final p = AppProvider();
    await p.ready;
    await p.startWordLesson(WordLesson.cvc);
    expect(p.wordLessonProgress(WordLesson.cvc).started, true);
    expect(p.wordLessonProgress(WordLesson.cvc).completed, isEmpty);
    await p.completeWordLessonWord(WordLesson.cvc, 'CAT');
    await p.completeWordLessonWord(WordLesson.cvc, 'CAT');
    await p.completeWordLessonWord(WordLesson.blending, 'SUN');
    expect(p.wordLessonProgress(WordLesson.cvc).completed, {'CAT'});
    expect(() => p.wordLessonProgress(WordLesson.cvc).completed.add('BAT'),
        throwsUnsupportedError);
    await expectLater(p.completeWordLessonWord(WordLesson.cvc, 'UNKNOWN'),
        throwsArgumentError);
    final restored = AppProvider();
    await restored.ready;
    expect(restored.wordLessonProgress(WordLesson.cvc).completed, {'CAT'});
    expect(restored.wordLessonProgress(WordLesson.blending).completed, {'SUN'});
    expect((restored.xp, restored.stars, restored.overallMasteredCount),
        (0, 0, 0));
    await restored.parentAuth.setup('2580', '2580');
    await restored.resetProgress();
    expect(restored.wordLessonProgress(WordLesson.cvc).started, false);
    final reset = AppProvider();
    await reset.ready;
    expect(reset.wordLessonProgress(WordLesson.blending).completed, isEmpty);
    reset.dispose();
    restored.dispose();
    p.dispose();
  });
  test('damaged word records cannot inflate completion', () async {
    SharedPreferences.setMockInitialValues({
      'wordLessonProgressV1': jsonEncode({
        'cvc': {
          'started': 'bad',
          'completed': ['CAT', 'CAT', 'UNKNOWN', 5]
        },
        'blending': {'completed': false},
      })
    });
    final p = AppProvider();
    await p.ready;
    expect(p.wordLessonProgress(WordLesson.cvc).completed, {'CAT'});
    expect(p.wordLessonProgress(WordLesson.cvc).started, true);
    expect(p.wordLessonProgress(WordLesson.blending).completed, isEmpty);
    p.dispose();
  });
  testWidgets('only assessed letter mastery updates and profile is editable',
      (t) async {
    reduced(t);
    final p = await mount(t, const LessonsScreen());
    await t.runAsync(() => p.markLetterViewed('A'));
    await t.pump();
    expect(find.text('0 / 26 Mastered'), findsNWidgets(2));
    await t.runAsync(
        () => p.completeAdventure('A', List.filled(5, true), 'lessons-a'));
    await t.pump();
    expect(find.text('1 / 26 Mastered'), findsNWidgets(2));
    expect(find.text('1 / 5 Mastered'), findsOneWidget);
    expect(
        t
            .widget<LinearProgressIndicator>(find
                .byKey(const ValueKey('lesson-progress-letter_recognition')))
            .value,
        1 / 26);
    await t.tap(find.byKey(const ValueKey('lessons-profile')));
    await t.pumpAndSettle();
    expect(find.byType(StudentCharacterPicker), findsOneWidget);
    await t.runAsync(() => p.setStudentCharacter('boy', 'Sam'));
    Navigator.of(t.element(find.byType(StudentCharacterPicker))).pop();
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('lessons-profile-boy')), findsOneWidget);
    expect(find.text('1 / 26 Mastered'), findsNWidgets(2));
    await close(t, p);
  });
  for (final lesson in WordLesson.values) {
    testWidgets(
        '$lesson completion refreshes the menu without awarding mastery',
        (t) async {
      reduced(t);
      final p = await mount(t, const LessonsScreen());
      final id = lesson == WordLesson.cvc ? 'cvc_words' : 'blending_sounds';
      // Use the screens' existing injectable audio adapters so platform audio
      // futures do not determine the widget-test clock.
      final destination = lesson == WordLesson.cvc
          ? CvcWordsScreen(
              controller: CvcLessonController(
                  play: (_) async => true,
                  stop: () async {},
                  voiceEnabled: false))
          : BlendingSoundsScreen(
              controller: BlendingLessonController(
                  play: (_) async => true,
                  stop: () async {},
                  voiceEnabled: false));
      Navigator.of(t.element(find.byType(LessonsScreen))).push(
          PageRouteBuilder<void>(
              pageBuilder: (_, __, ___) => destination,
              transitionDuration: Duration.zero));
      await t.pumpAndSettle();
      final page =
          lesson == WordLesson.cvc ? CvcWordsScreen : BlendingSoundsScreen;
      expect(find.byType(page), findsOneWidget);
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump();
      expect(p.wordLessonProgress(lesson).started, true);
      expect(p.wordLessonProgress(lesson).completed, isEmpty);
      if (lesson == WordLesson.blending) {
        // Wait for both current instruction captions, including Voice Off's
        // reading fallback, before interacting with the puzzle.
        final controller = (destination as BlendingSoundsScreen).controller!;
        for (var i = 0;
            i < 30 && controller.phase == BlendingPhase.intro;
            i++) {
          await t.pump(const Duration(milliseconds: 500));
        }
        expect(controller.phase, BlendingPhase.puzzle);
        await t.pumpAndSettle();
        for (var i = 0; i < 3; i++) {
          final piece = find.byKey(ValueKey('blend-piece-$i'));
          await t.ensureVisible(piece);
          await t.tap(piece);
          await t.pump();
          final slot = find.byKey(ValueKey('blend-slot-$i'));
          await t.ensureVisible(slot);
          await t.tap(slot);
          await t.pump();
        }
      }
      for (var i = 0; i < 45; i++) {
        await t.pump(const Duration(milliseconds: 500));
      }
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(p.wordLessonProgress(lesson).completed, {lesson.words.first});
      Navigator.of(t.element(find.byType(page))).pop();
      await t.pumpAndSettle();
      final tile = t
          .widgetList<LessonMenuCard>(find.byType(LessonMenuCard))
          .singleWhere((tile) => tile.id == id);
      expect((tile.mastered, tile.started, tile.action), (1, true, 'Continue'));
      expect((p.xp, p.stars, p.overallMasteredCount), (0, 0, 0));
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }
  testWidgets(
      'Lessons footer returns to retained main screens with correct glow',
      (t) async {
    reduced(t);
    final p = await mount(t, const HomeScreen());
    final homeState = t.state(find.byType(HomeScreen));
    await t.tap(find.byKey(const ValueKey('home-lessons')));
    await t.pumpAndSettle();
    expect(find.byType(KidsNavigationBar), findsOneWidget);
    expect(t.widget<KidsNavigationBar>(find.byType(KidsNavigationBar)).current,
        KidsDestination.home);
    await t.tap(find.byKey(const ValueKey('main-nav-progress')));
    await t.pumpAndSettle();
    expect(t.widget<KidsNavigationBar>(find.byType(KidsNavigationBar)).current,
        KidsDestination.progress);
    await t.tap(find.byKey(const ValueKey('main-nav-home')));
    await t.pumpAndSettle();
    expect(t.state(find.byType(HomeScreen)), same(homeState));
    expect(find.byType(LessonsScreen), findsNothing);
    await close(t, p);
  });

  testWidgets(
      'each card opens its existing lesson and keeps the menu on return',
      (t) async {
    reduced(t);
    final p = await mount(t, const LessonsScreen());
    final menu = t.state(find.byType(LessonsScreen));
    for (final (id, type) in [
      ('letter_recognition', LetterRecognitionScreen),
      ('letter_sounds', LetterSoundsScreen),
      ('vowel_sounds', LetterSoundsScreen),
      ('alphabet_pictures', AlphabetPicturesScreen),
      ('cvc_words', CvcWordsScreen),
      ('blending_sounds', BlendingSoundsScreen),
    ]) {
      await t.ensureVisible(action(id));
      await t.tap(action(id));
      await t.pumpAndSettle();
      expect(find.byType(type), findsOneWidget);
      if (id == 'vowel_sounds') {
        expect(
            t.widget<LetterSoundsScreen>(find.byType(type)).vowelsOnly, true);
      }
      Navigator.of(t.element(find.byType(type))).pop();
      await t.pumpAndSettle();
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      expect(t.state(find.byType(LessonsScreen)), same(menu));
    }
    expect(p.wordLessonProgress(WordLesson.cvc).completed, isEmpty);
    expect(p.wordLessonProgress(WordLesson.blending).completed, isEmpty);
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  testWidgets('press feedback is subtle and rapid taps open only one route',
      (t) async {
    final p = await mount(t, const LessonsScreen());
    final pressed =
        find.byKey(const ValueKey('lesson-open-letter_recognition'));
    final gesture =
        await t.startGesture(t.getCenter(card('letter_recognition')));
    await t.pump(const Duration(milliseconds: 120));
    final scale =
        find.descendant(of: pressed, matching: find.byType(AnimatedScale));
    expect(t.widget<AnimatedScale>(scale).scale, .97);
    await gesture.cancel();
    await t.pump(const Duration(milliseconds: 120));
    expect(t.widget<AnimatedScale>(scale).scale, 1);
    final open = t
        .widgetList<LessonMenuCard>(find.byType(LessonMenuCard))
        .first
        .onPressed!;
    open();
    open();
    await t.pump();
    await t.pump(const Duration(milliseconds: 350));
    await t.pump();
    expect(find.byType(LetterRecognitionScreen), findsOneWidget);
    Navigator.of(t.element(find.byType(LetterRecognitionScreen))).pop();
    await t.pump();
    await t.pump(const Duration(milliseconds: 350));
    await t.pump();
    expect(find.byType(LessonsScreen), findsOneWidget);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
