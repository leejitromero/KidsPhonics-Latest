import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/controllers/game_narration_controller.dart';
import 'package:kidsphonics/widgets/game_mascot_coach.dart';

import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'quiz_audio_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'quiz plays wrong and correct letter sounds before answer feedback',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    final audio = QuizAudioHarness()..install();
    final p =
        await mount(t, const PhonicsQuizScreen(difficulty: Difficulty.easy));
    await t.runAsync(() => p.toggleSfx());
    await t.pump();
    final word = t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
    final question = quizQuestionsForDifficulty(Difficulty.easy)
        .firstWhere((q) => q.word.toUpperCase() == word.toUpperCase());
    final answer = question.correctLetter;
    final wrong = question.options.firstWhere((l) => l != answer);
    final wrongChoice = t.widget<GameAnswerButton>(find.byWidgetPredicate(
        (w) => w is GameAnswerButton && w.label == letterChoiceLabel(wrong)));
    wrongChoice.onPressed!();
    await t.pump();
    final controller =
        t.widget<GameMascotCoach>(find.byType(GameMascotCoach)).controller;
    for (var i = 0;
        i < 40 &&
            !audio.starts.any(
                (s) => s.endsWith('/sounds/sound-${wrong.toLowerCase()}.mp3'));
        i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    expect(audio.starts.last,
        endsWith('/sounds/sound-${wrong.toLowerCase()}.mp3'));
    await t.pump(const Duration(seconds: 1));
    expect(t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult,
        isFalse);
    expect(p.stars, 0);
    await t.runAsync(() => audio.completeSound(wrong));
    for (var i = 0; i < 30 && controller.feedback != null; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    await t.pump(const Duration(milliseconds: 800));
    expect(t.widget<WordGameLayout>(find.byType(WordGameLayout)).word, word);
    expect(
        t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult, isNull);
    final choice = t.widget<GameAnswerButton>(find.byWidgetPredicate(
        (w) => w is GameAnswerButton && w.label == letterChoiceLabel(answer)));
    choice.onPressed!();
    await t.pump();
    final coach = t.widget<GameMascotCoach>(find.byType(GameMascotCoach));
    expect(coach.controller.feedback, '${letterChoiceLabel(answer)} sound');
    for (var i = 0;
        i < 40 &&
            !audio.starts.any(
                (s) => s.endsWith('/sounds/sound-${answer.toLowerCase()}.mp3'));
        i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    expect(audio.sources.last,
        endsWith('/sounds/sound-${answer.toLowerCase()}.mp3'));
    expect(audio.sources.where((s) => s.contains('/praise-')), isEmpty);
    await t.pump(const Duration(seconds: 2));
    expect(t.widget<WordGameLayout>(find.byType(WordGameLayout)).word, word);
    await t.runAsync(() => audio.completeSound(answer));
    for (var i = 0; i < 30 && coach.controller.feedback != null; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    expect(coach.controller.feedback, isNull);
    expect(coach.controller.speaking, isFalse);
    expect(audio.sources.where((s) => s.contains('/game_narration/')), isEmpty);
    expect(
        t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult, isTrue);
    await t.pump(const Duration(milliseconds: 1500));
    await close(t, p);
  });
  testWidgets(
      'coach stays silent on entry and cancels letter audio on mute and route coverage',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    final played = <String>[];
    final pending = <Completer<bool>>[];
    final controller = GameNarrationController(
      play: (phrase) {
        played.add(phrase);
        final c = Completer<bool>();
        pending.add(c);
        return c.future;
      },
      stop: () async {
        for (final c in pending) {
          if (!c.isCompleted) c.complete(false);
        }
      },
    );
    final p = await mount(
        t,
        Scaffold(
            body: GameMascotCoach(
          title: 'Phonics Quiz',
          instructions: 'Listen and pick the letters.',
          controller: controller,
        )));
    expect(played, isEmpty);
    expect(find.byTooltip('Stop instructions'), findsNothing);
    expect(find.byTooltip('Hear Instructions'), findsNothing);
    unawaited(controller.letterSound('A'));
    await t.pump();
    expect(played, ['lesson-sound-A']);
    await t.runAsync(() => p.toggleVoice());
    await t.pumpAndSettle();
    expect(controller.speaking, isFalse);
    await controller.letterSound('B');
    expect(played, hasLength(1));
    await t.runAsync(() => p.toggleVoice());
    await t.pumpAndSettle();
    expect(played, hasLength(1));
    unawaited(controller.letterSound('B'));
    await t.pump();
    final context = t.element(find.byType(GameMascotCoach));
    unawaited(showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(title: Text('Help'))));
    await t.pumpAndSettle();
    expect(controller.speaking, isFalse);
    expect(find.text('Help'), findsOneWidget);
    Navigator.of(context).pop();
    await t.pumpAndSettle();
    expect(played, hasLength(2),
        reason: 'Resume does not start generated speech');
    unawaited(controller.letterSound('C'));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await t.pump();
    expect(controller.speaking, isFalse);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(played, hasLength(3));
    await close(t, p);
    controller.dispose();
  });
}
