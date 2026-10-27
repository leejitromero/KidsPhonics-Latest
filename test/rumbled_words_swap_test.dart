import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close, flushWrites;
import 'rumbled_words_swap_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
  });

  testWidgets('selection floats without moving letters; drag inserts in order',
      (t) async {
    final p = await mount(
        t,
        const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: RumbledWordsScreen()));
    final word = t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
    final before = boardLetters(t, word.length);
    await tapBoardLetter(t, 0);
    expect(boardLetters(t, word.length), before);
    expect(find.text('Drag the floating letter into place.'), findsOneWidget);
    await tapBoardLetter(t, 0);
    expect(find.text('Drag the floating letter into place.'), findsNothing);
    // CTA -> CAT: moving the last tile to the middle shifts the middle one.
    await tapBoardLetter(t, 2);
    await dragBoardLetter(t, 2, 1);
    final expected = List.of(before);
    expected.insert(1, expected.removeAt(2));
    expect(boardLetters(t, word.length), expected);
    expect(
        t.state<GameSessionUi>(find.byType(RumbledWordsScreen)).scoredAttempts,
        0);
    expect((p.xp, p.stars), (0, 0));
    expect(find.byKey(const ValueKey('word-answer-board')), findsNothing);
    expect(find.byKey(const ValueKey('word-erase')), findsNothing);
    await close(t, p);
  });

  testWidgets('Check alone scores, preserves errors, and rewards success once',
      (t) async {
    final p = await mount(
        t,
        const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: RumbledWordsScreen()));
    final word = t
        .widget<WordGameLayout>(find.byType(WordGameLayout))
        .word
        .toUpperCase();
    final session = t.state<GameSessionUi>(find.byType(RumbledWordsScreen));
    final check = find.byKey(const ValueKey('word-check'));
    final before = boardLetters(t, word.length);
    final submitWrong = t.widget<OutlinedButton>(check).onPressed!;
    submitWrong();
    submitWrong();
    await t.pump();
    expect(session.scoredAttempts, 1);
    expect(boardLetters(t, word.length), before);
    expect(find.text('Try again! Drag a letter into place.'), findsOneWidget);
    // Selecting and cancelling do not allow the same wrong answer to be scored
    // again. The board must actually change.
    await tapBoardLetter(t, 0);
    await tapBoardLetter(t, 0);
    expect(t.widget<OutlinedButton>(check).onPressed, isNull);
    await t.tap(find.byKey(const ValueKey('word-hint')));
    await t.pump();
    expect(boardLetters(t, word.length).first, word[0]);
    expect(
        t
            .widget<ElevatedButton>(find.byKey(const ValueKey('word-tile-0')))
            .onPressed,
        isNull);
    expect(
        t
            .widget<OutlinedButton>(find.byKey(const ValueKey('word-hint')))
            .onPressed,
        isNull);
    expect(session.scoredAttempts, 1);
    await arrangeBoard(t, word);
    expect(session.scoredAttempts, 1);
    expect(find.text('Correct!'), findsNothing);
    final submitCorrect = t.widget<OutlinedButton>(check).onPressed!;
    submitCorrect();
    submitCorrect();
    await t.pump();
    expect(find.text('Correct!'), findsOneWidget);
    expect(session.scoredAttempts, 2);
    expect(session.correctAttempts, 1);
    await flushWrites(t);
    expect((p.xp, p.stars), (8, 1));
    expect(p.dailyActivity.values.single.questionsAnswered, 2);
    await close(t, p);
  });
}
