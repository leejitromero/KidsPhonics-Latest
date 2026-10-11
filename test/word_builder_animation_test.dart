import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/phonics_activity_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/word_builder_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

WordPuzzle puzzle(WidgetTester t, Difficulty difficulty) =>
    wordPuzzlesForDifficulty(difficulty).firstWhere((p) =>
        p.word ==
        t.widget<AudioButton>(find.byType(AudioButton)).phrase.toUpperCase());

String slot(WidgetTester t, int index) => t
    .widget<Text>(find.descendant(
        of: find.byKey(ValueKey('builder-blank-$index')),
        matching: find.byType(Text)))
    .data!;

Future<void> flushAudio(WidgetTester t) async {
  for (var i = 0; i < 30; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await t.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });

  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    testWidgets('correct letters fly to individual blanks at $size', (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      final p =
          await mount(t, const WordBuilderScreen(difficulty: Difficulty.hard));
      await t.runAsync(() => p.toggleVoice());
      await t.pump();
      final task = puzzle(t, Difficulty.hard);
      for (var i = 0; i < task.correctLetters.length; i++) {
        final choice =
            find.byKey(ValueKey('builder-choice-${task.correctLetters[i]}'));
        final start = t.getRect(choice);
        final end = t.getRect(find.byKey(ValueKey('builder-blank-$i')));
        await t.tap(choice);
        await t.tap(choice);
        await t.pump();
        final flying = find.byKey(const ValueKey('flying-builder-letter'));
        expect(flying, findsOneWidget);
        expect(t.getRect(flying), start);
        expect(slot(t, i), '_');
        await t.pump(const Duration(milliseconds: 275));
        expect(t.getRect(flying).center.dy, lessThan(start.center.dy));
        await t.pump(const Duration(milliseconds: 265));
        expect((t.getRect(flying).center - end.center).distance, lessThan(5));
        await t.pump(const Duration(milliseconds: 20));
        expect(flying, findsNothing);
        expect(slot(t, i), task.correctLetters[i]);
        await flushAudio(t);
        expect(p.stars, i == task.correctLetters.length - 1 ? 1 : 0);
        await t.pump(const Duration(milliseconds: 1100));
      }
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets('leaving during a flight removes the animated letter', (t) async {
    final p = await mount(t, const WordBuilderScreen());
    final task = puzzle(t, Difficulty.medium);
    await t.tap(
        find.byKey(ValueKey('builder-choice-${task.correctLetters.first}')));
    await t.pump();
    expect(find.byKey(const ValueKey('flying-builder-letter')), findsOneWidget);
    await close(t, p);
    await t.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('flying-builder-letter')), findsNothing);
    expect(t.takeException(), isNull);
  });
}
