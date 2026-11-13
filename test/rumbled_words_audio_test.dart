import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'quiz_audio_harness.dart';
import 'rumbled_words_swap_helpers.dart';

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

bool highlighted(WidgetTester t, int slot) {
  final box =
      t.widget<AnimatedContainer>(find.byKey(ValueKey('word-highlight-$slot')));
  return (box.decoration! as BoxDecoration).color == const Color(0xFFFFE36B);
}

Future<int> spell(WidgetTester t, QuizAudioHarness audio, String word) async {
  var count = audio.starts.length;
  await arrangeBoard(t, word, afterTap: (letter) async {
    await audioStarted(t, audio, ++count);
    expect(audio.starts.last,
        endsWith('/letters/letter-${letter.toLowerCase()}.mp3'));
    await t.runAsync(() => audio.completeLetterName(letter));
    await flushAudio(t);
  });
  expect(find.text('Correct!'), findsNothing);
  expect(t.state<GameSessionUi>(find.byType(RumbledWordsScreen)).scoredAttempts,
      0);
  t
      .widget<OutlinedButton>(find.byKey(const ValueKey('word-check')))
      .onPressed!();
  await t.pump();
  return count;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });

  testWidgets(
      'letter previews share one channel and submission advances without revealing correction',
      (t) async {
    final audio = QuizAudioHarness()..install();
    final p = await mount(t, const RumbledWordsScreen());
    await flushAudio(t);
    expect(audio.starts, isEmpty);
    await t.runAsync(() => p.toggleSfx());
    await t.pump();
    final task = shownWord(t);
    final word = task.toUpperCase();
    final selectionCount = await spell(t, audio, word);
    expect(find.text('Answer saved!'), findsOneWidget);
    expect(find.text('Correct!'), findsNothing);
    expect(
        t
            .widget<OutlinedButton>(find.byKey(const ValueKey('word-check')))
            .onPressed,
        isNull);
    await flushAudio(t);
    expect(audio.starts.length, selectionCount,
        reason: 'Correction audio is deferred until result review');
    await t.pump(const Duration(milliseconds: 700));
    expect(shownWord(t), isNot(task));
    expect(p.stars, 0);
    expect(audio.sources.where((s) => s.contains('/game_narration/')), isEmpty);
    await close(t, p);
    p.phonicsAudio.dispose();
    await flushAudio(t);
    expect(t.takeException(), isNull);
  });
}
