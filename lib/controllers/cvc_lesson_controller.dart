import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/cvc_lesson_data.dart';

enum CvcPhase { intro, picture, individual, slowBlend, fastBlend, complete }

/// Completion-driven playback keeps the highlighted letter with its recording.
/// Every user action invalidates older playback and pending animation delays.
class CvcLessonController extends ChangeNotifier {
  CvcLessonController(
      {required this.play, required this.stop, this.voiceEnabled = true});

  final Future<bool> Function(String phrase) play;
  final Future<void> Function() stop;
  bool voiceEnabled;
  int index = 0, highlighted = -1;
  CvcPhase phase = CvcPhase.picture;
  double blend = 0;
  bool running = false, audioUnavailable = false;
  int _generation = 0;
  bool _disposed = false;
  Timer? _timer;
  Completer<void>? _delay;
  CvcLessonWord get word => cvcLessonWords[index];
  bool _current(int generation) => !_disposed && generation == _generation;

  void _cancelDelay() {
    _timer?.cancel();
    _timer = null;
    final delay = _delay;
    _delay = null;
    if (delay != null && !delay.isCompleted) delay.complete();
  }

  Future<void> _pause(Duration duration, int generation) async {
    if (!_current(generation)) return;
    final delay = Completer<void>();
    _delay = delay;
    _timer = Timer(duration, () {
      if (!delay.isCompleted) delay.complete();
      if (identical(_delay, delay)) {
        _delay = null;
        _timer = null;
      }
    });
    await delay.future;
  }

  Future<bool> _cue(String phrase, int generation) async {
    if (!_current(generation)) return false;
    if (!voiceEnabled) {
      await _pause(const Duration(milliseconds: 650), generation);
    } else {
      bool success;
      try {
        success = await play(phrase);
      } catch (_) {
        success = false;
      }
      if (!_current(generation)) return false;
      if (!success) {
        audioUnavailable = true;
        notifyListeners();
        await _pause(const Duration(milliseconds: 650), generation);
      }
    }
    return _current(generation);
  }

  void _show(CvcPhase next, {int letter = -1, double progress = 0}) {
    phase = next;
    highlighted = letter;
    blend = progress;
    notifyListeners();
  }

  Future<void> start({bool introduction = false}) async {
    if (_disposed) return;
    final generation = ++_generation;
    _cancelDelay();
    running = true;
    audioUnavailable = false;
    _show(introduction ? CvcPhase.intro : CvcPhase.picture);
    await stop();
    if (!_current(generation)) return;
    if (introduction && !await _cue('cvc-intro', generation)) {
      return;
    }
    _show(CvcPhase.picture);
    if (!await _cue(word.wordAudio, generation)) return;
    await _pause(const Duration(milliseconds: 450), generation);
    for (final stage in [
      CvcPhase.individual,
      CvcPhase.slowBlend,
      CvcPhase.fastBlend
    ]) {
      for (var i = 0; i < 3; i++) {
        if (!_current(generation)) return;
        final progress = switch (stage) {
          CvcPhase.slowBlend => (i + 1) * .20,
          CvcPhase.fastBlend => .60 + (i + 1) * (.40 / 3),
          _ => 0.0,
        };
        _show(stage, letter: i, progress: progress);
        if (!await _cue(word.soundAudio(i), generation)) return;
        await _pause(
            Duration(milliseconds: stage == CvcPhase.fastBlend ? 60 : 420),
            generation);
      }
    }
    if (!_current(generation)) return;
    _show(CvcPhase.complete, progress: 1);
    if (!await _cue(word.wordAudio, generation)) return;
    if (!await _cue(word.praiseAudio, generation)) return;
    running = false;
    notifyListeners();
  }

  Future<void> hearLetter(int letter) async {
    if (_disposed || letter < 0 || letter > 2) return;
    final generation = ++_generation;
    _cancelDelay();
    running = true;
    audioUnavailable = false;
    _show(CvcPhase.individual, letter: letter);
    await stop();
    if (!await _cue(word.soundAudio(letter), generation)) return;
    highlighted = -1;
    running = false;
    notifyListeners();
  }

  Future<void> select(int next) async {
    if (_disposed ||
        next < 0 ||
        next >= cvcLessonWords.length ||
        next == index) {
      return;
    }
    index = next;
    await start();
  }

  void pause() {
    if (_disposed) return;
    _generation++;
    _cancelDelay();
    running = false;
    highlighted = -1;
    unawaited(stop());
    notifyListeners();
  }

  void setVoiceEnabled(bool value) {
    if (voiceEnabled == value) return;
    voiceEnabled = value;
    pause();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _cancelDelay();
    unawaited(stop());
    super.dispose();
  }
}
