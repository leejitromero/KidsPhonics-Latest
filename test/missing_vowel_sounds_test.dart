import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/missing_vowel_sounds.dart';
import 'package:kidsphonics/data/phonics_activity_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/missing_vowel_screen.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/services/audio_service.dart';
import 'package:kidsphonics/widgets/game_design.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';
import 'learner_ui_test.dart' show mount, close, flushWrites;
import 'learning_progress_test.dart' show mockProgressAudio;
import 'quiz_audio_harness.dart';

Future<void> drain(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await t.pump();
  }
}

Future<void> waitFor(WidgetTester t, bool Function() ready) async {
  for (var i = 0; i < 150 && !ready(); i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await t.pump();
  }
  expect(ready(), isTrue);
}

Set<int> glowing(WidgetTester t, int length) => {
      for (var i = 0; i < length; i++)
        if ((t
                    .widget<AnimatedContainer>(
                        find.byKey(ValueKey('vowel-sound-$i')))
                    .decoration as BoxDecoration)
                .color ==
            const Color(0xFFFFE36B))
          i
    };

Map<String, Object> soundTestPreferences({String? firstWord}) => {
      'sfx': false,
      'gameSessionOrderV1': jsonEncode({
        'version': 1,
        'games': {
          for (final d in Difficulty.values)
            'missing_vowel-${d.name}': {
              'pool': vowelPuzzlesFor(d).map((p) => p.word).toList(),
              'remaining': (vowelPuzzlesFor(d).map((p) => p.word).toList()
                ..sort((a, b) {
                  int rank(String w) => w == firstWord
                      ? -1
                      : PhonicsAudioService.assetForPhrase(
                                  missingVowelSoundSteps(w).single.phrase) !=
                              null
                          ? 0
                          : 1;
                  final byRank = rank(a).compareTo(rank(b));
                  return byRank == 0 ? a.compareTo(b) : byRank;
                })),
            },
        },
      }),
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues(soundTestPreferences());
    mockProgressAudio();
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });
  tearDown(() async {
    // Each harness models fresh native players, including their cached sources.
    PhonicsAudioService().dispose();
    AudioService().dispose();
    await Future<void>.delayed(Duration.zero);
  });

  test('all difficulties show all five vowels exactly once', () {
    for (final difficulty in Difficulty.values) {
      for (final vowel in 'AEIOU'.split('')) {
        expect(vowelChoicesFor(difficulty, vowel), ['A', 'E', 'I', 'O', 'U']);
      }
    }
  });

  test(
      'one cue highlights only the blank and never reads the word or consonants',
      () {
    final steps = missingVowelSoundSteps('TUB');
    expect(steps, hasLength(1));
    expect(steps.single.phrase, 'lesson-sound-U');
    expect(steps.single.positions, [1]);
    for (final d in Difficulty.values) {
      for (final puzzle in vowelPuzzlesFor(d)) {
        final cue = missingVowelSoundSteps(puzzle.word);
        expect(cue, hasLength(1), reason: puzzle.word);
        expect(cue.single.positions, [puzzle.display.split(' ').indexOf('_')]);
        expect(cue.single.phrase, isNot(puzzle.word));
        final asset = PhonicsAudioService.assetForPhrase(cue.single.phrase);
        expect(cue.single.phrase, 'lesson-sound-${puzzle.vowel}');
        expect(asset, isNotNull);
        expect(File('assets/$asset').existsSync(), isTrue);
      }
    }
  });

  test('every written vowel uses its existing sound recording', () {
    for (final (word, vowel, position) in [
      ('FAN', 'A', 1),
      ('NET', 'E', 1),
      ('LIPS', 'I', 1),
      ('MOON', 'O', 1),
      ('TUB', 'U', 1),
      ('BOOK', 'O', 1),
      ('ONION', 'O', 0),
      ('QUILL', 'U', 1),
      ('HEART', 'E', 1),
    ]) {
      final cue = missingVowelSoundSteps(word).single;
      expect(cue.phrase, 'lesson-sound-$vowel');
      expect(cue.positions, [position]);
    }
    expect(missingVowelSoundSteps('sky'), isEmpty);
  });

  testWidgets('MOON uses the existing O sound and highlights only its blank',
      (t) async {
    SharedPreferences.setMockInitialValues(
        soundTestPreferences(firstWord: 'MOON'));
    final audio = QuizAudioHarness()..install();
    final p = await mount(t, const MissingVowelScreen());
    expect(t.widget<WordGameLayout>(find.byType(WordGameLayout)).word, 'MOON');
    await audio.finishGameIntro(t, 'missing_vowel.mp3');
    await waitFor(t, () => audio.starts.isNotEmpty);
    expect(audio.starts.single, endsWith('/sounds/sound-o.mp3'));
    expect(glowing(t, 4), {1});
    expect(
        t.widget<Text>(find.byKey(const ValueKey('vowel-blank-letter'))).data,
        '_');
    expect((p.xp, p.stars), (0, 0));
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  testWidgets(
      'answering during a cue cancels remaining sounds without duplicate rewards',
      (t) async {
    final audio = QuizAudioHarness()..install();
    final p = await mount(t, const MissingVowelScreen());
    const intro = '/game_instructions/missing_vowel.mp3';
    await waitFor(t, () => audio.starts.any((s) => s.endsWith(intro)));
    await t.runAsync(() => audio.completeSource(intro));
    await waitFor(t, () => audio.starts.length >= 2);
    final word = t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
    final vowel = word[word.indexOf(RegExp('[AEIOU]'))];
    final choice = find
        .byWidgetPredicate((w) => w is GameAnswerButton && w.label == vowel);
    final button =
        find.descendant(of: choice, matching: find.byType(ElevatedButton));
    final before = audio.starts.length;
    await t.tap(button);
    await t.pump(const Duration(seconds: 2));
    await drain(t);
    await flushWrites(t);
    await waitFor(t, () => audio.starts.length > before);
    expect(audio.starts.length, before + 1);
    expect(audio.starts.last,
        endsWith('/${PhonicsAudioService.assetForPhrase(word)}'));
    expect(
        t.widget<Text>(find.byKey(const ValueKey('vowel-blank-letter'))).data,
        vowel);
    expect(glowing(t, word.length), isEmpty);
    expect((p.xp, p.stars), (8, 0));
    expect(t.widget<ElevatedButton>(button).onPressed, isNull);
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  testWidgets(
      'a covering route silences the cue and returning restarts the interrupted sound',
      (t) async {
    final audio = QuizAudioHarness()..install();
    final p = await mount(t, const MissingVowelScreen());
    const intro = '/game_instructions/missing_vowel.mp3';
    await waitFor(t, () => audio.starts.any((s) => s.endsWith(intro)));
    await t.runAsync(() => audio.completeSource(intro));
    await waitFor(t, () => audio.starts.length >= 2);
    final interrupted = audio.starts.last;
    final navigator = Navigator.of(t.element(find.byType(MissingVowelScreen)));
    navigator.push<void>(MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Covered'))));
    await t.pump(const Duration(milliseconds: 400));
    await drain(t);
    final count = audio.starts.length;
    await t.pump(const Duration(seconds: 2));
    expect(audio.starts.length, count);
    navigator.pop();
    await t.pump(const Duration(milliseconds: 400));
    await drain(t);
    await waitFor(t, () => audio.starts.length > count);
    expect(audio.starts.last, interrupted);
    expect((p.xp, p.stars), (0, 0));
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  testWidgets('FAN: blank cue, A flight, then completed word in that order',
      (t) async {
    SharedPreferences.setMockInitialValues(
        soundTestPreferences(firstWord: 'FAN'));
    t.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: false);
    final audio = QuizAudioHarness()..install();
    final p = await mount(
        t,
        const MediaQuery(
            data: MediaQueryData(disableAnimations: false),
            child: MissingVowelScreen()));
    await audio.finishGameIntro(t, 'missing_vowel.mp3');
    await waitFor(t, () => audio.starts.isNotEmpty);
    expect(audio.starts.single, endsWith('/sounds/sound-a.mp3'));
    expect(glowing(t, 3), {1});
    final choice =
        find.byWidgetPredicate((w) => w is GameAnswerButton && w.label == 'A');
    await t.tap(
        find.descendant(of: choice, matching: find.byType(ElevatedButton)));
    await t.pump();
    await t.pump();
    expect(find.byKey(const ValueKey('flying-vowel')), findsOneWidget);
    await t.pump(const Duration(milliseconds: 250));
    expect(
        t.widget<Text>(find.byKey(const ValueKey('vowel-blank-letter'))).data,
        '_');
    expect(audio.starts, hasLength(1));
    await t.pump(const Duration(milliseconds: 300));
    await waitFor(t, () => audio.starts.length == 2);
    expect(find.byKey(const ValueKey('flying-vowel')), findsNothing);
    expect(
        t.widget<Text>(find.byKey(const ValueKey('vowel-blank-letter'))).data,
        'A');
    expect(audio.starts.last, endsWith('/game_words/fan.mp3'));
    await t.pump(const Duration(seconds: 3));
    expect(t.widget<WordGameLayout>(find.byType(WordGameLayout)).word, 'FAN');
    await t.runAsync(() => audio.completeSource('/game_words/fan.mp3'));
    await drain(t);
    await t.pump(const Duration(milliseconds: 800));
    await drain(t);
    expect(t.widget<WordGameLayout>(find.byType(WordGameLayout)).word,
        isNot('FAN'));
    expect((p.xp, p.stars), (8, 0));
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  testWidgets('wrong answer advances without reading the completed word',
      (t) async {
    SharedPreferences.setMockInitialValues(
        soundTestPreferences(firstWord: 'FAN'));
    final audio = QuizAudioHarness()..install();
    final p = await mount(t, const MissingVowelScreen());
    await audio.finishGameIntro(t, 'missing_vowel.mp3');
    await waitFor(t, () => audio.starts.isNotEmpty);
    final choice =
        find.byWidgetPredicate((w) => w is GameAnswerButton && w.label == 'E');
    await t.tap(
        find.descendant(of: choice, matching: find.byType(ElevatedButton)));
    await t.pump();
    await t.pump();
    await t.pump(const Duration(milliseconds: 800));
    await drain(t);
    expect(audio.starts.any((s) => s.endsWith('/game_words/fan.mp3')), isFalse);
    expect(t.widget<WordGameLayout>(find.byType(WordGameLayout)).word,
        isNot('FAN'));
    expect((p.xp, p.stars), (0, 0));
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  for (final interrupt in ['background', 'route', 'dispose']) {
    testWidgets(
        '$interrupt during completed word cannot advance or speak offscreen',
        (t) async {
      SharedPreferences.setMockInitialValues(
          soundTestPreferences(firstWord: 'FAN'));
      final audio = QuizAudioHarness()..install();
      final p = await mount(t, const MissingVowelScreen());
      await audio.finishGameIntro(t, 'missing_vowel.mp3');
      await waitFor(t, () => audio.starts.isNotEmpty);
      final choice = find
          .byWidgetPredicate((w) => w is GameAnswerButton && w.label == 'A');
      await t.tap(
          find.descendant(of: choice, matching: find.byType(ElevatedButton)));
      await t.pump();
      await t.pump();
      await waitFor(t, () => audio.starts.last.endsWith('/game_words/fan.mp3'));
      final navigator =
          Navigator.of(t.element(find.byType(MissingVowelScreen)));
      if (interrupt == 'background') {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      } else if (interrupt == 'route') {
        navigator.push<void>(MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Covered'))));
      } else {
        await t.pumpWidget(const SizedBox());
      }
      await t.pump(const Duration(seconds: 2));
      await drain(t);
      final count = audio.starts.length;
      await t.pump(const Duration(seconds: 2));
      expect(audio.starts.length, count);
      if (interrupt != 'dispose') {
        if (interrupt == 'background') {
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        } else {
          navigator.pop();
        }
        await t.pump(const Duration(milliseconds: 400));
        await waitFor(t, () => audio.starts.length > count);
        expect(audio.starts.last, endsWith('/game_words/fan.mp3'));
        expect(
            t.widget<WordGameLayout>(find.byType(WordGameLayout)).word, 'FAN');
        await t.runAsync(() => audio.completeSource('/game_words/fan.mp3'));
        await drain(t);
        await t.pump(const Duration(milliseconds: 800));
        await drain(t);
        expect(t.widget<WordGameLayout>(find.byType(WordGameLayout)).word,
            isNot('FAN'));
      }
      expect((p.xp, p.stars), (8, 0));
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  for (final difficulty in Difficulty.values) {
    testWidgets(
        '${difficulty.name}: intro, actual audio completion, glow and repeat stay synchronized',
        (t) async {
      final audio = QuizAudioHarness()..install();
      final p = await mount(t, MissingVowelScreen(difficulty: difficulty));
      final word = t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
      final steps = missingVowelSoundSteps(word);
      const intro = '/game_instructions/missing_vowel.mp3';
      await waitFor(t, () => audio.starts.any((s) => s.endsWith(intro)));
      expect(glowing(t, word.length), isEmpty);
      await t.pump(const Duration(seconds: 4));
      expect(audio.starts, hasLength(1),
          reason: 'The sound cue waits for the actual intro completion');
      await t.runAsync(() => audio.completeSource(intro));

      Future<void> finishSequence(int startCount) async {
        for (var i = 0; i < steps.length; i++) {
          final suffix =
              '/${PhonicsAudioService.assetForPhrase(steps[i].phrase)}';
          await waitFor(t, () => audio.starts.length >= startCount + i + 1);
          expect(audio.starts.last, endsWith(suffix));
          await t.pump(const Duration(milliseconds: 160));
          expect(glowing(t, word.length), steps[i].positions.toSet());
          final count = audio.starts.length;
          await t.pump(const Duration(seconds: 2));
          expect(audio.starts.length, count,
              reason: 'A delay cannot advance an unfinished recording');
          if (steps[i].positions.length == 1 &&
              word[steps[i].positions.single] ==
                  RegExp('[AEIOU]').firstMatch(word)!.group(0)) {
            final slot = steps[i].positions.single;
            final text = find.descendant(
                of: find.byKey(ValueKey('vowel-sound-$slot')),
                matching: find.byType(Text));
            // Only the first vowel is blanked by the existing puzzle data.
            if (slot == word.indexOf(RegExp('[AEIOU]'))) {
              expect(t.widget<Text>(text).data, '_');
            }
          }
          await t.runAsync(() => audio.completeSource(suffix));
          await drain(t);
          await t.pump(const Duration(milliseconds: 350));
        }
        await drain(t);
        expect(glowing(t, word.length), isEmpty);
      }

      await finishSequence(1);
      expect((p.xp, p.stars), (0, 0),
          reason: 'Hearing or replaying sounds never scores an answer');
      final again = find.widgetWithText(OutlinedButton, 'Listen Again');
      expect(t.widget<OutlinedButton>(again).onPressed, isNotNull);
      final count = audio.starts.length;
      await t.tap(again);
      await t.pump();
      expect(t.widget<OutlinedButton>(again).onPressed, isNull);
      await finishSequence(count);
      expect((p.xp, p.stars), (0, 0));

      final vowel = word[word.indexOf(RegExp('[AEIOU]'))];
      final choice = find
          .byWidgetPredicate((w) => w is GameAnswerButton && w.label == vowel);
      await t.tap(
          find.descendant(of: choice, matching: find.byType(ElevatedButton)));
      await t.pump(const Duration(milliseconds: 710));
      await flushWrites(t);
      expect(p.stars, 0);
      expect(p.xp, (8 * difficulty.xpMultiplier).round());
      final completedWord = '/${PhonicsAudioService.assetForPhrase(word)}';
      await waitFor(t, () => audio.starts.last.endsWith(completedWord));
      final starts = audio.starts.length;
      expect(
          t.widget<Text>(find.byKey(const ValueKey('vowel-blank-letter'))).data,
          vowel);
      expect(t.widget<OutlinedButton>(again).onPressed, isNull);
      await t.pump(const Duration(seconds: 3));
      expect(audio.starts.length, starts,
          reason: 'The completed word finishes before advancing');
      expect(t.widget<WordGameLayout>(find.byType(WordGameLayout)).word, word);
      await t.runAsync(() => audio.completeSource(completedWord));
      await drain(t);
      await t.pump(const Duration(milliseconds: 800));
      await t.pump();
      await waitFor(t, () => audio.starts.length > starts);
      final nextWord =
          t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
      final first = missingVowelSoundSteps(nextWord).first;
      expect(audio.starts.last,
          endsWith('/${PhonicsAudioService.assetForPhrase(first.phrase)}'));
      expect(audio.starts.where((s) => s.endsWith(intro)), hasLength(1));
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets(
      'backgrounding stops the cue and returning replays its interrupted step',
      (t) async {
    final audio = QuizAudioHarness()..install();
    final p = await mount(t, const MissingVowelScreen());
    const intro = '/game_instructions/missing_vowel.mp3';
    await waitFor(t, () => audio.starts.any((s) => s.endsWith(intro)));
    await t.runAsync(() => audio.completeSource(intro));
    await waitFor(t, () => audio.starts.length >= 2);
    final interrupted = audio.starts.last;
    final word = t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(seconds: 2));
    expect(glowing(t, word.length), isEmpty);
    final count = audio.starts.length;
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await waitFor(t, () => audio.starts.length > count);
    expect(audio.starts.last, interrupted);
    expect((p.xp, p.stars), (0, 0));
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  for (final difficulty in Difficulty.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
          '${difficulty.name}: all vowels and repeat fit a small screen at text $scale',
          (t) async {
        await t.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => t.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
        final p = await mount(
            t,
            MediaQuery(
                data: MediaQueryData(
                    size: const Size(320, 568),
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true),
                child: MissingVowelScreen(difficulty: difficulty)));
        await t.pumpAndSettle();
        expect(
            t
                .widgetList<GameAnswerButton>(find.byType(GameAnswerButton))
                .map((w) => w.label),
            ['A', 'E', 'I', 'O', 'U']);
        for (final button in find.byType(GameAnswerButton).evaluate()) {
          final rect = t.getRect(find.byWidget(button.widget));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
          expect(rect.bottom, lessThanOrEqualTo(568));
        }
        expect(
            t
                .widget<ForestAudioButton>(find.byType(ForestAudioButton))
                .onPressed,
            isNull);
        expect(find.byType(Scrollable), findsNothing);
        expect(t.takeException(), isNull);
        await close(t, p);
      });
    }
  }
}
