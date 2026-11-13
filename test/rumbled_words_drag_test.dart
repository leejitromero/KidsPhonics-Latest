import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/rumbled_words_design.dart';
import 'package:kidsphonics/widgets/floating_choice.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;
import 'rumbled_words_swap_helpers.dart';
import 'updated_scene_test.dart' show capture;

Finder tile(int i) => find.byKey(ValueKey('word-tile-$i'));

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
  });

  for (final reduced in [false, true]) {
    testWidgets(
        'direct drag needs no tap; neighbors slide for insertion, reduced $reduced',
        (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      final p = await mount(
          t,
          MediaQuery(
              data: MediaQueryData(
                  size: const Size(390, 844), disableAnimations: reduced),
              child: RepaintBoundary(
                  key: boundary, child: const RumbledWordsScreen())));
      final before = boardLetters(t, 3);
      final first = t.getCenter(tile(0));
      final second = t.getCenter(tile(1));
      final last = t.getCenter(tile(2));
      expect(
          find.descendant(
              of: find.byType(RumbledLetterRow),
              matching: find.byType(FloatingChoice)),
          findsNothing);
      expect(t.getCenter(tile(2)), last);
      final gesture = await t.startGesture(t.getCenter(tile(2)));
      await gesture.moveBy(const Offset(-22, 0));
      await t.pump();
      await gesture.moveTo(first);
      await t.pump();
      if (!reduced) {
        await t.pump(const Duration(milliseconds: 120));
        final halfway = t.getCenter(tile(0)).dx;
        expect(halfway, greaterThan(first.dx));
        expect(halfway, lessThan(second.dx));
      }
      await t.pump(const Duration(milliseconds: 300));
      expect(t.getCenter(tile(0)).dx, closeTo(second.dx, 1));
      expect(boardLetters(t, 3), before,
          reason:
              'Hover previews placement without submitting or committing it');
      expect(
          t
              .widget<OutlinedButton>(find.byKey(const ValueKey('word-check')))
              .onPressed,
          isNull);
      expect(
          t
              .widget<OutlinedButton>(find.byKey(const ValueKey('word-hint')))
              .onPressed,
          isNull);
      if (!reduced) await capture(t, boundary, 'rumbled_drag_preview');
      await gesture.up();
      await t.pump(const Duration(milliseconds: 300));
      final expected = List.of(before)..insert(0, before[2]);
      expected.removeLast();
      expect(boardLetters(t, 3), expected);
      final session = t.state<GameSessionUi>(find.byType(RumbledWordsScreen));
      expect(session.scoredAttempts, 0);
      expect((p.xp, p.stars), (0, 0));
      if (!reduced) await capture(t, boundary, 'rumbled_drag_landed');
      await close(t, p);
    });
  }

  testWidgets('dragging to the right shifts intervening letters to the left',
      (t) async {
    final p = await mount(t, const RumbledWordsScreen());
    final before = boardLetters(t, 3);
    await dragBoardLetter(t, 0, 2);
    expect(boardLetters(t, 3), [before[1], before[2], before[0]]);
    expect((p.xp, p.stars), (0, 0));
    await close(t, p);
  });

  for (final difficulty in Difficulty.values) {
    testWidgets(
        '$difficulty directly moves any tile without selecting it first',
        (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final p = await mount(t, RumbledWordsScreen(difficulty: difficulty));
      final count =
          t.widget<WordGameLayout>(find.byType(WordGameLayout)).word.length;
      final before = boardLetters(t, count);
      final ids = List.of(
          t.widget<RumbledLetterRow>(find.byType(RumbledLetterRow)).tileIds);
      await dragBoardLetter(t, count - 1, 1);
      final expected = List.of(before)..insert(1, before.last);
      expected.removeLast();
      ids.insert(1, ids.removeLast());
      expect(boardLetters(t, count), expected);
      expect(t.widget<RumbledLetterRow>(find.byType(RumbledLetterRow)).tileIds,
          ids);
      expect(
          t
              .state<GameSessionUi>(find.byType(RumbledWordsScreen))
              .scoredAttempts,
          0);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets(
      'two taps select another letter without suddenly moving either one',
      (t) async {
    final p = await mount(t, const RumbledWordsScreen());
    final before = boardLetters(t, 3);
    final centers = [for (var i = 0; i < 3; i++) t.getCenter(tile(i))];
    await tapBoardLetter(t, 0);
    await t.pump(const Duration(milliseconds: 450));
    for (var i = 0; i < 3; i++) {
      expect(t.getCenter(tile(i)), centers[i]);
    }
    await tapBoardLetter(t, 2);
    await t.pump(const Duration(milliseconds: 800));
    for (var i = 0; i < 3; i++) {
      expect(t.getCenter(tile(i)), centers[i]);
    }
    expect(boardLetters(t, 3), before);
    await dragBoardLetter(t, 2, 1);
    final expected = List.of(before)..insert(1, before[2]);
    expected.removeLast();
    expect(boardLetters(t, 3), expected);
    await close(t, p);
  });

  testWidgets('a second finger cannot replace or finish an active drag',
      (t) async {
    final p = await mount(t, const RumbledWordsScreen());
    final before = boardLetters(t, 3);
    final end = t.getCenter(tile(1));
    final first = await t.startGesture(t.getCenter(tile(0)), pointer: 1);
    await first.moveBy(const Offset(22, 0));
    await t.pump();
    final second = await t.startGesture(t.getCenter(tile(2)), pointer: 2);
    await second.moveBy(const Offset(0, 25));
    await t.pump();
    await second.up();
    await t.pump();
    expect(
        t
            .widget<OutlinedButton>(find.byKey(const ValueKey('word-check')))
            .onPressed,
        isNull);
    await first.moveTo(end);
    await t.pump(const Duration(milliseconds: 300));
    await first.up();
    await t.pump(const Duration(milliseconds: 300));
    expect(boardLetters(t, 3), [before[1], before[0], before[2]]);
    expect(
        t.state<GameSessionUi>(find.byType(RumbledWordsScreen)).scoredAttempts,
        0);
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  testWidgets('outside drop cancels and hint keeps the first letter fixed',
      (t) async {
    final p = await mount(t, const RumbledWordsScreen());
    final before = boardLetters(t, 3);
    final gesture = await t.startGesture(t.getCenter(tile(2)));
    await gesture.moveBy(const Offset(0, -120));
    await t.pump();
    await gesture.moveBy(const Offset(0, -40));
    await t.pump();
    await gesture.up();
    await t.pump(const Duration(milliseconds: 300));
    expect(boardLetters(t, 3), before);
    await t.tap(find.byKey(const ValueKey('word-hint')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    final hinted = boardLetters(t, 3);
    await dragBoardLetter(t, 0, 2);
    expect(boardLetters(t, 3), hinted);
    await dragBoardLetter(t, 2, 0);
    expect(boardLetters(t, 3), [hinted[0], hinted[2], hinted[1]]);
    expect(t.widget<ElevatedButton>(tile(0)).onPressed, isNull);
    expect((p.xp, p.stars), (0, 0));
    await close(t, p);
  });

  for (final interruption in ['background', 'dispose']) {
    testWidgets(
        '$interruption cancels a drag without changing the board or scoring',
        (t) async {
      final p = await mount(t, const RumbledWordsScreen());
      final before = boardLetters(t, 3);
      final gesture = await t.startGesture(t.getCenter(tile(2)));
      await gesture.moveBy(const Offset(-22, 0));
      await t.pump();
      await gesture.moveTo(t.getCenter(tile(0)));
      await t.pump(const Duration(milliseconds: 300));
      if (interruption == 'background') {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await t.pump();
        await gesture.up();
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await t.pump(const Duration(milliseconds: 300));
        expect(boardLetters(t, 3), before);
      } else {
        await t.pumpWidget(const SizedBox());
        await gesture.up();
      }
      expect((p.xp, p.stars), (0, 0));
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }
}
