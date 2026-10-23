import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/missing_vowel_sounds.dart';
import 'package:kidsphonics/data/phonics_activity_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/missing_vowel_screen.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({'sfx': false});
    mockProgressAudio();
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });

  test('all difficulties show all five vowels exactly once', () {
    for (final difficulty in Difficulty.values) {
      for (final vowel in 'AEIOU'.split('')) {
        expect(vowelChoicesFor(difficulty, vowel), ['A', 'E', 'I', 'O', 'U']);
      }
    }
  });

  test('TUB sounds its consonants and missing short vowel before the word', () {
    final steps = missingVowelSoundSteps('TUB');
    expect(steps.map((s) => s.phrase),
        ['lesson-sound-T', 'lesson-sound-U', 'lesson-sound-B', 'TUB']);
    expect(steps.map((s) => s.positions), [
      [0],
      [1],
      [2],
      [0, 1, 2]
    ]);
  });

  test('word-specific vowel groups and silent letters use matching recordings',
      () {
    final goat = missingVowelSoundSteps('GOAT');
    expect(goat[1].phrase, 'lesson-letter-O');
    expect(goat[1].positions, [1, 2]);
    final rose = missingVowelSoundSteps('ROSE');
    expect(rose.map((s) => s.phrase),
        ['lesson-sound-R', 'lesson-letter-O', 'lesson-sound-Z', 'ROSE']);
    expect(rose[1].positions, [1, 3]);
    final lamb = missingVowelSoundSteps('LAMB');
    expect(lamb.map((s) => s.phrase), isNot(contains('lesson-sound-B')));
    for (final word in ['MOON', 'SHEEP']) {
      final steps = missingVowelSoundSteps(word);
      expect(steps, hasLength(1));
      expect(steps.single.phrase, word);
      expect(steps.single.positions, List.generate(word.length, (i) => i));
    }
    for (final difficulty in Difficulty.values) {
      for (final puzzle in vowelPuzzlesFor(difficulty)) {
        final steps = missingVowelSoundSteps(puzzle.word);
        expect(steps.last.phrase, puzzle.word);
        for (final step in steps) {
          expect(step.positions, isNotEmpty);
          expect(step.positions.every((i) => i >= 0 && i < puzzle.word.length),
              isTrue);
          final asset = PhonicsAudioService.assetForPhrase(step.phrase);
          expect(asset, isNotNull, reason: step.phrase);
          expect(File('assets/$asset').existsSync(), isTrue,
              reason: step.phrase);
        }
      }
    }
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
    expect(audio.starts.length, before);
    expect(glowing(t, word.length), isEmpty);
    expect((p.xp, p.stars), (8, 1));
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
      expect(p.stars, 1);
      expect(p.xp, (8 * difficulty.xpMultiplier).round());
      final starts = audio.starts.length;
      await t.tap(find.widgetWithText(ElevatedButton, 'Next'));
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
