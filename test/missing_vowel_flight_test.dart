import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/missing_vowel_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;

const flying = ValueKey('flying-vowel');
const blank = ValueKey('vowel-blank-letter');

Finder choiceFor(String vowel) =>
    find.byWidgetPredicate((w) => w is GameAnswerButton && w.label == vowel);

String correctVowel(WidgetTester t) {
  final word = t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
  return RegExp('[AEIOU]').firstMatch(word)!.group(0)!;
}

Future<void> pick(WidgetTester t, String vowel) async {
  await t.tap(find.descendant(
      of: choiceFor(vowel), matching: find.byType(ElevatedButton)));
  await t.pump();
  await t.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
  });

  for (final difficulty in Difficulty.values) {
    for (final reduced in [false, true]) {
      testWidgets('$difficulty vowel flies to blank; reduced motion $reduced',
          (t) async {
        final p = await mount(
            t,
            MediaQuery(
                data: MediaQueryData(disableAnimations: reduced),
                child: MissingVowelScreen(difficulty: difficulty)));
        final vowel = correctVowel(t);
        final session = t.state<GameSessionUi>(find.byType(MissingVowelScreen));
        final onPick = t.widget<GameAnswerButton>(choiceFor(vowel)).onPressed!;
        final source = t.getCenter(choiceFor(vowel));
        await pick(t, vowel);
        onPick();
        if (!reduced) {
          expect(find.byKey(flying), findsOneWidget);
          expect(t.widget<Text>(find.byKey(blank)).data, '_');
          final start = t.getCenter(find.byKey(flying));
          expect(start.dy, closeTo(source.dy, 1));
          await t.pump(const Duration(milliseconds: 250));
          final middle = t.getCenter(find.byKey(flying));
          expect(middle.dy, lessThan(start.dy));
          expect(middle.dy, greaterThan(t.getCenter(find.byKey(blank)).dy));
        }
        await t.pump(const Duration(milliseconds: 600));
        await t.pump();
        expect(find.byKey(flying), findsNothing);
        expect(t.widget<Text>(find.byKey(blank)).data, vowel);
        expect(session.scoredAttempts, 1);
        var saved = false;
        session.rewardsSaved.then((_) => saved = true);
        for (var i = 0; i < 100 && !saved; i++) {
          await t.runAsync(() => Future<void>.delayed(Duration.zero));
          await t.pump();
        }
        expect(saved, isTrue);
        expect((p.xp, p.stars), ((8 * difficulty.xpMultiplier).round(), 1));
        await t.tap(find.widgetWithText(ElevatedButton, 'Next'));
        await t.pump(const Duration(milliseconds: 800));
        expect(t.widget<Text>(find.byKey(blank)).data, '_');
        expect(find.byKey(flying), findsNothing);
        expect(t.takeException(), isNull);
        await close(t, p);
      });
    }
  }

  testWidgets('wrong vowel lands, then clears on the existing retry reset',
      (t) async {
    final p = await mount(t, const MissingVowelScreen());
    final correct = correctVowel(t);
    final wrong = 'AEIOU'.split('').firstWhere((v) => v != correct);
    await pick(t, wrong);
    await t.pump(const Duration(milliseconds: 600));
    await t.pump();
    expect(t.widget<Text>(find.byKey(blank)).data, wrong);
    expect(find.text('Next'), findsNothing);
    await t.pump(const Duration(milliseconds: 200));
    await t.pump(const Duration(milliseconds: 600));
    expect(t.widget<Text>(find.byKey(blank)).data, '_');
    expect(t.widget<GameAnswerButton>(choiceFor(correct)).onPressed, isNotNull);
    expect((p.xp, p.stars), (0, 0));
    await close(t, p);
  });

  for (final leave in ['next', 'dispose']) {
    testWidgets('$leave during flight leaves no floating vowel behind',
        (t) async {
      final p = await mount(t, const MissingVowelScreen());
      await pick(t, correctVowel(t));
      expect(find.byKey(flying), findsOneWidget);
      if (leave == 'next') {
        await t.tap(find.widgetWithText(ElevatedButton, 'Next'));
        await t.pump();
        expect(t.widget<Text>(find.byKey(blank)).data, '_');
      } else {
        await t.pumpWidget(const SizedBox());
      }
      await t.pump(const Duration(seconds: 1));
      expect(find.byKey(flying), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }
}
