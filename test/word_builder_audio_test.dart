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
  testWidgets(
      'a wrong letter fills the blank and scores once without corrective audio',
      (t) async {
    final audio = QuizAudioHarness()..install();
    final p =
        await mount(t, const WordBuilderScreen(difficulty: Difficulty.easy));
    await t.runAsync(() => p.toggleSfx());
    await t.pump();
    final task = puzzle(t, Difficulty.easy);
    final wrong = task.tiles.firstWhere((l) => l != task.correctLetters.first);
    final choice = t.widget<GameAnswerButton>(find
        .byWidgetPredicate((w) => w is GameAnswerButton && w.label == wrong)
        .first);
    await t.tap(find.byKey(choice.buttonKey!));
    await t.pump();
    await flushAudio(t);
    expect(
        audio.starts.where((s) => !s.contains('/game_instructions/')), isEmpty,
        reason: 'Choices do not reveal correctness through audio');
    await t.pump(const Duration(milliseconds: 600));
    expect(slot(t, 0), wrong);
    expect(p.stars, 0);
    expect(p.xp, 0);
    final state = t.state<GameSessionUi>(find.byType(WordBuilderScreen));
    expect((state.scoredAttempts, state.correctAttempts), (1, 0));
    expect(find.text('Answer saved!'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 700));
    expect(puzzle(t, Difficulty.easy).word, isNot(task.word));
    expect(audio.sources.where((s) => s.contains('/praise-')), isEmpty);
    await close(t, p);
  });
}
