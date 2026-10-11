import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/learning_progress.dart';
import 'parent_auth_service.dart';
import 'preference_write_queue.dart';

/// One foreground clock for the whole application, independent of routes.
class ScreenTimeService extends ChangeNotifier {
  ScreenTimeService(this._prefs, this._auth,
      {DateTime Function()? now, int Function()? elapsedMilliseconds})
      : _now = now ?? DateTime.now {
    _watch.start();
    try {
      final saved = _prefs.get('screenTimeStateV1');
      final value = jsonDecode(saved is String ? saved : '{}');
      if (value is Map<String, dynamic>) _snapshot = value;
    } on FormatException {
      // Fall back to the existing keys for old or damaged snapshots.
    }
    _elapsed = elapsedMilliseconds ?? () => _watch.elapsedMilliseconds;
    _date = _read<String>('screenTimeDateV2', '');
    _usedMs = _read<int>('screenTimeUsedSecondsV2', 0).clamp(0, 86400) * 1000;
    _extra = _read<int>('extraTimeSecondsTodayV1', 0).clamp(0, 86400);
    _enabled = _read<bool>(
        'screenTimeLimitEnabledV2', _read<bool>('timeLimit', false));
    _limit = _read<int>('screenTimeLimitMinutesV2', 30);
    if (!limitOptions.contains(_limit)) _limit = 30;
    _bypass = _read<String>('limitBypassDateV1', '');
    _warnings = _read<int>('screenTimeWarningsV2', 0);
    refreshDailyState();
  }
  static const limitOptions = [15, 30, 45, 60, 90];
  final SharedPreferences _prefs;
  final ParentAuthService _auth;
  final DateTime Function() _now;
  final Stopwatch _watch = Stopwatch();
  late final int Function() _elapsed;
  Timer? _timer;
  late String _date, _bypass;
  late int _usedMs, _extra, _limit, _warnings;
  late bool _enabled;
  bool _foreground = false;
  bool _disposed = false;
  bool _parent = false;
  int? _last;
  int _lastSave = 0;
  final _saveQueue = PreferenceWriteQueue();
  bool get hasUnsavedChanges => _saveQueue.lastError != null;
  Map<String, dynamic> _snapshot = {};
  final _warningStream = StreamController<int>.broadcast();
  Stream<int> get warnings => _warningStream.stream;
  T _read<T>(String key, T fallback) {
    final value = _snapshot.containsKey(key) ? _snapshot[key] : _prefs.get(key);
    return value is T ? value : fallback;
  }

  bool get isLimitEnabled => _enabled;
  String get dateKey => _date;
  int get dailyLimitMinutes => _limit;
  int get usedSecondsToday => _usedMs ~/ 1000;
  int get extraSecondsToday => _extra;
  int get allowedSecondsToday => _limit * 60 + _extra;
  int get remainingSeconds =>
      (allowedSecondsToday - usedSecondsToday).clamp(0, 172800);
  bool get isBypassedToday => _bypass == _date;
  bool get isLimitReached =>
      _enabled && !isBypassedToday && remainingSeconds == 0;
  bool get _counting => _foreground && !_parent && !isLimitReached;

  void refreshDailyState() {
    final today = localDateKey(_now());
    if (_date == today) return;
    _date = today;
    _usedMs = 0;
    _extra = 0;
    _bypass = '';
    _warnings = 0;
    _last = _elapsed();
    unawaited(save());
  }

  void tick() {
    if (_disposed) return;
    final before = (usedSecondsToday, _date, isLimitReached);
    final elapsed = _elapsed();
    final previous = _last;
    final oldDate = _date;
    refreshDailyState();
    if (_counting && previous != null) {
      var delta = (elapsed - previous).clamp(0, 86400000);
      if (oldDate != _date) {
        final now = _now();
        delta = delta.clamp(
            0,
            now
                .difference(DateTime(now.year, now.month, now.day))
                .inMilliseconds);
      }
      _usedMs += delta;
      if (_enabled && !isBypassedToday) {
        _usedMs = _usedMs.clamp(0, allowedSecondsToday * 1000);
      }
    }
    _last = elapsed;
    if (_counting && _enabled && !isBypassedToday) {
      for (final minutes in [5, 1]) {
        final bit = minutes == 5 ? 1 : 2;
        if (remainingSeconds <= minutes * 60 && (_warnings & bit) == 0) {
          _warnings |= bit;
          _warningStream.add(minutes);
          unawaited(save());
        }
      }
    }
    // Save changed usage at ten-second checkpoints and immediately at the cap.
    if (_usedMs != _savedUsedMs &&
        (elapsed - _lastSave >= 10000 || isLimitReached)) {
      unawaited(save());
    }
    if (before != (usedSecondsToday, _date, isLimitReached)) _changed();
  }

  int _savedUsedMs = -1;
  void startTracking() {
    if (_disposed) return;
    refreshDailyState();
    if (_foreground) return;
    _foreground = true;
    _last = _elapsed();
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => tick());
    _changed();
  }

  Future<void> pauseTracking() {
    tick();
    _foreground = false;
    _last = null;
    _timer?.cancel();
    _timer = null;
    return save();
  }

  void setParentActive(bool active) {
    tick();
    _parent = active;
    _last = _elapsed();
    unawaited(save());
  }

  Future<void> setDailyLimit(int minutes) async {
    _auth.requireSession();
    if (!limitOptions.contains(minutes)) throw ArgumentError.value(minutes);
    tick();
    _limit = minutes;
    await save();
    _changed();
  }

  Future<void> setLimitEnabled(bool enabled) async {
    _auth.requireSession();
    tick();
    _enabled = enabled;
    await save();
    _changed();
  }

  Future<void> addExtraTime(int minutes) async {
    _auth.requireSession();
    if (![10, 15, 30].contains(minutes)) throw ArgumentError.value(minutes);
    tick();
    _extra = (_extra + minutes * 60).clamp(0, 86400);
    await save();
    _changed();
  }

  Future<void> bypassLimitForToday() async {
    _auth.requireSession();
    tick();
    _bypass = _date;
    await save();
    _changed();
  }

  Future<void> save() async {
    _lastSave = _elapsed();
    final savedUsage = _usedMs;
    final values = <String, Object>{
      'screenTimeDateV2': _date,
      'screenTimeUsedSecondsV2': usedSecondsToday,
      'screenTimeLimitEnabledV2': _enabled,
      'screenTimeLimitMinutesV2': _limit,
      'extraTimeSecondsTodayV1': _extra,
      'limitBypassDateV1': _bypass,
      'screenTimeWarningsV2': _warnings,
    };
    final errorBefore = hasUnsavedChanges;
    final saved = await _saveQueue.save(_prefs, {
      'screenTimeStateV1': jsonEncode(values),
      ...Map.of(values)..remove('screenTimeDateV2'),
      'screenTimeDateV2': _date,
    });
    if (saved) _savedUsedMs = savedUsage;
    if (errorBefore != hasUnsavedChanges) _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _watch.stop();
    unawaited(_warningStream.close());
    super.dispose();
  }
}
