import 'dart:math';
import '../models/difficulty.dart';

/// Draws from a shuffled pool across replays, with history per game/tier.
class GameSessionOrder {
  static int roundLength(Difficulty difficulty) => switch (difficulty) {
        Difficulty.easy => 5,
        Difficulty.medium => 6,
        Difficulty.hard => 8,
      };
  static final _random = Random();
  static final Map<String, String> _previousFirst = {};
  static final Map<String, String> _previousLast = {};
  static final Map<String, Set<String>> _pools = {};
  static final Map<String, List<String>> _remaining = {};
  static List<T> next<T>(
      String key, Iterable<T> source, String Function(T) identity,
      {int? count}) {
    final items = {for (final item in source) identity(item): item};
    final length = (count ?? items.length).clamp(0, items.length);
    if (length == 0) return [];

    final pool = items.keys.toSet();
    final previousPool = _pools[key];
    if (previousPool == null ||
        previousPool.length != pool.length ||
        !previousPool.containsAll(pool)) {
      _pools[key] = pool;
      _remaining[key] = [];
    }

    final remaining = _remaining[key]!;
    final selected = <String>[];
    while (selected.length < length) {
      if (remaining.isEmpty) {
        remaining.addAll(pool.toList()..shuffle(_random));
      }
      // A session spanning two pools must still contain unique tasks.
      final candidates =
          remaining.where((id) => !selected.contains(id)).toList();
      final preferred = candidates
          .where((id) =>
              id != (selected.isEmpty ? _previousLast[key] : selected.last) &&
              (selected.isNotEmpty || id != _previousFirst[key]))
          .toList();
      final chosen = preferred.isNotEmpty ? preferred.first : candidates.first;
      remaining.remove(chosen);
      selected.add(chosen);
    }
    _previousFirst[key] = selected.first;
    _previousLast[key] = selected.last;
    return [for (final id in selected) items[id]!];
  }
}
