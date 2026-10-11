import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/phonics_activity_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/word_builder_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'quiz_audio_harness.dart';

WordPuzzle puzzle(WidgetTester t, Difficulty difficulty) =>
    wordPuzzlesForDifficulty(difficulty).firstWhere((p) =>
        p.word ==
        t.widget<AudioButton>(find.byType(AudioButton)).phrase.toUpperCase());

String slot(WidgetTester t, int index) => t
    .widget<Text>(find.descendant(
        of: find.byKey(ValueKey('builder-blank-$index')),
        matching: find.byType(Text)))
    .data!;

Future<void> flushAudio(WidgetTester t) async {
  for (var i = 0; i < 30; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await t.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });
  testWidgets('wrong and correct options finish phonemes before feedback',
      (t) async {
    final audio = QuizAudioHarness()..install();
    final p =
        await mount(t, const WordBuilderScreen(difficulty: Difficulty.easy));
    await t.runAsync(() => p.toggleSfx());
    await t.pump();
    final task = puzzle(t, Difficulty.easy);
    final wrong = task.tiles.firstWhere((l) => l != task.correctLetters.first);
    await t.tap(find.byKey(ValueKey('builder-choice-$wrong')));
    await t.pump();
    await flushAudio(t);
    expect(audio.starts.last,
        endsWith('/sounds/sound-${wrong.toLowerCase()}.mp3'));
    expect(find.byKey(const ValueKey('flying-builder-letter')), findsNothing);
    expect(slot(t, 0), '_');
    expect(t.widget<AudioButton>(find.byType(AudioButton)).enabled, isFalse);
    await t.runAsync(() => audio.completeSound(wrong));
    await flushAudio(t);
    await t.pump(const Duration(milliseconds: 350));
    final answer = task.correctLetters.first;
    await t.tap(find.byKey(ValueKey('builder-choice-$answer')));
    await t.pump();
    await flushAudio(t);
    expect(audio.starts.last,
        endsWith('/sounds/sound-${answer.toLowerCase()}.mp3'));
    await t.pump(const Duration(milliseconds: 600));
    expect(slot(t, 0), answer);
    expect(p.stars, 0);
    expect(audio.sources.where((s) => s.contains('/praise-')), isEmpty);
    await t.pump(const Duration(seconds: 2));
    expect(puzzle(t, Difficulty.easy).word, task.word);
    await t.runAsync(() => audio.completeSound(answer));
    await flushAudio(t);
    expect(p.stars, 1);
    expect(audio.sources.where((s) => s.contains('/praise-')), isEmpty);
    expect(audio.sources.where((s) => s.contains('/game_narration/')), isEmpty);
    await t.pump(const Duration(milliseconds: 1100));
    expect(puzzle(t, Difficulty.easy).word, isNot(task.word));
    await close(t, p);
  });
}
