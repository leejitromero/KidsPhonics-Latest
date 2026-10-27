import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/phonics_quiz_design.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'phonics_quiz_test_helpers.dart';
import 'updated_scene_test.dart' show capture;

void main() {
  for (final d in Difficulty.values) {
    for (final (size, scale) in [
      (const Size(320, 568), 1.0),
      (const Size(390, 844), 1.0),
      (const Size(480, 1066), 1.0),
      (const Size(320, 568), 1.8),
    ]) {
      testWidgets('$d sound quiz fits $size text $scale before and after Check',
          (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
        mockProgressAudio();
        final boundary = GlobalKey();
        final p = await mount(
            t,
            MediaQuery(
                data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                    padding: const EdgeInsets.symmetric(vertical: 24)),
                child: RepaintBoundary(
                    key: boundary, child: PhonicsQuizScreen(difficulty: d))));
        final q = shownQuiz(t);
        final guide =
            t.getRect(find.byKey(const ValueKey('game-instruction-guide')));
        void fits() {
          final view = t.getRect(find.byType(PhonicsQuizQuestionView));
          expect(guide.bottom, lessThan(view.top));
          for (final choice in find.byType(GameAnswerButton).evaluate()) {
            final rect = t.getRect(find.byWidget(choice.widget));
            expect(rect.left, greaterThanOrEqualTo(12));
            expect(rect.right, lessThanOrEqualTo(size.width - 12));
            expect(rect.bottom, lessThanOrEqualTo(size.height - 24));
            expect(rect.height, greaterThanOrEqualTo(32));
          }
          final questionFrame =
              t.getRect(find.byKey(const ValueKey('quiz-question-frame')));
          final questionText = t.renderObject<RenderParagraph>(
              find.byKey(const ValueKey('quiz-question')));
          expect(questionText.didExceedMaxLines, isFalse,
              reason: 'The entire question stays readable with large text');
          expect(questionFrame.bottom,
              lessThan(t.getRect(find.byType(GameAnswerButton).first).top));
          for (final choice in t
              .widgetList<GameAnswerButton>(find.byType(GameAnswerButton))) {
            final speaker =
                t.getRect(find.byKey(ValueKey('quiz-sound-${choice.label}')));
            final tile = t.getRect(find.byWidget(choice));
            expect(speaker.center.dx, closeTo(tile.center.dx, .1));
            expect(speaker.top, greaterThan(tile.bottom));
            expect(speaker.width, closeTo(speaker.height, .1),
                reason: 'Speaker controls stay circular');
            expect(speaker.bottom, lessThanOrEqualTo(size.height - 24));
          }
          expect(t.takeException(), isNull);
        }

        fits();
        if (size.width == 390 && d == Difficulty.hard) {
          await capture(t, boundary, 'phonics_quiz_new');
        }
        final selected = d == Difficulty.medium
            ? q.options.firstWhere((letter) => letter != q.correctLetter)
            : q.correctLetter;
        await selectQuiz(t, selected);
        final check = find.byKey(const ValueKey('quiz-check-answer'));
        expect(t.getRect(check).bottom, lessThanOrEqualTo(size.height - 24));
        await submitQuiz(t);
        fits();
        expect(find.text(q.explanation), findsOneWidget);
        final feedback =
            t.getRect(find.byKey(const ValueKey('quiz-feedback-frame')));
        expect(feedback.bottom, lessThanOrEqualTo(size.height - 24));
        expect(find.text('Correct!'),
            selected == q.correctLetter ? findsOneWidget : findsNothing);
        if (size.width == 390 && d == Difficulty.hard) {
          await capture(t, boundary, 'phonics_quiz_new_feedback');
        }
        if (size.width == 390 && d == Difficulty.medium) {
          await capture(t, boundary, 'phonics_quiz_framed_retry');
        }
        if (size.width == 320 && scale == 1.8 && d == Difficulty.hard) {
          await capture(t, boundary, 'phonics_quiz_framed_large_text');
        }
        await close(t, p);
      });
    }
  }
}
