import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/learning_progress.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  for (final width in [320.0, 600.0, 900.0]) {
    testWidgets('Home fits width $width with large text', (tester) async {
      mockProgressAudio();
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester
          .binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      late AppProvider provider;
      await tester.runAsync(() async {
        provider = AppProvider();
        await provider.ready;
      });
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.8),
            ),
            child: child!,
          ),
          home: const HomeScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('home-parents')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('home-lessons')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-games')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      provider.dispose();
    });
  }
  for (final scenario in ['new', 'practice', 'mastered']) {
    testWidgets(
        'Home shows progress without a duplicate practice button for $scenario',
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
      expect(find.byKey(const ValueKey('continue-learning')), findsNothing);
      expect(find.text('Continue Learning'), findsNothing);
      expect(find.text('Explore Lessons'), findsNothing);
      if (scenario != 'mastered') {
        expect(
            find.text('Your next little step: Letter $target'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      p.dispose();
    });
  }
}
