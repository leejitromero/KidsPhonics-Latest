import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/controllers/game_narration_controller.dart';
import 'package:kidsphonics/widgets/game_mascot_coach.dart';

import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'quiz_audio_harness.dart';
import 'phonics_quiz_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'quiz intro, word, question, previews and feedback share one audio channel',
      (t) async {
    SharedPreferences.setMockInitialValues({'voice': true, 'sfx': false});
    mockProgressAudio();
    final audio = QuizAudioHarness()..install();
    final p =
        await mount(t, const PhonicsQuizScreen(difficulty: Difficulty.easy));
    Future<void> waitStarts(int count) async {
      for (var i = 0; i < 100 && audio.starts.length < count; i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await t.pump();
      }
      expect(audio.starts, hasLength(count));
    }

    final q = shownQuiz(t);
    await waitStarts(1);
    expect(audio.starts.last, endsWith('/game_instructions/phonics_quiz.mp3'));
    await t.runAsync(
        () => audio.completeSource('/game_instructions/phonics_quiz.mp3'));
    await waitStarts(2);
    expect(audio.starts.last,
        endsWith('/cvc_lesson/word-${q.word.toLowerCase()}.mp3'));
    await t.runAsync(() =>
        audio.completeSource('/cvc_lesson/word-${q.word.toLowerCase()}.mp3'));
    await waitStarts(3);
    expect(
        audio.starts.last, endsWith('/game_instructions/quiz_beginning.mp3'));
    await t.runAsync(
        () => audio.completeSource('/game_instructions/quiz_beginning.mp3'));
    final wrong = q.options.firstWhere((letter) => letter != q.correctLetter);
    await t.tap(find.byKey(ValueKey('quiz-sound-$wrong')));
    await waitStarts(4);
    expect(audio.starts.last,
        endsWith('/sounds/sound-${wrong.toLowerCase()}.mp3'));
    await t.runAsync(() => audio.completeSound(wrong));
    await selectQuiz(t, wrong);
    expect(
        t.state<GameSessionUi>(find.byType(PhonicsQuizScreen)).scoredAttempts,
        0);
    expect(
        t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult, isNull);
    await submitQuiz(t);
    await waitStarts(5);
    expect(t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult,
        isFalse);
    expect(audio.starts.last,
        endsWith('/cvc_lesson/word-${q.word.toLowerCase()}.mp3'));
    await t.pump(const Duration(seconds: 2));
    expect(shownQuiz(t).id, q.id);
    await t.runAsync(() =>
        audio.completeSource('/cvc_lesson/word-${q.word.toLowerCase()}.mp3'));
    await waitStarts(6);
    expect(audio.starts.last,
        endsWith('/sounds/sound-${q.correctLetter.toLowerCase()}.mp3'));
    await t.pump(const Duration(seconds: 2));
    expect(shownQuiz(t).id, q.id);
    await t.runAsync(() => audio.completeSound(q.correctLetter));
    for (var i = 0; i < 12; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    await t.pump(const Duration(milliseconds: 850));
    expect(shownQuiz(t).word, isNot(q.word));
    expect(p.stars, 0);
    expect(audio.sources.where((s) => s.contains('/praise-')), isEmpty);
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
