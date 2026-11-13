import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/controllers/cvc_lesson_controller.dart';
import 'package:kidsphonics/controllers/blending_lesson_controller.dart';
import 'package:kidsphonics/data/blending_lesson_data.dart';
import 'package:kidsphonics/data/cvc_lesson_data.dart';
import 'package:kidsphonics/models/word_lesson_progress.dart';
import 'package:kidsphonics/screens/letter_recognition_screen.dart';
import 'package:kidsphonics/screens/letter_sounds_screen.dart';
import 'package:kidsphonics/screens/alphabet_pictures_screen.dart';
import 'package:kidsphonics/screens/cvc_words_screen.dart';
import 'package:kidsphonics/screens/blending_sounds_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/lesson_swipe_navigation.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
  });

  Future<void> swipe(WidgetTester t, {bool previous = false}) async {
    final rect = t.getRect(find.byType(LessonSwipeNavigation));
    final start = Offset(rect.center.dx + (previous ? -80 : 80), rect.top + 35);
    await t.dragFrom(start, Offset(previous ? 160 : -160, 0));
    await t.pump();
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
    await t.pump();
  }

  Finder button(String label) => find.widgetWithText(OutlinedButton, label);

  for (final sound in [false, true]) {
    testWidgets(
        '${sound ? 'Letter Sounds' : 'Letter Recognition'} swipes and buttons share A-Z boundaries',
        (t) async {
      final p = await mount(t,
          sound ? const LetterSoundsScreen() : const LetterRecognitionScreen());
      String phrase() => t.widget<AudioButton>(find.byType(AudioButton)).phrase;
      String expected(String letter) => sound ? 'lesson-sound-$letter' : letter;
      await swipe(t, previous: true);
      expect(phrase(), expected('A'));
      await swipe(t);
      expect(phrase(), expected('B'));
      await t.tap(button('Next'));
      await t.pump();
      expect(phrase(), expected('C'));
      await swipe(t, previous: true);
      expect(phrase(), expected('B'));
      await t.tap(button('Previous'));
      await t.pump();
      expect(phrase(), expected('A'));
      for (var i = 0; i < 26; i++) {
        await swipe(t);
      }
      expect(phrase(), expected('Z'));
      expect(t.widget<OutlinedButton>(button('Next')).onPressed, isNull);
      expect((p.xp, p.stars, p.overallMasteredCount), (0, 0, 0));
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets('vowels swipe both ways, retain tab selection and stop at A/U',
      (t) async {
    final p = await mount(t, const LetterSoundsScreen(vowelsOnly: true));
    String phrase() => t.widget<AudioButton>(find.byType(AudioButton)).phrase;
    await swipe(t, previous: true);
    expect(phrase(), 'lesson-sound-A');
    await swipe(t);
    expect(phrase(), 'lesson-sound-E');
    await swipe(t, previous: true);
    expect(phrase(), 'lesson-sound-A');
    await t.tap(find.byKey(const ValueKey('vowel-tab-U')));
    await t.pump();
    await swipe(t);
    expect(phrase(), 'lesson-sound-U');
    await swipe(t, previous: true);
    expect(phrase(), 'lesson-sound-O');
    expect((p.xp, p.stars, p.overallMasteredCount), (0, 0, 0));
    await close(t, p);
  });

  testWidgets(
      'Alphabet & Pictures updates swipe directions as its controller changes',
      (t) async {
    final p = await mount(t, const AlphabetPicturesScreen());
    await swipe(t, previous: true);
    expect(find.byKey(const ValueKey('alphabet-picture-A')), findsOneWidget);
    await swipe(t);
    expect(find.byKey(const ValueKey('alphabet-picture-B')), findsOneWidget);
    await swipe(t, previous: true);
    expect(find.byKey(const ValueKey('alphabet-picture-A')), findsOneWidget);
    for (var i = 0; i < 26; i++) {
      await swipe(t);
    }
    expect(find.byKey(const ValueKey('alphabet-picture-Z')), findsOneWidget);
    expect(t.widget<OutlinedButton>(button('Next')).onPressed, isNull);
    expect((p.xp, p.stars, p.overallMasteredCount), (0, 0, 0));
    await close(t, p);
  });

  testWidgets(
      'CVC swipes reuse select, preserve controls and do not complete skipped words',
      (t) async {
    final lesson = CvcLessonController(
        play: (_) async => true, stop: () async {}, voiceEnabled: false);
    final p = await mount(t, CvcWordsScreen(controller: lesson));
    await swipe(t, previous: true);
    expect(lesson.index, 0);
    await swipe(t);
    expect(lesson.index, 1);
    await swipe(t, previous: true);
    expect(lesson.index, 0);
    await t.tap(button('Next'));
    await t.pump();
    expect(lesson.index, 1);
    unawaited(lesson.select(cvcLessonWords.length - 1));
    await t.pump();
    await swipe(t);
    expect(lesson.index, cvcLessonWords.length - 1);
    expect(p.wordLessonProgress(WordLesson.cvc).completed, isEmpty);
    expect((p.xp, p.stars), (0, 0));
    await close(t, p);
  });

  testWidgets(
      'Blending swipes both ways within boundaries and leaves puzzle drags intact',
      (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final lesson = BlendingLessonController(
        play: (_) async => true, stop: () async {}, voiceEnabled: false);
    final p = await mount(t, BlendingSoundsScreen(controller: lesson));
    await t.tap(button('Try Again'));
    await t.pump();
    final piece = find.byKey(const ValueKey('blend-piece-0'));
    final slot = find.byKey(const ValueKey('blend-slot-0'));
    await t.ensureVisible(piece);
    await t.dragFrom(
        t.getCenter(piece), t.getCenter(slot) - t.getCenter(piece));
    await t.pump();
    expect(lesson.slots[0], 0);
    expect(lesson.index, 0);
    await swipe(t, previous: true);
    expect(lesson.index, 0);
    await swipe(t);
    expect(lesson.index, 1);
    expect(lesson.slots, [null, null, null]);
    await swipe(t, previous: true);
    expect(lesson.index, 0);
    await swipe(t, previous: true);
    expect(lesson.index, 0);
    await swipe(t);
    expect(lesson.index, 1);
    for (var i = 1; i < blendingLessonWords.length; i++) {
      await swipe(t);
    }
    expect(lesson.index, blendingLessonWords.length - 1);
    expect(p.wordLessonProgress(WordLesson.blending).completed, isEmpty);
    expect((p.xp, p.stars), (0, 0));
    await close(t, p);
  });

  testWidgets(
      'Blending back swipe across word lengths preserves recorded completions',
      (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final lesson = BlendingLessonController(
        play: (_) async => true,
        stop: () async {},
        voiceEnabled: false,
        words: [blendingLessonWords.first, blendingLessonWords.last]);
    final p = await mount(t, BlendingSoundsScreen(controller: lesson));
    lesson.reset();
    await t.pump();
    Future<void> solve() async {
      for (var i = 0; i < lesson.word.word.length; i++) {
        expect(lesson.place(i, i), isTrue);
      }
      for (var i = 0; i < 80; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
      await t.pump();
      expect(lesson.phase, BlendingPhase.complete);
    }

    await solve();
    expect(p.wordLessonProgress(WordLesson.blending).completed, {'SUN'});
    await swipe(t);
    expect(lesson.word.word, 'TRACTOR');
    expect(lesson.slots, hasLength(7));
    await swipe(t, previous: true);
    expect(lesson.word.word, 'SUN');
    expect(lesson.slots, [null, null, null]);
    expect(p.wordLessonProgress(WordLesson.blending).completed, {'SUN'});
    await solve();
    expect(p.wordLessonProgress(WordLesson.blending).completed, {'SUN'});
    expect((p.xp, p.stars), (0, 0));
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  testWidgets('Blending previous cancels an old recording and pending praise',
      (t) async {
    final pending = Completer<bool>();
    final heard = <String>[];
    var stops = 0;
    final lesson = BlendingLessonController(
        words: [blendingLessonWords.first, blendingLessonWords.last],
        play: (phrase) {
          heard.add(phrase);
          return pending.future;
        },
        stop: () async {
          stops++;
          if (heard.isNotEmpty && !pending.isCompleted) pending.complete(false);
        });
    lesson.next();
    lesson.place(0, 0);
    await t.pump();
    expect(heard, hasLength(1));
    final before = stops;
    lesson.previous();
    await t.pump();
    expect(await pending.future, isFalse);
    expect(stops, greaterThan(before));
    expect(lesson.index, 0);
    expect(lesson.running, isFalse);
    expect(lesson.highlightedLetters, isEmpty);
    await t.pump(const Duration(seconds: 10));
    expect(heard, hasLength(1));
    lesson.previous();
    expect(lesson.index, 0);
    lesson.dispose();
  });

  testWidgets(
      'swiping CVC stops an old recording before the new word and ignores late completion',
      (t) async {
    SharedPreferences.setMockInitialValues({'voice': true, 'sfx': false});
    final heard = <String>[];
    final pending = <Completer<bool>>[];
    var active = 0, stops = 0;
    final lesson = CvcLessonController(play: (phrase) {
      expect(active, 0, reason: 'Recordings must not overlap');
      active++;
      heard.add(phrase);
      final completion = Completer<bool>();
      pending.add(completion);
      return completion.future.whenComplete(() => active--);
    }, stop: () async {
      stops++;
      for (final completion in pending) {
        if (!completion.isCompleted) completion.complete(false);
      }
      await Future<void>.value();
    });
    final p = await mount(t, CvcWordsScreen(controller: lesson));
    for (var i = 0; i < 10 && heard.isEmpty; i++) {
      await t.pump();
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    expect(heard, isNotEmpty);
    final before = stops;
    await swipe(t);
    expect(lesson.index, 1);
    expect(stops, greaterThan(before));
    expect(heard.last, cvcLessonWords[1].wordAudio);
    expect(heard, isNot(contains(cvcLessonWords[0].praiseAudio)));
    expect(p.wordLessonProgress(WordLesson.cvc).completed, isEmpty);
    await close(t, p);
  });
}
