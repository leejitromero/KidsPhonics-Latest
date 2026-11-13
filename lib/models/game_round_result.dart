import 'package:flutter/foundation.dart';

/// Immutable evidence from the first submitted response to one scored item.
@immutable
class GameRoundAnswer {
  const GameRoundAnswer(
      {required this.id,
      required this.prompt,
      required this.selected,
      required this.expected,
      required this.correct,
      this.word,
      this.highlightedIndex});
  final String id, prompt, selected, expected;
  final bool correct;
  final String? word;
  final int? highlightedIndex;
}

/// A completion star encourages finishing; three stars require a perfect round.
int gameRoundStars(
    {required int correct, required int total, required bool completed}) {
  if (!completed || total <= 0) return 0;
  if (correct >= total) return 3;
  return correct * 100 >= total * 60 ? 2 : 1;
}
