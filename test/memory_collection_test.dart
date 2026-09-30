import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/memory_game_screen.dart';
import 'package:kidsphonics/widgets/game_word_picture.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final reduced in [false, true]) {
    testWidgets('matched images collect and celebrate once; reduced $reduced',
        (t) async {
      await t.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => t.binding.setSurfaceSize(null));
      t.binding.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(
          t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
      SharedPreferences.setMockInitialValues({});
      mockProgressAudio();
      final p =
          await mount(t, const MemoryGameScreen(difficulty: Difficulty.easy));
      final total = t.widget<GameScaffold>(find.byType(GameScaffold)).total!;
      Finder card(int i) => find.byKey(ValueKey('memory-$i'));
      bool enabled(int i) =>
          t.widget<ElevatedButton>(card(i)).onPressed != null;
      var collected = 0;
      for (var i = 0; i < total * 2 && collected < total; i++) {
        if (!enabled(i)) continue;
        for (var j = i + 1; j < total * 2; j++) {
          if (!enabled(j)) continue;
          await t.tap(card(i));
          await t.pump();
          await t.tap(card(j));
          await t.pump();
          String word(int index) => t
              .widget<GameWordPicture>(find.descendant(
                  of: card(index), matching: find.byType(GameWordPicture)))
              .word;
          final matched = word(i) == word(j);
          final expectedWord = word(i);
          await t.pump(const Duration(milliseconds: 760));
          if (matched) {
            await t.pump();
            expect(find.byKey(const ValueKey('memory-flying-picture')),
                reduced ? findsNothing : findsOneWidget);
            if (!reduced) {
              final start = t
                  .getRect(find.byKey(const ValueKey('memory-flying-picture')));
              await t.pump(const Duration(milliseconds: 300));
              expect(
                  t
                      .getRect(
                          find.byKey(const ValueKey('memory-flying-picture')))
                      .top,
                  lessThan(start.top));
              await t.pump(const Duration(milliseconds: 350));
              await t.pump();
            }
            expect(
                t
                    .widget<GameWordPicture>(
                        find.byKey(ValueKey('memory-collected-$collected')))
                    .word,
                expectedWord);
            collected++;
            if (collected == total) {
              expect(find.byKey(const ValueKey('memory-fireworks')),
                  findsOneWidget);
              expect(find.byType(GameResultDialog), findsNothing);
              await t.pump();
              await t.pump(const Duration(milliseconds: 1800));
              final session =
                  t.state(find.byType(MemoryGameScreen)) as GameSessionUi;
              var saved = false;
              session.rewardsSaved.then((_) => saved = true);
              for (var wait = 0; wait < 100; wait++) {
                await t.runAsync(() => Future<void>.delayed(Duration.zero));
                await t.pump();
                if (saved &&
                    find.byType(GameResultDialog).evaluate().isNotEmpty) {
                  break;
                }
              }
              expect(saved, isTrue);
              await t.pump(const Duration(milliseconds: 400));
              expect(find.byType(GameResultDialog), findsOneWidget);
            } else {
              expect(
                  find.byKey(const ValueKey('memory-fireworks')), findsNothing);
            }
            break;
          } else {
            expect(find.byKey(const ValueKey('memory-flying-picture')),
                findsNothing);
            await t.pump(const Duration(milliseconds: 850));
          }
        }
      }
      expect(collected, total);
      expect(p.stars, total);
      expect(p.xp, total * 5 + 10);
      await t.ensureVisible(find.text('Play Again'));
      await t.tap(find.text('Play Again'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('memory-collected-0')), findsNothing);
      expect(find.byKey(const ValueKey('memory-fireworks')), findsNothing);
      expect(t.widget<GameScaffold>(find.byType(GameScaffold)).current, 0);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }
}
