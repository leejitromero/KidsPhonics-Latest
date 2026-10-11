import '../models/difficulty.dart';
import 'game_word_data.dart';

/// Spelling tiers depend on the number of tiles the learner must arrange.
/// The shared artwork catalog's tiers cover other games, so keep them intact.
Difficulty? _spellingDifficulty(String word) {
  if (!RegExp(r'^[A-Za-z]+$').hasMatch(word)) return null;
  return switch (word.length) {
    3 => Difficulty.easy,
    4 || 5 => Difficulty.medium,
    >= 6 => Difficulty.hard,
    _ => null,
  };
}

String rumbledWordLengthLabel(Difficulty difficulty) => switch (difficulty) {
      Difficulty.easy => '3 letters',
      Difficulty.medium => '4–5 letters',
      Difficulty.hard => '6+ letters',
    };

List<GameWord> rumbledWordsFor(Difficulty difficulty) => [
      for (final word in gameWords)
        if (word.enabledInGames && _spellingDifficulty(word.word) == difficulty)
          GameWord(difficulty, word.letter, word.slug, word.word, word.frames),
    ];
