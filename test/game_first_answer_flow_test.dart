import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/sound_match_screen.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/screens/missing_vowel_screen.dart';
import 'package:kidsphonics/screens/picture_word_match_screen.dart';
import 'package:kidsphonics/screens/word_builder_screen.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'package:kidsphonics/screens/alphabet_order_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/sound_match_design.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';
import 'package:kidsphonics/data/phonics_activity_data.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'phonics_quiz_test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(TestWidgetsFlutterBinding
        .instance.platformDispatcher.clearAccessibilityFeaturesTestValue);
  });
  Future<void> settleRound(WidgetTester t, {bool quiz = false}) async {
    for (var i = 0; i < (quiz ? 30 : 20); i++) {
      await t.pump(const Duration(milliseconds: 100));
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    await t.pump();
  }

  Future<void> pick(WidgetTester t, String label) async {
    final target = find
        .byWidgetPredicate((w) => w is GameAnswerButton && w.label == label);
    await t.ensureVisible(target);
    await t.tap(
        find.descendant(of: target, matching: find.byType(ElevatedButton)));
    await t.pump();
  }

  final pages = <String, Widget>{
    'Sound Match': const SoundMatchScreen(difficulty: Difficulty.easy),
    'Phonics Quiz': const PhonicsQuizScreen(difficulty: Difficulty.easy),
    'Missing Vowel': const MissingVowelScreen(difficulty: Difficulty.easy),
    'Picture Match': const PictureWordMatchScreen(difficulty: Difficulty.easy),
    'Word Builder': const WordBuilderScreen(difficulty: Difficulty.easy),
    'Rumbled Words': const RumbledWordsScreen(difficulty: Difficulty.easy),
    'Alphabet Order': const AlphabetOrderScreen(difficulty: Difficulty.easy),
  };
  for (final entry in pages.entries) {
    testWidgets(
        '${entry.key}: wrong first answers advance and appear only in result review',
        (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final p = await mount(t, entry.value);
      final session =
          t.state<GameSessionUi>(find.byType(entry.value.runtimeType));
      final total = session.totalGameItems;
      for (var i = 0; i < total; i++) {
        expect(find.byType(GameResultDialog), findsNothing);
        switch (entry.key) {
          case 'Sound Match':
            final sound =
                t.widget<SoundMatchLayout>(find.byType(SoundMatchLayout));
            final correct = sound.phrase.split('-').last;
            final options =
                t.widgetList<GameAnswerButton>(find.byType(GameAnswerButton));
            await pick(
                t,
                options
                    .firstWhere(
                        (b) => b.label != correct && b.onPressed != null)
                    .label);
          case 'Phonics Quiz':
            final question = shownQuiz(t);
            await selectQuiz(
                t,
                question.options
                    .firstWhere((l) => l != question.correctLetter));
            expect(find.text(question.explanation), findsNothing);
          case 'Missing Vowel':
            final word =
                t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
            final question = vowelPuzzlesFor(Difficulty.easy)
                .firstWhere((p) => p.word == word);
            await pick(
                t,
                ['A', 'E', 'I', 'O', 'U']
                    .firstWhere((v) => v != question.vowel));
          case 'Picture Match':
            final word = t
                .widget<AudioButton>(find.byType(AudioButton))
                .phrase
                .toUpperCase();
            final question = pictureRoundsFor(Difficulty.easy)
                .firstWhere((p) => p.word == word);
            final wrong =
                question.options.indexWhere((o) => o != question.correctEmoji);
            await pick(t, 'Picture ${wrong + 1}');
          case 'Word Builder':
            final word =
                t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
            final question = wordPuzzlesForDifficulty(Difficulty.easy)
                .firstWhere((p) => p.word == word);
            await pick(
                t,
                question.tiles
                    .firstWhere((l) => l != question.correctLetters.first));
          case 'Rumbled Words':
            await t.tap(find.byKey(const ValueKey('word-check')));
            await t.pump();
          case 'Alphabet Order':
            final expected = String.fromCharCode(65 + i);
            final options =
                t.widgetList<GameAnswerButton>(find.byType(GameAnswerButton));
            final available = options
                .where((b) => b.onPressed != null && b.label != expected);
            // The final remaining letter has no distractor; its correct answer is valid.
            await pick(t, available.isEmpty ? expected : available.first.label);
        }
        expect(session.scoredAttempts, i + 1,
            reason: 'Exactly one scored submission per task');
        expect(t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult,
            entry.key == 'Alphabet Order' && i == total - 1 ? isTrue : isFalse);
        expect(p.stars, 0,
            reason: 'Stars are awarded only after the entire round');
        await settleRound(t, quiz: entry.key == 'Phonics Quiz');
      }
      await settleRound(t, quiz: entry.key == 'Phonics Quiz');
      final result = t.widget<GameResultDialog>(find.byType(GameResultDialog));
      final expectedCorrect = entry.key == 'Alphabet Order' ? 1 : 0;
      expect(
          (result.correctItems, result.totalItems), (expectedCorrect, total));
      expect(result.answers, hasLength(total));
      expect(result.answers.where((a) => !a.correct),
          hasLength(total - expectedCorrect));
      expect(p.stars, 1);
      expect(p.dailyActivity.values.single.questionsAnswered, total);
      expect(p.overallMasteredCount, 0);
      expect(p.smartReviewSuggestions, isNotEmpty,
          reason: 'First-answer mistakes must inform unscored Smart Review');
      expect(find.text('Review Answers'), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }
}
