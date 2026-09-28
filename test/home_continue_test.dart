import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/learning_progress.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/screens/letter_mastery_check_screen.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  for (final scenario in ['new', 'practice', 'mastered']) {
    testWidgets('Home continues the $scenario learner to the right destination',
        (tester) async {
      mockProgressAudio();
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester
          .binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
      SharedPreferences.setMockInitialValues({
        'letterProgressV2': jsonEncode({
          if (scenario == 'practice')
            'B': const LetterProgress(
                    letter: 'B', attempts: 2, correctAnswers: 1)
                .toJson(),
          if (scenario == 'mastered')
            for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''))
              letter: LetterProgress(
                      letter: letter,
                      mastered: true,
                      attempts: 5,
                      correctAnswers: 5,
                      completedAssessments: 1,
                      bestAssessmentScore: 5)
                  .toJson(),
        }),
      });
      late AppProvider p;
      await tester.runAsync(() async {
        p = AppProvider();
        await p.ready;
      });
      await tester.pumpWidget(ChangeNotifierProvider.value(
          value: p, child: const MaterialApp(home: HomeScreen())));
      await tester.pumpAndSettle();
      final target = scenario == 'new' ? 'A' : 'B';
      expect(
          find.text(
              scenario == 'mastered' ? 'Explore Lessons' : 'Continue Learning'),
          findsOneWidget);
      if (scenario != 'mastered') {
        expect(
            find.text('Your next little step: Letter $target'), findsOneWidget);
      }
      final before = p.getLetterProgress(target).attempts;
      await tester
          .ensureVisible(find.byKey(const ValueKey('continue-learning')));
      await tester.tap(find.byKey(const ValueKey('continue-learning')));
      await tester.pumpAndSettle();
      if (scenario == 'mastered') {
        expect(find.byType(LessonsScreen), findsOneWidget);
      } else {
        expect(
            tester
                .widget<LetterMasteryCheckScreen>(
                    find.byType(LetterMasteryCheckScreen))
                .letter
                .letter,
            target);
      }
      expect(p.getLetterProgress(target).attempts, before);
      await tester.pumpWidget(const SizedBox());
      p.dispose();
    });
  }
}
