import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/controllers/blending_lesson_controller.dart';
import 'package:kidsphonics/data/blending_lesson_data.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/blending_sounds_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/widgets/cvc_word_picture.dart';
import 'package:kidsphonics/widgets/blending_puzzle_piece.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher
      .clearAccessibilityFeaturesTestValue());
  Future<void> finish(WidgetTester t) async {
    for (var i = 0; i < 70; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  BlendingLessonController controller(
          {List<String>? heard, bool voice = true}) =>
      BlendingLessonController(
          play: (phrase) async {
            heard?.add(phrase);
            return true;
          },
          stop: () async {},
          voiceEnabled: voice);
  Finder control(String label) => find.widgetWithText(OutlinedButton, label);
  Finder slot(int i) => find.byKey(ValueKey('blend-slot-$i'));
  Finder piece(int i) => find.byKey(ValueKey('blend-piece-$i'));

  Future<void> finishIntroduction(
      WidgetTester t, BlendingLessonController lesson) async {
    for (var i = 0; i < 240 && lesson.phase == BlendingPhase.intro; i++) {
      await t.pump(const Duration(milliseconds: 500));
    }
    expect(lesson.phase, BlendingPhase.puzzle);
    await t.pump();
  }

  testWidgets(
      'intro, out-of-order placements, blending and praise stay ordered',
      (t) async {
    final heard = <String>[];
    final lesson = controller(heard: heard);
    lesson.introduce();
    await t.pump();
    expect(lesson.phase, BlendingPhase.puzzle);
    expect(lesson.order.map((i) => lesson.word.word[i]).join(), isNot('SUN'));
    expect(lesson.place(2, 2), isTrue);
    expect(lesson.place(0, 0), isTrue);
    expect(lesson.place(1, 1), isTrue);
    await finish(t);
    expect(heard, [
      'blend-intro-1',
      'blend-intro-2',
      'lesson-sound-N',
      'lesson-sound-S',
      'lesson-sound-U',
      'lesson-sound-S',
      'lesson-sound-U',
      'lesson-sound-N',
      'blend-word-sun',
      'blend-praise-sun'
    ]);
    expect(lesson.phase, BlendingPhase.complete);
    expect(lesson.joined, isTrue);
    expect(lesson.running, isFalse);
    lesson.dispose();
  });
  testWidgets('wrong slot is gentle, never fills or awards completion',
      (t) async {
    final heard = <String>[];
    final lesson = controller(heard: heard);
    expect(lesson.place(0, 1), isFalse);
    expect(lesson.place(0, 2), isFalse);
    await t.pump();
    expect(heard, ['blend-try-another']);
    expect(lesson.slots, [null, null, null]);
    expect(lesson.tryAnother, isTrue);
    expect(lesson.place(0, 0), isTrue);
    await t.pump();
    expect(lesson.tryAnother, isFalse);
    expect(lesson.place(0, 0), isFalse);
    expect(lesson.slots, [0, null, null]);
    lesson.dispose();
  });
  testWidgets('last word rejects reused pieces and stays at the end',
      (t) async {
    final lesson = controller();
    for (var i = 1; i < blendingLessonWords.length; i++) {
      lesson.next();
    }
    expect(lesson.word.word, 'WIG');
    expect(lesson.place(0, 0), isTrue);
    expect(lesson.place(0, 2), isFalse);
    expect(lesson.place(2, 2), isTrue);
    expect(lesson.place(1, 1), isTrue);
    await finish(t);
    expect(lesson.phase, BlendingPhase.complete);
    lesson.next();
    expect(lesson.word.word, 'WIG');
    lesson.dispose();
  });
  testWidgets(
      'Hear Again gives sounds and word without solving an incomplete puzzle',
      (t) async {
    final heard = <String>[];
    final lesson = controller(heard: heard);
    lesson.place(0, 0);
    await t.pump();
    heard.clear();
    lesson.hearAgain();
    await finish(t);
    expect(heard, [
      'lesson-sound-S',
      'lesson-sound-U',
      'lesson-sound-N',
      'blend-word-sun'
    ]);
    expect(lesson.slots, [0, null, null]);
    expect(lesson.complete, isFalse);
    expect(lesson.joined, isFalse);
    lesson.reset();
    expect(lesson.slots, [null, null, null]);
    lesson.dispose();
  });
  testWidgets(
      'reset and next cancel queued sounds and late playback completions',
      (t) async {
    final heard = <String>[];
    final pending = <Completer<bool>>[];
    final lesson = BlendingLessonController(
        play: (phrase) {
          heard.add(phrase);
          final result = Completer<bool>();
          pending.add(result);
          return result.future;
        },
        stop: () async {});
    for (var i = 0; i < 3; i++) {
      lesson.place(i, i);
    }
    await t.pump();
    lesson.reset();
    pending[0].complete(true);
    await finish(t);
    expect(heard, ['lesson-sound-S']);
    expect(lesson.slots, [null, null, null]);
    lesson.place(0, 0);
    await t.pump();
    lesson.next();
    pending[1].complete(true);
    await finish(t);
    expect(heard, ['lesson-sound-S', 'lesson-sound-S']);
    expect(lesson.word.word, 'CUP');
    expect(lesson.slots, [null, null, null]);
    lesson.dispose();
  });
  testWidgets('mute, background pause and dispose stop playback', (t) async {
    final heard = <String>[];
    final lesson = controller(heard: heard);
    lesson.hearAgain();
    await t.pump();
    lesson.setVoiceEnabled(false);
    await finish(t);
    expect(heard, ['lesson-sound-S']);
    lesson.hearAgain();
    await t.pump();
    lesson.pause();
    await finish(t);
    expect(lesson.running, isFalse);
    lesson.setVoiceEnabled(true);
    lesson.hearAgain();
    await t.pump();
    lesson.dispose();
    await finish(t);
    expect(heard, ['lesson-sound-S', 'lesson-sound-S']);
  });
  testWidgets('missing audio still allows the puzzle and celebration',
      (t) async {
    final lesson =
        BlendingLessonController(play: (_) async => false, stop: () async {});
    for (var i = 0; i < 3; i++) {
      lesson.place(i, i);
    }
    await finish(t);
    expect(lesson.audioUnavailable, isTrue);
    expect(lesson.phase, BlendingPhase.complete);
    expect(lesson.running, isFalse);
    lesson.dispose();
  });
  test(
      'all 22 supplied words have bundled word, praise, phonemes and picture support',
      () async {
    expect(blendingLessonWords, hasLength(22));
    expect(blendingLessonWords.map((w) => w.word).toSet(), hasLength(22));
    for (final word in blendingLessonWords) {
      expect(
          word.imageAsset != null ||
              word.emoji.isNotEmpty ||
              ['FIN', 'RUG', 'BIG', 'DIG', 'RIB', 'MOP', 'HUG']
                  .contains(word.word),
          isTrue);
      if (word.imageAsset != null) {
        expect((await rootBundle.load(word.imageAsset!)).lengthInBytes,
            greaterThan(0));
      }
      for (final phrase in [
        word.wordAudio,
        word.praiseAudio,
        'blend-intro-1',
        'blend-intro-2',
        'blend-try-another',
        for (var i = 0; i < 3; i++) word.soundAudio(i)
      ]) {
        final asset = PhonicsAudioService.assetForPhrase(phrase);
        expect(asset, isNotNull);
        final data = await rootBundle.load('assets/$asset');
        expect(data.lengthInBytes, greaterThan(44));
        expect(asset, endsWith('.mp3'));
      }
    }
    expect(
        Directory('assets/audio/blending_lesson').listSync().whereType<File>(),
        hasLength(45));
  });

  testWidgets(
      'drag rejects wrong slot, then accepts all letters; controls reset and advance',
      (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final lesson = controller();
    final p = await mount(t, BlendingSoundsScreen(controller: lesson));
    await t.pump();
    await finishIntroduction(t, lesson);
    await t.dragFrom(
        t.getCenter(piece(0)), t.getCenter(slot(1)) - t.getCenter(piece(0)));
    await t.pump();
    expect(lesson.slots, [null, null, null]);
    expect(find.text('Try another spot!'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await t.dragFrom(
          t.getCenter(piece(i)), t.getCenter(slot(i)) - t.getCenter(piece(i)));
      await t.pump();
    }
    await finish(t);
    expect(lesson.phase, BlendingPhase.complete);
    expect(find.text('SUN'), findsOneWidget);
    await t.tap(control('Hear Again'));
    await finish(t);
    expect(lesson.phase, BlendingPhase.complete);
    await t.tap(control('Try Again'));
    await t.pump();
    expect(lesson.slots, [null, null, null]);
    await t.tap(control('Next'));
    await t.pump();
    expect(lesson.word.word, 'CUP');
    expect(p.xp, 0);
    expect(p.stars, 0);
    expect(p.dailyActivity, isEmpty);
    await close(t, p);
  });

  testWidgets('wrong drop animates home and reset cancels the return overlay',
      (t) async {
    t.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: false);
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final lesson = controller();
    final p = await mount(t, BlendingSoundsScreen(controller: lesson));
    await t.pump();
    await finishIntroduction(t, lesson);
    await t.dragFrom(
        t.getCenter(piece(0)), t.getCenter(slot(1)) - t.getCenter(piece(0)));
    await t.pump();
    expect(find.byType(BlendingPuzzlePiece), findsNWidgets(7));
    await t.pump(const Duration(milliseconds: 300));
    await t.pump();
    expect(find.byType(BlendingPuzzlePiece), findsNWidgets(6));
    expect(lesson.slots, [null, null, null]);
    await t.dragFrom(
        t.getCenter(piece(0)), t.getCenter(slot(1)) - t.getCenter(piece(0)));
    await t.pump();
    await t.tap(control('Try Again'));
    await t.pump();
    expect(find.byType(BlendingPuzzlePiece), findsNWidgets(6));
    expect(lesson.tryAnother, isFalse);
    await close(t, p);
    expect(t.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1024)
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
          'touch controls and tap alternative fit $size with text $scale',
          (t) async {
        await t.binding.setSurfaceSize(size);
        addTearDown(() => t.binding.setSurfaceSize(null));
        late AppProvider p;
        await t.runAsync(() async {
          p = AppProvider();
          await p.ready;
        });
        final lesson = controller(voice: false);
        await t.pumpWidget(ChangeNotifierProvider.value(
            value: p,
            child: MaterialApp(
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!),
                home: BlendingSoundsScreen(controller: lesson))));
        await t.pump();
        await t.pump(const Duration(milliseconds: 700));
        await finishIntroduction(t, lesson);
        expect(find.byType(CvcWordPicture), findsOneWidget);
        for (final label in ['Hear Again', 'Try Again', 'Next']) {
          final rect = t.getRect(control(label));
          expect(rect.bottom, lessThan(size.height));
          expect(rect.width, greaterThanOrEqualTo(48));
        }
        await t.ensureVisible(piece(0));
        await t.pumpAndSettle();
        await t.tap(piece(0));
        await t.pump();
        expect(lesson.selected, 0);
        await t.ensureVisible(slot(0));
        await t.pumpAndSettle();
        await t.tap(slot(0));
        await t.pump();
        expect(lesson.slots[0], 0);
        expect(t.takeException(), isNull);
        await close(t, p);
      });
    }
  }
  testWidgets('all words are reachable and last Next is disabled', (t) async {
    final lesson = controller();
    final p = await mount(t, BlendingSoundsScreen(controller: lesson));
    await t.pump();
    await finishIntroduction(t, lesson);
    for (final word in blendingLessonWords) {
      expect(t.widget<CvcWordPicture>(find.byType(CvcWordPicture)).word.word,
          word.word);
      if (word != blendingLessonWords.last) {
        await t.tap(control('Next'));
        await t.pump();
      }
    }
    expect(t.widget<OutlinedButton>(control('Next')).onPressed, isNull);
    expect(p.xp, 0);
    expect(p.dailyActivity, isEmpty);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
  testWidgets('Lessons menu opens Blending Sounds directly', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final p = await mount(t, const LessonsScreen());
    await t.ensureVisible(find.text('Blending Sounds'));
    await t.pumpAndSettle();
    await t.tap(find.text('Blending Sounds'));
    await t.pump();
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byType(BlendingSoundsScreen), findsOneWidget);
    await close(t, p);
  });
}
