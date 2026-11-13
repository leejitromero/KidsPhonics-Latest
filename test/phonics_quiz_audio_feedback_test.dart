import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/phonics_quiz_design.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;
import 'phonics_quiz_test_helpers.dart';
import 'quiz_audio_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late QuizAudioHarness audio;
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': true, 'sfx': true});
    mockProgressAudio();
    audio = QuizAudioHarness()..install();
  });
  for (final correct in [true, false]) {
    testWidgets(
        'tap interrupts speech, plays ${correct ? 'correct' : 'wrong'} once, then advances',
        (t) async {
      final p =
          await mount(t, const PhonicsQuizScreen(difficulty: Difficulty.easy));

      Future<void> until(bool Function() ready) async {
        for (var i = 0; i < 100 && !ready(); i++) {
          await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 5)));
          await t.pump();
        }
        expect(ready(), isTrue, reason: 'Audio starts: ${audio.starts}');
      }

      final q = shownQuiz(t);
      await until(
          () => audio.starts.any((s) => s.contains('/cvc_lesson/word-')));
      expect(p.phonicsAudio.currentPhrase, q.wordAudioKey);
      final staleTap = t
          .widget<PhonicsQuizQuestionView>(find.byType(PhonicsQuizQuestionView))
          .onSelect;
      final selected = correct
          ? q.correctLetter
          : q.options.firstWhere((l) => l != q.correctLetter);
      await selectQuiz(t, selected);
      staleTap(q.correctLetter);
      final suffix = '/audio/${correct ? 'correct' : 'wrong'}.mp3';
      await until(() => audio.starts.any((s) => s.endsWith(suffix)));
      expect(p.phonicsAudio.currentPhrase, isNull,
          reason: 'Answer feedback stops the previous word before playing.');
      final session = t.state<GameSessionUi>(find.byType(PhonicsQuizScreen));
      expect((session.scoredAttempts, session.correctAttempts),
          (1, correct ? 1 : 0));
      expect(t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult,
          correct);
      expect(
          t
              .widgetList<GameAnswerButton>(find.byType(GameAnswerButton))
              .every((w) => w.onPressed == null),
          isTrue);
      expect(
          t
              .widget<IconButton>(
                  find.byKey(ValueKey('quiz-sound-${q.correctLetter}')))
              .onPressed,
          isNull);
      expect(find.byKey(const ValueKey('quiz-check-answer')), findsNothing);

      await t.pump(const Duration(milliseconds: 2100));
      expect(shownQuiz(t).id, q.id,
          reason: 'Keep the 2.04-second effect audible before the next word.');
      expect(audio.starts.where((s) => s.contains('/cvc_lesson/word-')),
          hasLength(1));
      await t.runAsync(() => audio.completeSource(suffix));
      await t.pump(const Duration(milliseconds: 100));
      await t.pump();
      await until(() =>
          audio.starts.where((s) => s.contains('/cvc_lesson/word-')).length ==
          2);
      expect(shownQuiz(t).id, isNot(q.id));
      expect(
          audio.starts.where((s) =>
              s.endsWith('/audio/correct.mp3') ||
              s.endsWith('/audio/wrong.mp3')),
          hasLength(1));
      expect(
          audio.starts
              .where((s) => s.endsWith('/game_instructions/phonics_quiz.mp3')),
          isEmpty);
      expect(session.scoredAttempts, 1);
      await close(t, p);
      await t.runAsync(() async {
        p.audio.dispose();
        p.phonicsAudio.dispose();
        await Future<void>.delayed(Duration.zero);
      });
      expect(t.takeException(), isNull);
    });
  }
}
