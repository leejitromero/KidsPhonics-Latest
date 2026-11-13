import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/difficulty.dart';
import '../services/preference_write_queue.dart';

/// Draws from a shuffled pool across replays, with history per game/tier.
class GameSessionOrder {
  static int roundLength(Difficulty difficulty) => switch (difficulty) {
        Difficulty.easy => 5,
        Difficulty.medium => 6,
        Difficulty.hard => 8,
      };
  static GameSessionHistory _history = GameSessionHistory();

  /// Called after preferences load, before the app permits opening a game.
  /// Rebuilding a provider must not reset the history of an active app.
  static void initialize(SharedPreferences preferences) {
    if (!identical(_history.preferences, preferences)) {
      _history = GameSessionHistory(preferences: preferences);
    }
  }

  static Future<bool> get saved => _history.saved;

  static List<T> next<T>(
          String key, Iterable<T> source, String Function(T) identity,
          {int? count}) =>
      _history.next(key, source, identity, count: count);
}

/// Persists only selection history, never active questions, answers or rewards.
/// A round reserves its tasks once; rebuilding or pausing does not draw again.
class GameSessionHistory {
  GameSessionHistory({this.preferences, Random? random})
      : _random = random ?? Random() {
    _restore();
  }

  static const storageKey = 'gameSessionOrderV1';
  final SharedPreferences? preferences;
  final Random _random;
  final _games = <String, _DrawHistory>{};
  final _writes = PreferenceWriteQueue();
  Future<bool> _saved = Future.value(true);
  Future<bool> get saved => _saved;

  void _restore() {
    final value = preferences?.get(storageKey);
    if (value is! String) return;
    try {
      final data = jsonDecode(value);
      if (data is! Map || data['version'] != 1 || data['games'] is! Map) {
        return;
      }
      for (final entry in (data['games'] as Map).entries) {
        if (entry.key is! String) continue;
        final history = _DrawHistory.fromJson(entry.value);
        if (history != null) _games[entry.key as String] = history;
      }
    } on FormatException {
      // Damaged randomization data must not prevent games or progress loading.
    }
  }

  List<T> next<T>(String key, Iterable<T> source, String Function(T) identity,
      {int? count}) {
    final items = {for (final item in source) identity(item): item};
    final length = (count ?? items.length).clamp(0, items.length);
    if (length == 0) return [];

    final pool = items.keys.toSet();
    final history = _games.putIfAbsent(key, () => _DrawHistory({}));
    if (history.pool.length != pool.length || !history.pool.containsAll(pool)) {
      // Keep pending valid tasks when an app update adds/removes content.
      final added = pool.difference(history.pool).toList()..shuffle(_random);
      history.remaining
        ..removeWhere((id) => !pool.contains(id))
        ..addAll(added);
      history.pool = pool;
      if (!pool.contains(history.first)) history.first = null;
      if (!pool.contains(history.last)) history.last = null;
    }

    final remaining = history.remaining;
    final selected = <String>[];
    while (selected.length < length) {
      if (remaining.isEmpty) {
        remaining.addAll(pool.toList()..shuffle(_random));
      }
      // A session spanning two pools must still contain unique tasks.
      final candidates =
          remaining.where((id) => !selected.contains(id)).toList();
      // At rollover, avoiding the previous last task takes priority over
      // changing the opening task. Never skip pending tasks just for variety.
      final noRepeat = selected.isEmpty
          ? candidates.where((id) => id != history.last).toList()
          : candidates;
      final preferred = selected.isEmpty
          ? noRepeat.where((id) => id != history.first).toList()
          : noRepeat;
      final chosen = preferred.isNotEmpty
          ? preferred.first
          : noRepeat.isNotEmpty
              ? noRepeat.first
              : candidates.first;
      remaining.remove(chosen);
      selected.add(chosen);
    }
    history.first = selected.first;
    history.last = selected.last;
    final prefs = preferences;
    if (prefs != null) {
      // Capture now and serialize writes so a rapid replay cannot save an
      // older queue over a newer one. Failed storage writes leave play usable.
      _saved = _writes.save(prefs, {
        storageKey: jsonEncode({
          'version': 1,
          'games': {for (final e in _games.entries) e.key: e.value.toJson()},
        }),
      });
    }
    return [for (final id in selected) items[id]!];
  }
}

class _DrawHistory {
  _DrawHistory(this.pool, {List<String>? remaining, this.first, this.last})
      : remaining = remaining ?? [];

  Set<String> pool;
  final List<String> remaining;
  String? first, last;

  Map<String, Object?> toJson() => {
        'pool': pool.toList(),
        'remaining': remaining,
        'first': first,
        'last': last,
      };

  static _DrawHistory? fromJson(Object? value) {
    if (value is! Map) return null;
    final pool = value['pool'], remaining = value['remaining'];
    if (pool is! List ||
        remaining is! List ||
        pool.isEmpty ||
        pool.any((id) => id is! String) ||
        remaining.any((id) => id is! String)) {
      return null;
    }
    final ids = pool.cast<String>().toSet();
    final pending = remaining.cast<String>();
    if (ids.length != pool.length ||
        pending.toSet().length != pending.length ||
        !ids.containsAll(pending)) {
      return null;
    }
    return _DrawHistory(ids,
        remaining: List.of(pending),
        first: ids.contains(value['first']) ? value['first'] as String : null,
        last: ids.contains(value['last']) ? value['last'] as String : null);
  }
}
