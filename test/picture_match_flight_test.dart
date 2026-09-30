import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/picture_word_match_screen.dart';
import 'package:kidsphonics/widgets/game_word_picture.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  for (final reduced in [false, true]) {
    testWidgets('correct picture lands and resets; reduced motion $reduced',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      mockProgressAudio();
      SharedPreferences.setMockInitialValues({});
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(tester
          .binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
      late AppProvider p;
      await tester.runAsync(() async {
        p = AppProvider();
        await p.ready;
      });
      await tester.pumpWidget(ChangeNotifierProvider.value(
          value: p,
          child: const MaterialApp(
              home: PictureWordMatchScreen(difficulty: Difficulty.hard))));
      await tester.pump();
      expect(find.byType(Scrollable), findsNothing);
      for (final choice in tester
          .widgetList<GameAnswerButton>(find.byType(GameAnswerButton))) {
        final rect =
            tester.getRect(find.widgetWithText(GameAnswerButton, choice.label));
        expect(rect.bottom, lessThanOrEqualTo(568));
        expect(rect.width, lessThanOrEqualTo(100));
      }
      final pictures = tester
          .widgetList<GameWordPicture>(find.byType(GameWordPicture))
          .toList();
      final correct = pictures.singleWhere(
          (pic) => find.text(pic.word.toUpperCase()).evaluate().isNotEmpty);
      final wrong = pictures.firstWhere((pic) => pic.word != correct.word);
      Finder buttonFor(String word) => find.ancestor(
          of: find
              .byWidgetPredicate((w) => w is GameWordPicture && w.word == word),
          matching: find.byType(GameAnswerButton));
      await tester.ensureVisible(buttonFor(wrong.word));
      await tester.tap(find.descendant(
          of: buttonFor(wrong.word), matching: find.byType(ElevatedButton)));
      await tester.pump(const Duration(milliseconds: 950));
      expect(find.byKey(const ValueKey('matched-picture')), findsNothing);
      expect(find.byKey(const ValueKey('flying-match-picture')), findsNothing);
      await tester.ensureVisible(buttonFor(correct.word));
      await tester.tap(find.descendant(
          of: buttonFor(correct.word), matching: find.byType(ElevatedButton)));
      await tester.pump();
      if (!reduced) {
        expect(
            find.byKey(const ValueKey('flying-match-picture')), findsOneWidget);
        expect(
            tester
                .widget<ElevatedButton>(
                    find.widgetWithText(ElevatedButton, 'Next'))
                .onPressed,
            isNull);
      }
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
      expect(find.byKey(const ValueKey('flying-match-picture')), findsNothing);
      expect(
          tester
              .widget<GameWordPicture>(
                  find.byKey(const ValueKey('matched-picture')))
              .word
              .toUpperCase(),
          correct.word.toUpperCase());
      expect(find.text('Correct match!'), findsOneWidget);
      expect(tester.getRect(find.text('Next')).bottom, lessThanOrEqualTo(568));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.byKey(const ValueKey('matched-picture')), findsNothing);
      expect(find.text('Your picture goes here'), findsOneWidget);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpWidget(const SizedBox());
      p.dispose();
    });
  }
}
