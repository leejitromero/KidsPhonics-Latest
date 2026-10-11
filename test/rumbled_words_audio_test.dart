import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'quiz_audio_harness.dart';

String shownWord(WidgetTester t) =>
    t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;

Future<void> audioStarted(
    WidgetTester t, QuizAudioHarness audio, int count) async {
  for (var i = 0; i < 80 && audio.starts.length < count; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await t.pump();
  }
  final state = t.state<GameSessionUi>(find.byType(RumbledWordsScreen));
  expect(audio.starts.length, count,
      reason:
          'sources=${audio.sources}, active=${state.canAdvanceGameFeedback}, '
          'enabled=${state.gameNarration.enabled}, '
          'feedback=${state.gameNarration.feedback}, '
          'lifecycle=${t.binding.lifecycleState}');
}

Future<void> flushAudio(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await t.pump();
  }
}

List<String> options(WidgetTester t, int length) => [
      for (var i = 0; i < length; i++)
        t
            .widget<Text>(find.descendant(
                of: find.byKey(ValueKey('word-tile-$i')),
                matching: find.byType(Text)))
            .data!
    ];

bool highlighted(WidgetTester t, int slot) {
  final box =
      t.widget<AnimatedContainer>(find.byKey(ValueKey('word-highlight-$slot')));
  return (box.decoration! as BoxDecoration).color == const Color(0xFFFFE36B);
}

Future<void> spell(WidgetTester t, QuizAudioHarness audio, String word) async {
  final tiles = options(t, word.length);
  final used = <int>{};
  for (var slot = 0; slot < word.length; slot++) {
    final index = List.generate(tiles.length, (i) => i)
        .firstWhere((i) => !used.contains(i) && tiles[i] == word[slot]);
    used.add(index);
    final starts = audio.starts.length;
    t
        .widget<ElevatedButton>(find.byKey(ValueKey('word-tile-$index')))
        .onPressed!();
    await t.pump();
    await audioStarted(t, audio, starts + 1);
    expect(audio.starts.last,
        endsWith('/sounds/sound-${word[slot].toLowerCase()}.mp3'));
    if (slot < word.length - 1) {
      await t.runAsync(() => audio.completeSound(word[slot]));
      await flushAudio(t);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });

  testWidgets(
      'options sound, each letter highlights, word finishes before next',
      (t) async {
    final audio = QuizAudioHarness()..install();
    final p = await mount(t, const RumbledWordsScreen());
    await t.runAsync(() => p.toggleSfx());
    await t.pump();
    final task = shownWord(t);
    final word = task.toUpperCase();
    await spell(t, audio, word);
    expect(find.text('Correct!'), findsOneWidget);
    expect(find.text('Check'), findsNothing);
    expect(find.text('Next'), findsNothing);
    expect(t.widget<AudioButton>(find.byType(AudioButton)).enabled, isFalse);
    expect(
        t
            .widget<OutlinedButton>(find.byKey(const ValueKey('word-erase')))
            .onPressed,
        isNull);
    // The final option must finish before the completed-word sequence starts.
    await t.pump(const Duration(seconds: 2));
    expect(audio.starts.length, word.length);
    await t.runAsync(() => audio.completeSound(word[word.length - 1]));
    for (var slot = 0; slot < word.length; slot++) {
      await audioStarted(t, audio, word.length + slot + 1);
      expect(audio.starts.last,
          endsWith('/sounds/sound-${word[slot].toLowerCase()}.mp3'));
      for (var i = 0; i < word.length; i++) {
        expect(highlighted(t, i), i == slot);
      }
      await t.pump(const Duration(seconds: 2));
      expect(shownWord(t), task);
      await t.runAsync(() => audio.completeSound(word[slot]));
    }
    await audioStarted(t, audio, word.length * 2 + 1);
    final asset = PhonicsAudioService.assetForPhrase(task)!;
    expect(audio.starts.last, endsWith('/$asset'));
    for (var slot = 0; slot < word.length; slot++) {
      expect(highlighted(t, slot), isTrue);
    }
    await t.pump(const Duration(seconds: 2));
    expect(shownWord(t), task);
    await t.runAsync(() => audio.completeSource('/$asset'));
    await flushAudio(t);
    expect(shownWord(t), isNot(task));
    await t.runAsync(() async {
      final state = t.state<GameSessionUi>(find.byType(RumbledWordsScreen));
      await state.rewardsSaved;
    });
    expect(p.stars, 1);
    expect(audio.sources.where((s) => s.contains('/game_narration/')), isEmpty);
    await close(t, p);
    p.phonicsAudio.dispose();
    await flushAudio(t);
    expect(t.takeException(), isNull);
  });
}
