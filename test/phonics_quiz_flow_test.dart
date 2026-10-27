import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/game_design.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close, flushWrites;
import 'phonics_quiz_test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
  });
  test(
      'four supplied recordings are preserved and all sound targets are explicit',
      () {
    final imports = jsonDecode(
            File('tools/phonics_quiz_audio_import.json').readAsStringSync())
        as List;
    expect(imports, hasLength(4));
    for (final entry in imports) {
      expect(
          sha256
              .convert(File(entry['path']).readAsBytesSync())
              .toString()
              .toUpperCase(),
          entry['sha256']);
    }
    for (final d in Difficulty.values) {
      final pool = quizQuestionsForDifficulty(d);
      expect(pool.map((q) => q.position).toSet(), quizPositionsFor(d).toSet());
      for (final q in pool) {
        expect(q.word.length, 3);
        expect(q.correctLetter, q.word[q.position.wordIndex]);
        expect(q.options.toSet(), hasLength(3));
        expect(q.options.where((x) => x == q.correctLetter), hasLength(1));
        expect(File(q.pictureAsset!).existsSync(), isTrue);
        expect(
            File('assets/${PhonicsAudioService.assetForPhrase(q.wordAudioKey)}')
                .existsSync(),
            isTrue);
        expect(
            File('assets/${PhonicsAudioService.assetForPhrase(q.position.audioKey)}')
                .existsSync(),
            isTrue);
      }
    }
  });

  testWidgets('selection is editable and Check accepts only one submission',
      (t) async {
    final p = await mount(t, const PhonicsQuizScreen());
    final q = shownQuiz(t);
    final session = t.state<GameSessionUi>(find.byType(PhonicsQuizScreen));
    final wrong = q.options.firstWhere((x) => x != q.correctLetter);
    await submitQuiz(t);
    expect(session.scoredAttempts, 0);
    await selectQuiz(t, wrong);
    expect(session.scoredAttempts, 0);
    expect(
        t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult, isNull);
    await selectQuiz(t, q.correctLetter);
    expect(session.scoredAttempts, 0);
    await submitQuiz(t);
    await submitQuiz(t);
    expect(session.scoredAttempts, 1);
    expect(
        t.widget<GameScaffold>(find.byType(GameScaffold)).answerResult, isTrue);
    expect(find.text(q.explanation), findsOneWidget);
    await finishMutedQuizFeedback(t);
    expect(shownQuiz(t).id, isNot(q.id));
    await flushWrites(t);
    expect(p.stars, 1);
    await close(t, p);
  });

  for (final d in Difficulty.values) {
    testWidgets(
        '$d quiz score stays fixed through mistake review and replay resets',
        (t) async {
      final p = await mount(t, PhonicsQuizScreen(difficulty: d));
      final session = t.state<GameSessionUi>(find.byType(PhonicsQuizScreen));
      final total = session.totalGameItems;
      final positions = <QuizSoundPosition>{};
      final words = <String>{};
      String? missedId;
      for (var i = 0; i < total; i++) {
        final q = shownQuiz(t);
        positions.add(q.position);
        expect(words.add(q.word), isTrue);
        if (i == 0) missedId = q.id;
        await selectQuiz(
            t,
            i == 0
                ? q.options.firstWhere((l) => l != q.correctLetter)
                : q.correctLetter);
        await submitQuiz(t);
        await finishMutedQuizFeedback(t);
      }
      await flushWrites(t);
      expect(positions, quizPositionsFor(d).toSet());
      expect(find.text('Score: ${total - 1} / $total'), findsOneWidget);
      expect(
          find.textContaining(
              'Review practice does not change this quiz score.'),
          findsOneWidget);
      expect(session.scoredAttempts, total);
      final expectedXp = (total - 1) * (5 * d.xpMultiplier).round() +
          (20 * d.xpMultiplier).round();
      expect((p.xp, p.stars), (expectedXp, total - 1));
      expect(p.dailyActivity.values.single.activitiesCompleted, 1);
      await t.ensureVisible(find.byKey(const ValueKey('quiz-review-mistakes')));
      await t.tap(find.byKey(const ValueKey('quiz-review-mistakes')));
      await t.pump();
      expect(shownQuiz(t).id, missedId);
      expect(t.widget<GameScaffold>(find.byType(GameScaffold)).progressLabel,
          'Review');
      await selectQuiz(t, shownQuiz(t).correctLetter);
      await submitQuiz(t);
      await finishMutedQuizFeedback(t);
      await flushWrites(t);
      expect(find.text('Score: ${total - 1} / $total'), findsOneWidget);
      expect(find.byKey(const ValueKey('quiz-review-mistakes')), findsNothing);
      expect((p.xp, p.stars), (expectedXp, total - 1));
      expect(session.scoredAttempts, total);
      expect(p.dailyActivity.values.single.questionsAnswered, total);
      expect(p.dailyActivity.values.single.activitiesCompleted, 1);
      await t.ensureVisible(find.text('Play Again'));
      await t.tap(find.text('Play Again'));
      await t.pump();
      expect(session.scoredAttempts, 0);
      expect(t.widget<GameScaffold>(find.byType(GameScaffold)).progressLabel,
          'Question');
      expect(
          t
              .widget<ForestAudioButton>(
                  find.byKey(const ValueKey('quiz-check-answer')))
              .onPressed,
          isNull);
      await close(t, p);
    });
  }
}
