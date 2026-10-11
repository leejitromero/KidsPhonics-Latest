import 'package:shared_preferences/shared_preferences.dart';

/// Serializes checked writes; a failed operation never poisons later saves.
class PreferenceWriteQueue {
  Future<void> _tail = Future.value();
  Object? lastError;
  final Map<String, Object?> _written = {};

  Future<bool> save(SharedPreferences prefs, Map<String, Object?> snapshot) {
    final values = Map<String, Object?>.of(snapshot);
    final operation = _tail.then((_) async {
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          for (final entry in values.entries) {
            if (_written.containsKey(entry.key) &&
                _written[entry.key] == entry.value) {
              continue;
            }
            final value = entry.value;
            final bool saved;
            if (value == null) {
              saved = await prefs.remove(entry.key);
            } else if (value is bool) {
              saved = await prefs.setBool(entry.key, value);
            } else if (value is int) {
              saved = await prefs.setInt(entry.key, value);
            } else if (value is double) {
              saved = await prefs.setDouble(entry.key, value);
            } else if (value is String) {
              saved = await prefs.setString(entry.key, value);
            } else {
              throw ArgumentError.value(value, entry.key);
            }
            if (!saved) throw StateError('Unable to save ${entry.key}');
            _written[entry.key] = value;
          }
          lastError = null;
          return true;
        } catch (error) {
          lastError = error;
        }
      }
      return false;
    });
    _tail = operation.then((_) {});
    return operation;
  }
}
