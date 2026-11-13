import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/data/phonics_activity_data.dart';
import 'package:kidsphonics/screens/word_builder_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/word_builder_choice_frame.dart';
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
      await t.runAsync(() => p.toggleVoice());
      await t.pump();
      expect(find.byType(Scrollable), findsNothing);
      final word =
          t.widget<AudioButton>(find.byType(AudioButton)).phrase.toUpperCase();
      final puzzle = wordPuzzlesForDifficulty(difficulty)
          .firstWhere((p) => p.word == word);
      final before = <Key, Rect>{};
      final choices = t
          .widgetList<GameAnswerButton>(find.byType(GameAnswerButton))
          .toList();
      expect(choices, hasLength(difficulty.index + 3));
      final frame = t.getRect(find.byType(WordBuilderChoiceFrame));
      for (final choice in choices) {
        final rect = t.getRect(find.byKey(choice.buttonKey!));
        expect(rect.bottom, lessThanOrEqualTo(568));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
        expect(rect.width, lessThanOrEqualTo(60));
        expect(frame.contains(rect.topLeft), isTrue);
        expect(frame.contains(rect.bottomRight), isTrue);
        before[choice.buttonKey!] = rect;
      }
      final wrong =
          puzzle.tiles.firstWhere((l) => l != puzzle.correctLetters.first);
      final selected = choices.firstWhere((choice) => choice.label == wrong);
      await t.tap(find.byKey(selected.buttonKey!));
      await t.pump();
      expect(find.byKey(selected.buttonKey!), findsNothing);
      expect(find.byType(WordBuilderEmptyPlace), findsOneWidget);
      expect(find.text('Nice try! Keep practicing.'), findsNothing);
      for (final choice in choices.where((choice) => choice != selected)) {
        final current = t.getRect(find.byKey(choice.buttonKey!));
        expect((current.center - before[choice.buttonKey!]!.center).distance,
            lessThan(4));
        expect(current.bottom, lessThanOrEqualTo(568));
      }
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Correct!'), findsNothing);
      if (puzzle.correctLetters.length == 1) {
        final saved = find.text('Answer saved!');
        expect(saved, findsOneWidget);
        expect(t.getRect(saved).bottom, lessThanOrEqualTo(568));
      }
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }
}
