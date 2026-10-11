import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/game_session_order.dart';
import 'package:kidsphonics/data/game_word_data.dart';
import 'package:kidsphonics/data/rumbled_words_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;

bool fits(Difficulty difficulty, String word) => switch (difficulty) {
      Difficulty.easy => word.length == 3,
      Difficulty.medium => word.length >= 4 && word.length <= 5,
      Difficulty.hard => word.length >= 6,
    };

void main() {
  test('spelling pools are distinct and retain each supplied picture and sound',
      () {
    final originalTiers = gameWords.map((w) => w.difficulty).toList();
    final seen = <String>{};
    for (final difficulty in Difficulty.values) {
      final pool = rumbledWordsFor(difficulty);
      expect(pool.length,
          greaterThanOrEqualTo(GameSessionOrder.roundLength(difficulty)));
      for (final word in pool) {
        expect(fits(difficulty, word.word), isTrue, reason: word.word);
        expect(word.difficulty, difficulty);
        expect(seen.add(word.slug), isTrue,
            reason: '${word.word} must appear in exactly one spelling tier');
        final original = gameWordFor(word.word)!;
        expect(word.frames, original.frames);
        expect(
            PhonicsAudioService.assetForPhrase(word.audioKey), word.audioAsset);
        expect(File('assets/${word.audioAsset}').existsSync(), isTrue);
        for (final frame in word.frames) {
          expect(File(frame).existsSync(), isTrue);
        }
      }
    }
    expect(
        seen,
        gameWords
            .where((w) => w.enabledInGames && !w.word.contains(' '))
            .map((w) => w.slug)
            .toSet());
    expect(gameWords.map((w) => w.difficulty), originalTiers,
        reason: 'Other games retain their supplied catalog tiers');
    expect(rumbledWordsFor(Difficulty.easy).map((w) => w.word),
        containsAll(['Dog', 'Net', 'Pen']));
    expect(rumbledWordsFor(Difficulty.medium).map((w) => w.word),
        containsAll(['Moon', 'Spoon', 'Apple']));
    expect(rumbledWordsFor(Difficulty.hard).map((w) => w.word),
        containsAll(['Elephant', 'Airplane']));
    for (final difficulty in Difficulty.values) {
      expect(rumbledWordsFor(difficulty).map((w) => w.word),
          isNot(contains('Umbrella')));
    }
  });

  test('random replays stay within their spelling tier and exhaust its pool',
      () {
    for (final difficulty in Difficulty.values) {
      final pool = rumbledWordsFor(difficulty);
      final drawn = <String>[];
      String? previousLast;
      for (var replay = 0; replay < 25; replay++) {
        final session = GameSessionOrder.next(
            'rumbled-tier-test-${difficulty.name}', pool, (w) => w.word,
            count: GameSessionOrder.roundLength(difficulty));
        expect(session, hasLength(GameSessionOrder.roundLength(difficulty)));
        expect(session.map((w) => w.word).toSet(), hasLength(session.length));
        expect(session.every((w) => fits(difficulty, w.word)), isTrue);
        expect(session.first.word, isNot(previousLast));
        previousLast = session.last.word;
        drawn.addAll(session.map((w) => w.word));
      }
      expect(drawn.take(pool.length).toSet(), pool.map((w) => w.word).toSet(),
          reason: 'Every word should appear before the pool repeats');
    }
  });

  for (final difficulty in Difficulty.values) {
    testWidgets('$difficulty launches the correct tier and number of tiles',
        (tester) async {
      SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
      mockProgressAudio();
      final provider =
          await mount(tester, RumbledWordsScreen(difficulty: difficulty));
      final scaffold = tester.widget<GameScaffold>(find.byType(GameScaffold));
      expect(scaffold.difficulty, difficulty);
      expect(scaffold.total, GameSessionOrder.roundLength(difficulty));
      final word =
          tester.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
      expect(fits(difficulty, word), isTrue, reason: word);
      expect(rumbledWordsFor(difficulty).map((w) => w.word), contains(word));
      for (var i = 0; i < word.length; i++) {
        expect(find.byKey(ValueKey('word-tile-$i')), findsOneWidget);
        expect(find.byKey(ValueKey('word-slot-$i')), findsOneWidget);
      }
      expect(find.byKey(ValueKey('word-tile-${word.length}')), findsNothing);
      expect(tester.takeException(), isNull);
      await close(tester, provider);
    });
  }
}
