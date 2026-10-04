import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/controllers/cvc_lesson_controller.dart';
import 'package:kidsphonics/data/cvc_lesson_data.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/cvc_words_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/widgets/cvc_word_picture.dart';
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

  testWidgets('guided flow highlights each recording, blends and praises',
      (t) async {
    final heard = <String>[];
    final highlighted = <int>[];
    final stages = <CvcPhase>[];
    late CvcLessonController lesson;
    lesson = CvcLessonController(
        play: (phrase) async {
          heard.add(phrase);
          if (phrase.startsWith('lesson-sound-')) {
            highlighted.add(lesson.highlighted);
            stages.add(lesson.phase);
          }
          return true;
        },
        stop: () async {});
    final finished = lesson.start(introduction: true);
    for (var i = 0; i < 60; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await finished;
    expect(heard, [
      'cvc-intro',
      'cvc-word-cat',
      for (var i = 0; i < 3; i++) ...[
        'lesson-sound-C',
        'lesson-sound-A',
        'lesson-sound-T'
      ],
      'cvc-word-cat',
      'cvc-praise-cat'
    ]);
    expect(highlighted, [0, 1, 2, 0, 1, 2, 0, 1, 2]);
    expect(stages, [
      for (final stage in [
        CvcPhase.individual,
        CvcPhase.slowBlend,
        CvcPhase.fastBlend
      ]) ...[stage, stage, stage]
    ]);
    expect(lesson.phase, CvcPhase.complete);
    expect(lesson.blend, closeTo(1, .001));
    expect(lesson.running, isFalse);
    lesson.dispose();
  });

  testWidgets('rapid next and replay ignore late audio completions', (t) async {
    final heard = <String>[];
    final pending = <Completer<bool>>[];
    final lesson = CvcLessonController(
        play: (phrase) {
          heard.add(phrase);
          final result = Completer<bool>();
          pending.add(result);
          return result.future;
        },
        stop: () async {});
    unawaited(lesson.start());
    await t.pump();
    unawaited(lesson.select(1));
    await t.pump();
    expect(heard, ['cvc-word-cat', 'cvc-word-bat']);
    pending[0].complete(true);
    await t.pump(const Duration(seconds: 2));
    expect(heard, hasLength(2));
    unawaited(lesson.start());
    await t.pump();
    pending[1].complete(true);
    await t.pump(const Duration(seconds: 2));
    expect(heard, ['cvc-word-cat', 'cvc-word-bat', 'cvc-word-bat']);
    lesson.dispose();
    pending[2].complete(true);
    await t.pump(const Duration(seconds: 2));
    expect(heard, hasLength(3));
  });

  testWidgets('individual sound cancels the automatic sequence', (t) async {
    final heard = <String>[];
    final lesson = CvcLessonController(
        play: (phrase) async {
          heard.add(phrase);
          return true;
        },
        stop: () async {});
    unawaited(lesson.start());
    await t.pump();
    await lesson.hearLetter(1);
    await t.pump(const Duration(seconds: 10));
    expect(heard, ['cvc-word-cat', 'lesson-sound-A']);
    expect(lesson.running, isFalse);
    lesson.dispose();
  });

  testWidgets('mute, background pause and dispose cancel queued sounds',
      (t) async {
    final heard = <String>[];
    var stops = 0;
    final lesson = CvcLessonController(play: (phrase) async {
      heard.add(phrase);
      return true;
    }, stop: () async {
      stops++;
    });
    unawaited(lesson.start());
    await t.pump();
    lesson.setVoiceEnabled(false);
    await t.pump(const Duration(seconds: 10));
    expect(heard, ['cvc-word-cat']);
    unawaited(lesson.start());
    await t.pump(const Duration(milliseconds: 300));
    lesson.pause();
    await t.pump(const Duration(seconds: 10));
    expect(heard, ['cvc-word-cat']);
    expect(lesson.running, isFalse);
    expect(stops, greaterThanOrEqualTo(3));
    lesson.dispose();
  });

  testWidgets('audio failure leaves a replayable visual lesson', (t) async {
    final lesson =
        CvcLessonController(play: (_) async => false, stop: () async {});
    unawaited(lesson.start());
    for (var i = 0; i < 150; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(lesson.audioUnavailable, isTrue);
    expect(lesson.phase, CvcPhase.complete);
    expect(lesson.running, isFalse);
    lesson.dispose();
  });

  test('all 25 document words have bundled narration, phonemes and a picture',
      () async {
    expect(cvcLessonWords, hasLength(25));
    expect(cvcLessonWords.map((w) => w.word).toSet(), hasLength(25));
    for (final vowel in ['A', 'E', 'I', 'O', 'U']) {
      expect(cvcLessonWords.where((w) => w.vowel == vowel), hasLength(5));
    }
    for (final word in cvcLessonWords) {
      expect(word.word,
          matches(RegExp(r'^[B-DF-HJ-NP-TV-Z][AEIOU][B-DF-HJ-NP-TV-Z]$')));
      expect(
          word.imageAsset != null ||
              word.emoji.isNotEmpty ||
              ['WIG', 'FIN', 'SIT', 'TOP'].contains(word.word),
          isTrue);
      if (word.imageAsset != null) {
        expect((await rootBundle.load(word.imageAsset!)).lengthInBytes,
            greaterThan(0));
      }
      for (final phrase in [
        word.wordAudio,
        word.praiseAudio,
        'cvc-intro',
        for (var i = 0; i < 3; i++) word.soundAudio(i)
      ]) {
        final asset = PhonicsAudioService.assetForPhrase(phrase);
        expect(asset, isNotNull);
        final data = await rootBundle.load('assets/$asset');
        expect(data.lengthInBytes, greaterThan(44));
        if (asset!.endsWith('.wav')) {
          expect(String.fromCharCodes(data.buffer.asUint8List(0, 4)), 'RIFF');
        }
      }
    }
    expect(
        Directory('assets/audio/cvc_lesson')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.wav')),
        hasLength(51));
  });

  Finder control(String label) => find.widgetWithText(OutlinedButton, label);
  test('app audio adapter advances the muted intro and cancels cleanly',
      () async {
    final provider = AppProvider();
    await provider.ready;
    final lesson = CvcLessonController(
      play: provider.phonicsAudio.playInstruction,
      stop: provider.phonicsAudio.stop,
      voiceEnabled: false,
    );
    final playback = lesson.start(introduction: true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    expect(lesson.phase, CvcPhase.picture);
    lesson.dispose();
    await playback;
    provider.dispose();
  });
  CvcWordsScreen visualLesson() => CvcWordsScreen(
      controller: CvcLessonController(
          play: (_) async => true, stop: () async {}, voiceEnabled: false));

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1024)
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('CVC content and controls fit $size at text $scale',
          (t) async {
        await t.binding.setSurfaceSize(size);
        addTearDown(() => t.binding.setSurfaceSize(null));
        late AppProvider p;
        await t.runAsync(() async {
          p = AppProvider();
          await p.ready;
        });
        await t.pumpWidget(ChangeNotifierProvider.value(
            value: p,
            child: MaterialApp(
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!),
                home: visualLesson())));
        await t.pump();
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await t.pump();
        await t.pump(const Duration(milliseconds: 700));
        await t.pump();
        expect(find.byType(CvcWordPicture), findsOneWidget);
        final nav = ['Previous', 'Hear Again', 'Next']
            .map((label) => t.getRect(control(label)))
            .toList();
        expect(nav[0].top, nav[1].top);
        expect(nav[1].top, nav[2].top);
        expect(nav[2].right, lessThanOrEqualTo(size.width));
        for (final rect in nav) {
          expect(rect.bottom, lessThan(size.height));
        }
        await t.ensureVisible(find.byKey(const ValueKey('cvc-letter-1')));
        await t.tap(find.byKey(const ValueKey('cvc-letter-1')));
        await t.pump();
        expect(t.takeException(), isNull);
        await t.tap(control('Next'));
        await t.pump();
        expect(
            t.widget<Text>(find.byKey(const ValueKey('cvc-whole-word'))).data,
            'BAT');
        expect(p.xp, 0);
        expect(p.dailyActivity, isEmpty);
        expect(find.textContaining('Easy'), findsNothing);
        expect(find.textContaining('Score'), findsNothing);
        expect(find.textContaining('lives'), findsNothing);
        await close(t, p);
      });
    }
  }

  testWidgets('all words are reachable and browsing has no rewards or scores',
      (t) async {
    final p = await mount(t, visualLesson());
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
    await t.pump();
    await t.pump(const Duration(milliseconds: 700));
    for (final word in cvcLessonWords) {
      expect(t.widget<CvcWordPicture>(find.byType(CvcWordPicture)).word.word,
          word.word);
      expect(t.takeException(), isNull);
      if (word.word != 'RUN') {
        await t.tap(control('Next'));
        await t.pump();
      }
    }
    expect(t.widget<OutlinedButton>(control('Next')).onPressed, isNull);
    await t.tap(control('Previous'));
    await t.pump();
    expect(
        t.widget<CvcWordPicture>(find.byType(CvcWordPicture)).word.word, 'BUG');
    expect(p.xp, 0);
    expect(p.stars, 0);
    expect(p.journeyScore('cvc'), isNull);
    expect(p.dailyActivity, isEmpty);
    await close(t, p);
  });

  testWidgets('Lessons CVC card opens the guided lesson', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final p = await mount(t, const LessonsScreen());
    await t.ensureVisible(find.text('CVC Words'));
    await t.pumpAndSettle();
    await t.tap(find.text('CVC Words'));
    await t.pump();
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byType(CvcWordsScreen), findsOneWidget);
    await close(t, p);
  });
}
