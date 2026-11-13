import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/preference_write_queue.dart';

/// Each visit opens a stable shuffled lesson, prioritizing words not yet shown.
/// Browsing history is separate from completed practice and game draw history.
class LessonWordOrder {
  static LessonWordHistory _history = LessonWordHistory();

  static void initialize(SharedPreferences preferences) {
    if (!identical(_history.preferences, preferences)) {
      _history = LessonWordHistory(preferences: preferences);
    }
  }

  static Future<bool> get saved => _history.saved;

  static LessonWordSession<T> open<T>(
          String key, Iterable<T> source, String Function(T) identity) =>
      _history.open(key, source, identity);
}

class LessonWordSession<T> {
  LessonWordSession._(List<T> words, this._shown)
      : words = List.unmodifiable(words);

  final List<T> words;
  final Future<bool> Function(int) _shown;
  int? _lastShown;

  Future<bool> show(int index) {
    if (index < 0 || index >= words.length || index == _lastShown) {
      return Future.value(true);
    }
    _lastShown = index;
    return _shown(index);
  }
}

class LessonWordHistory {
  LessonWordHistory({this.preferences, Random? random})
      : _random = random ?? Random() {
    _restore();
  }

  static const storageKey = 'lessonWordOrderV1';
  final SharedPreferences? preferences;
  final Random _random;
  final _lessons = <String, _LessonHistory>{};
  final _writes = PreferenceWriteQueue();
  Future<bool> _saved = Future.value(true);
  Future<bool> get saved => _saved;

  void _restore() {
    final value = preferences?.get(storageKey);
    if (value is! String) return;
    try {
      final data = jsonDecode(value);
      if (data is! Map || data['version'] != 1 || data['lessons'] is! Map) {
        return;
      }
      for (final entry in (data['lessons'] as Map).entries) {
        if (entry.key is! String) continue;
        final history = _LessonHistory.fromJson(entry.value);
        if (history != null) _lessons[entry.key as String] = history;
      }
    } on FormatException {
      // A damaged browsing history must not block lessons or saved progress.
    }
  }

  LessonWordSession<T> open<T>(
      String key, Iterable<T> source, String Function(T) identity) {
    final items = {for (final item in source) identity(item): item};
    final pool = items.keys.toSet();
    final previous = _lessons[key];
    final pending = <String>{
      ...?previous?.remaining.where(pool.contains),
      ...pool.difference(previous?.pool ?? {}),
    };
    if (pending.isEmpty) pending.addAll(pool);
    final history = _LessonHistory(pool, pending,
        first: previous?.first, last: previous?.last);
    _lessons[key] = history;
    final unseen = pending.toList()..shuffle(_random);
    final seen = pool.difference(pending).toList()..shuffle(_random);
    if (unseen.isNotEmpty) {
      // Never skip an unseen word just to vary the opening word.
      final notLast = unseen.where((id) => id != history.last).toList();
      final preferred = notLast.where((id) => id != history.first).toList();
      final first = preferred.isNotEmpty
          ? preferred.first
          : notLast.isNotEmpty
              ? notLast.first
              : unseen.first;
      unseen
        ..remove(first)
        ..insert(0, first);
    }
    final order = [...unseen, ...seen];
    var opened = false;
    return LessonWordSession._([for (final id in order) items[id]!], (index) {
      // A stale covered route cannot consume a newer session's pending words.
      if (!identical(_lessons[key], history)) return Future.value(true);
      final id = order[index];
      if (!opened) {
        history.first = id;
        opened = true;
      }
      history.remaining.remove(id);
      history.last = id;
      final prefs = preferences;
      if (prefs != null) {
        _saved = _writes.save(prefs, {
          storageKey: jsonEncode({
            'version': 1,
            'lessons': {
              for (final entry in _lessons.entries)
                entry.key: entry.value.toJson(),
            },
          }),
        });
      }
      return _saved;
    });
  }
}

class _LessonHistory {
  _LessonHistory(this.pool, this.remaining, {this.first, this.last});
  final Set<String> pool, remaining;
  String? first, last;

  Map<String, Object?> toJson() => {
        'pool': pool.toList(),
        'remaining': remaining.toList(),
        'first': first,
        'last': last,
      };

  static _LessonHistory? fromJson(Object? value) {
    if (value is! Map) return null;
    final pool = value['pool'], remaining = value['remaining'];
    if (pool is! List ||
        remaining is! List ||
        pool.any((id) => id is! String) ||
        remaining.any((id) => id is! String)) {
      return null;
    }
    final ids = pool.cast<String>().toSet();
    final pending = remaining.cast<String>().toSet();
    if (ids.length != pool.length ||
        pending.length != remaining.length ||
        !ids.containsAll(pending)) {
      return null;
    }
    return _LessonHistory(ids, pending,
        first: ids.contains(value['first']) ? value['first'] as String : null,
        last: ids.contains(value['last']) ? value['last'] as String : null);
  }
}
