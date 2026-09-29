import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/letter_mastery_check_screen.dart';
import 'package:kidsphonics/services/mastery_audio_service.dart';
import 'package:kidsphonics/widgets/adventure_background.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

class _Audio implements MasteryAudio {
  Completer<bool>? completion;
  int plays = 0;
  String? lastPhrase;
  bool disposed = false;
  @override
  Future<bool> play(String phrase) {
    plays++;
    lastPhrase = phrase;
    completion = Completer<bool>();
    return completion!.future;
  }

  @override
  Future<void> stop() async {
    if (completion != null && !completion!.isCompleted) {
      completion!.complete(false);
    }
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await stop();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(TestWidgetsFlutterBinding
        .instance.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
      'opening and speaker taps record nothing; audio completion gates answers',
      (tester) async {
    late AppProvider p;
    await tester.runAsync(() async {
      p = AppProvider();
      await p.ready;
    });
    final audio = _Audio();
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            home: LetterMasteryCheckScreen(
                letter: allLetters[1], audio: audio))));
    await tester.pump();
    ElevatedButton answer() =>
        tester.widget<ElevatedButton>(find.byKey(const ValueKey('B')));
    expect(p.dailyActivity, isEmpty);
    expect(p.getLetterProgress('B').attempts, 0);
    expect(audio.plays, 0);
    expect(answer().onPressed, isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('hear-sound')));
    await tester.tap(find.byKey(const ValueKey('hear-sound')));
    await tester.pump();
    expect(answer().onPressed, isNull);
    expect(find.text('Listening…'), findsOneWidget);
    expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
    expect(p.dailyActivity, isEmpty);
    audio.completion!.complete(false);
    await tester.pump();
    expect(answer().onPressed, isNull);
    expect(find.textContaining('Word could not play'), findsOneWidget);
    expect(find.text('Listen Again'), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('hear-sound')));
    await tester.tap(find.byKey(const ValueKey('hear-sound')));
    audio.completion!.complete(true);
    await tester.pump();
    expect(audio.lastPhrase, isIn(['lesson-word-B', 'Bag', 'Book', 'Bottle']));
    expect(find.text('Listen Again'), findsOneWidget);
    expect(answer().onPressed, isNotNull);
    expect(p.getLetterProgress('B').attempts, 0);
    expect(p.dailyActivity, isEmpty);
    await tester.ensureVisible(find.byKey(const ValueKey('B')));
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('B')));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(p.getLetterProgress('B').attempts, 1);
    expect(p.dailyActivity.values.single.questionsAnswered, 1);
    expect(p.dailyActivity.values.single.activitiesCompleted, 0);
    expect(answer().onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
    expect(audio.disposed, isTrue);
    p.dispose();
  });

  testWidgets('five-question UI checks fail, pass and retain mastery on retry',
      (tester) async {
    late AppProvider p;
    await tester.runAsync(() async {
      p = AppProvider();
      await p.ready;
    });
    final audio = _Audio();
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            home: LetterMasteryCheckScreen(
                letter: allLetters[1], audio: audio))));
    await tester.pump();
    var completed = 0;
    for (final score in [3, 4, 2]) {
      for (var index = 0; index < 5; index++) {
        expect(
            tester
                .widget<AdventureBackground>(find.byType(AdventureBackground))
                .answerResult,
            isNull);
        expect(find.text('${index + 1} / 5 question'), findsOneWidget);
        final speaker = find.byKey(const ValueKey('hear-sound'));
        if (speaker.evaluate().isNotEmpty) {
          await tester.ensureVisible(speaker);
          await tester.tap(speaker);
          audio.completion!.complete(true);
          await tester.pump();
        }
        final choices = tester
            .widgetList<ElevatedButton>(find.byType(ElevatedButton))
            .where((b) =>
                b.key is ValueKey<String> &&
                b.key != const ValueKey('hear-sound'))
            .map((b) => (b.key! as ValueKey<String>).value)
            .toList();
        final String correct;
        if (index == 2) {
          correct = choices.singleWhere((c) => c.startsWith('B'));
        } else if (index == 3) {
          correct = choices.singleWhere(
              (c) => c.startsWith('B') || c.split(' ').last.startsWith('B'));
          expect(correct, audio.lastPhrase == 'lesson-word-B' ? 'Ball' : audio.lastPhrase);
        } else if (choices.contains('Start')) {
          correct = 'Start';
        } else {
          correct = 'B';
        }
        final selected =
            index < score ? correct : choices.firstWhere((c) => c != correct);
        final answer = find.byKey(ValueKey(selected));
        await tester.ensureVisible(answer);
        await tester.runAsync(() async {
          await tester.tap(answer);
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<AdventureBackground>(find.byType(AdventureBackground))
                .answerResult,
            index < score);
        final effect = find.byKey(const ValueKey('answer-background-effect'));
        final opacity = tester.widget<AnimatedOpacity>(find
            .ancestor(of: effect, matching: find.byType(AnimatedOpacity))
            .first);
        expect(opacity.opacity, 1);
        expect(opacity.duration, Duration.zero);
        final decoration =
            tester.widget<DecoratedBox>(effect).decoration as BoxDecoration;
        expect((decoration.gradient! as RadialGradient).colors.last,
            index < score ? const Color(0xFF92DEB7) : const Color(0xFFF6B5B5));
        final next = find.text(index == 4 ? 'See Result' : 'Next Question');
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
      completed++;
      expect(
          tester
              .widget<AdventureBackground>(find.byType(AdventureBackground))
              .answerResult,
          isNull);
      expect(find.text('Score: $score / 5'), findsOneWidget);
      expect(
          find.text(completed == 1
              ? 'PRACTICED'
              : completed == 2
                  ? 'MASTERED'
                  : 'Still Mastered'),
          findsOneWidget);
      expect(p.dailyActivity.values.single.questionsAnswered, completed * 5);
      expect(p.dailyActivity.values.single.activitiesCompleted, completed);
      expect(p.getLetterProgress('B').attempts, completed * 5);
      if (completed < 3) {
        await tester.ensureVisible(find.text('Try Again'));
        await tester.tap(find.text('Try Again'));
        await tester.pumpAndSettle();
      }
    }
    expect(p.getLetterProgress('B').bestAssessmentScore, 4);
    expect(audio.plays, 9);
    await tester.pumpWidget(const SizedBox());
    p.dispose();
  });
}
