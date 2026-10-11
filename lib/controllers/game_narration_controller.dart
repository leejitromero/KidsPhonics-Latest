import 'dart:async';
import 'package:flutter/foundation.dart';

/// Plays supplied letter and word recordings without generated narration or praise.
class GameNarrationController extends ChangeNotifier {
  GameNarrationController({required this.play, required this.stop});

  final Future<bool> Function(String) play;
  final Future<void> Function() stop;
  bool _enabled = true, _active = false, _disposed = false;
  bool speaking = false, audioUnavailable = false;
  String? feedback;
  int _generation = 0;
  int get generation => _generation;
  bool get enabled => _enabled;

  void updateEnvironment({required bool enabled, required bool active}) {
    final changed = enabled != _enabled || active != _active;
    final interrupted = (_enabled && !enabled) || (_active && !active);
    _enabled = enabled;
    _active = active;
    if (interrupted) {
      cancel();
    } else if (changed && !_disposed) {
      notifyListeners();
    }
  }

  int cancel() {
    _generation++;
    if (speaking) unawaited(stop());
    speaking = false;
    feedback = null;
    if (!_disposed) notifyListeners();
    return _generation;
  }

  void resetRound() {
    cancel();
  }

  Future<void> letterSound(String letter) async {
    if (!_enabled || !_active || _disposed) return;
    await _say('lesson-sound-$letter',
        message: '${letter == 'Q' ? 'Qu' : letter} sound');
  }

  Future<void> letterName(String letter) async {
    if (!_enabled || !_active || _disposed) return;
    await _say('lesson-letter-$letter', message: letter);
  }

  Future<void> word(String word) async {
    if (!_enabled || !_active || _disposed) return;
    await _say(word, message: word.toUpperCase());
  }

  Future<void> _say(String phrase, {String? message}) async {
    final request = ++_generation;
    feedback = message;
    speaking = true;
    audioUnavailable = false;
    notifyListeners();
    bool current() =>
        !_disposed && request == _generation && _enabled && _active;
    try {
      final played = await play(phrase);
      if (!current()) return;
      audioUnavailable = !played;
    } catch (_) {
      if (current()) audioUnavailable = true;
    } finally {
      if (current()) {
        speaking = false;
        feedback = null;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    cancel();
    super.dispose();
  }
}
