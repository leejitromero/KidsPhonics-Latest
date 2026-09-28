import 'dart:math';
import '../models/difficulty.dart';

/// Shuffle once per round set, never during build. Separate history per game/tier.
class GameSessionOrder {
  static int roundLength(Difficulty difficulty) => switch (difficulty) {
        Difficulty.easy => 5,
        Difficulty.medium => 6,
        Difficulty.hard => 8,
      };
  static final _random = Random();
  static final Map<String, String> _previousFirst = {};
  static List<T> next<T>(
      String key, Iterable<T> source, String Function(T) identity,
      {int? count}) {
    final items = source.toList()..shuffle(_random);
    if (items.length > 1 && identity(items.first) == _previousFirst[key]) {
      final alternatives = [
        for (var i = 1; i < items.length; i++)
          if (identity(items[i]) != _previousFirst[key]) i
      ];
      if (alternatives.isNotEmpty) {
        final other = alternatives[_random.nextInt(alternatives.length)];
        final first = items.first;
        items[0] = items[other];
        items[other] = first;
      }
    }
    if (items.isNotEmpty) _previousFirst[key] = identity(items.first);
    return items.take(count ?? items.length).toList();
  }
}
