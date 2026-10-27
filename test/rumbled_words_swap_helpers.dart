import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> boardLetters(WidgetTester t, int length) => [
      for (var i = 0; i < length; i++)
        t
            .widget<Text>(find.descendant(
                of: find.byKey(ValueKey('word-tile-$i')),
                matching: find.byType(Text)))
            .data!
    ];

Future<void> tapBoardLetter(WidgetTester t, int index) async {
  final tile = find.byKey(ValueKey('word-tile-$index'));
  await t.ensureVisible(tile);
  await t.tap(tile);
  await t.pump();
}

/// Drag a selected letter to a position, inserting it between its neighbors.
Future<void> dragBoardLetter(WidgetTester t, int from, int to) async {
  final start = t.getCenter(find.byKey(ValueKey('word-tile-$from')));
  final end = t.getCenter(find.byKey(ValueKey('word-tile-$to')));
  final gesture = await t.startGesture(start);
  // Cross the pan slop before moving over the intended insertion position.
  await gesture.moveBy(Offset(to > from ? 22 : -22, 0));
  await t.pump();
  await gesture.moveTo(end);
  await t.pump(const Duration(milliseconds: 280));
  await gesture.up();
  await t.pump(const Duration(milliseconds: 300));
}

/// Sort by insertion, keeping duplicate letters as separate tiles.
Future<void> arrangeBoard(WidgetTester t, String word,
    {Future<void> Function(String letter)? afterTap}) async {
  for (var position = 0; position < word.length; position++) {
    final letters = boardLetters(t, word.length);
    if (letters[position] == word[position]) continue;
    final source = List.generate(word.length, (i) => i)
        .firstWhere((i) => i > position && letters[i] == word[position]);
    await tapBoardLetter(t, source);
    await afterTap?.call(letters[source]);
    await dragBoardLetter(t, source, position);
  }
  expect(boardLetters(t, word.length).join(), word);
}
