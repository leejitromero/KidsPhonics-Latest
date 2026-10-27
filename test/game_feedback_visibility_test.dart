import 'phonics_quiz_test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/screens/sound_match_screen.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/screens/word_builder_screen.dart';
import 'package:kidsphonics/data/phonics_activity_data.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';
import 'package:kidsphonics/widgets/sound_match_design.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });
  for (final covered in ['dialog', 'background']) {
    testWidgets('Word Builder preserves its completed task during $covered',
        (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final p =
          await mount(t, const WordBuilderScreen(difficulty: Difficulty.easy));
      await t.runAsync(() async {
        await p.toggleVoice();
        await p.toggleSfx();
      });
      await t.pump();
      final word = t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
      final puzzle = wordPuzzlesForDifficulty(Difficulty.easy)
          .firstWhere((puzzle) => puzzle.word == word);
      t
          .widget<GameAnswerButton>(find.byWidgetPredicate((w) =>
              w is GameAnswerButton && w.label == puzzle.correctLetters.first))
          .onPressed!();
      await t.pump();
      if (covered == 'dialog') {
        await t.tap(find.byTooltip('Back'));
        await t.pump(const Duration(milliseconds: 300));
        expect(find.text('Leave this game?'), findsOneWidget);
      } else {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      }
      await t.pump(const Duration(seconds: 2));
      expect(
          t
              .widget<WordGameLayout>(
                  find.byType(WordGameLayout, skipOffstage: false))
              .word,
          word);
      if (covered == 'dialog') {
        await t.tap(find.text('Cancel'));
      } else {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      }
      await t.pump(const Duration(milliseconds: 500));
      await t.pump(const Duration(milliseconds: 300));
      expect(t.widget<WordGameLayout>(find.byType(WordGameLayout)).word,
          isNot(word));
      await close(t, p);
    });
    testWidgets('Sound Match preserves its current task during $covered',
        (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final p =
          await mount(t, const SoundMatchScreen(difficulty: Difficulty.easy));
      await t.runAsync(() => p.toggleSfx());
      await t.pump();
      final phrase =
          t.widget<SoundMatchLayout>(find.byType(SoundMatchLayout)).phrase;
      final answer =
          letterChoiceLabel(phrase.replaceFirst('lesson-sound-', ''));
      final wrong = t
          .widgetList<GameAnswerButton>(find.byType(GameAnswerButton))
          .firstWhere((w) => w.label != answer)
          .label;
      t
          .widget<GameAnswerButton>(find.byWidgetPredicate(
              (w) => w is GameAnswerButton && w.label == wrong))
          .onPressed!();
      await t.pump();
      if (covered == 'dialog') {
        await t.tap(find.byTooltip('Back'));
        await t.pump(const Duration(milliseconds: 300));
        expect(find.text('Leave this game?'), findsOneWidget);
      } else {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      }
      await t.pump(const Duration(seconds: 2));
      expect(
          t
              .widget<SoundMatchLayout>(
                  find.byType(SoundMatchLayout, skipOffstage: false))
              .phrase,
          phrase);
      if (covered == 'dialog') {
        await t.tap(find.text('Cancel'));
      } else {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      }
      await t.pump(const Duration(milliseconds: 500));
      await t.pump(const Duration(milliseconds: 300));
      expect(t.widget<SoundMatchLayout>(find.byType(SoundMatchLayout)).phrase,
          phrase);
      expect(find.text('Try Again!'), findsOneWidget);
      t
          .widget<GameAnswerButton>(find.byWidgetPredicate(
              (w) => w is GameAnswerButton && w.label == answer))
          .onPressed!();
      await t.pump(const Duration(milliseconds: 1500));
      expect(t.widget<SoundMatchLayout>(find.byType(SoundMatchLayout)).phrase,
          isNot(phrase));
      await close(t, p);
    });
  }
  testWidgets('Phonics Quiz preserves the answer while the app is backgrounded',
      (t) async {
    final p =
        await mount(t, const PhonicsQuizScreen(difficulty: Difficulty.easy));
    await t.runAsync(() async {
      await p.toggleVoice();
      await p.toggleSfx();
    });
    await t.pump();
    final word = t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
    final answer = quizQuestionsForDifficulty(Difficulty.easy)
        .firstWhere((q) => q.word.toUpperCase() == word.toUpperCase())
        .correctLetter;
    t
        .widget<GameAnswerButton>(find.byWidgetPredicate((w) =>
            w is GameAnswerButton && w.label == letterChoiceLabel(answer)))
        .onPressed!();
    await submitQuiz(t);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(seconds: 2));
    expect(t.widget<WordGameLayout>(find.byType(WordGameLayout)).word, word);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await finishMutedQuizFeedback(t);
    expect(t.widget<WordGameLayout>(find.byType(WordGameLayout)).word,
        isNot(word));
    await close(t, p);
  });
}
