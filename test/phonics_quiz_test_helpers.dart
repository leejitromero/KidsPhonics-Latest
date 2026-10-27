import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/phonics_quiz_design.dart';

QuizQuestion shownQuiz(WidgetTester t) => t
    .widget<PhonicsQuizQuestionView>(find.byType(PhonicsQuizQuestionView))
    .question;

Future<void> selectQuiz(WidgetTester t, String letter) async {
  final choice = find.byWidgetPredicate(
      (w) => w is GameAnswerButton && w.label == letterChoiceLabel(letter));
  await t.ensureVisible(choice);
  await t
      .tap(find.descendant(of: choice, matching: find.byType(ElevatedButton)));
  await t.pump();
}

Future<void> submitQuiz(WidgetTester t) async {
  t
      .widget<PhonicsQuizQuestionView>(find.byType(PhonicsQuizQuestionView))
      .onCheck();
  await t.pump();
}

Future<void> finishMutedQuizFeedback(WidgetTester t) async {
  for (final ms in [450, 450, 950]) {
    await t.pump(Duration(milliseconds: ms));
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
    await t.pump();
  }
  for (var i = 0; i < 30; i++) {
    final view =
        t.widget<PhonicsQuizQuestionView>(find.byType(PhonicsQuizQuestionView));
    final session = t.state<GameSessionUi>(find.byType(PhonicsQuizScreen));
    if (!view.submitted || session.resultOpen) break;
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await t.pump(const Duration(milliseconds: 100));
  }
}
