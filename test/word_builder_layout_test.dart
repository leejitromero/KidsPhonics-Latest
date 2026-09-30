import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/data/phonics_activity_data.dart';
import 'package:kidsphonics/screens/word_builder_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final difficulty in Difficulty.values) {
    testWidgets('builder $difficulty choices and feedback fit a small phone',
        (t) async {
      await t.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => t.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      mockProgressAudio();
      final p = await mount(t, WordBuilderScreen(difficulty: difficulty));
      expect(find.byType(Scrollable), findsNothing);
      final word =
          t.widget<AudioButton>(find.byType(AudioButton)).phrase.toUpperCase();
      final puzzle = wordPuzzlesForDifficulty(difficulty)
          .firstWhere((p) => p.word == word);
      final before = <String, Rect>{};
      for (final letter in puzzle.tiles) {
        final rect = t.getRect(find.byKey(ValueKey('builder-choice-$letter')));
        expect(rect.bottom, lessThanOrEqualTo(568));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
        expect(rect.width, lessThanOrEqualTo(60));
        before[letter] = rect;
      }
      final wrong =
          puzzle.tiles.firstWhere((l) => l != puzzle.correctLetters.first);
      await t.tap(find.byKey(ValueKey('builder-choice-$wrong')));
      await t.pump();
      expect(find.text('Nice try! Keep practicing.'), findsOneWidget);
      for (final letter in puzzle.tiles) {
        expect(t.getRect(find.byKey(ValueKey('builder-choice-$letter'))),
            before[letter]);
      }
      expect(t.getRect(find.text('Nice try! Keep practicing.')).bottom,
          lessThanOrEqualTo(568));
      await t.pump(const Duration(milliseconds: 350));
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }
}
