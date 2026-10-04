import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/blending_lesson_data.dart';

enum BlendingPhase { intro, puzzle, blending, complete }

class BlendingLessonController extends ChangeNotifier {
  BlendingLessonController(
      {required this.play,
      required this.stop,
      this.voiceEnabled = true,
      Random? random})
      : _random = random ?? Random() {
    _shuffle();
  }
  final Future<bool> Function(String) play;
  final Future<void> Function() stop;
  final Random _random;
  bool voiceEnabled;
  int index = 0;
  final List<int?> _slots = [null, null, null];
  List<int?> get slots => List.unmodifiable(_slots);
  List<int> order = [2, 0, 1];
  int? selected, highlighted;
  bool tryAnother = false,
      joined = false,
      running = false,
      audioUnavailable = false;
  BlendingPhase phase = BlendingPhase.puzzle;
  BlendingLessonWord get word => blendingLessonWords[index];
  bool get complete => _slots.every((piece) => piece != null);
  bool used(int piece) => _slots.contains(piece);
  int _generation = 0, _jobs = 0;
  bool _disposed = false;
  Future<void> _queue = Future.value(), _ready = Future.value();
  Timer? _timer;
  Completer<void>? _delay;
  bool _current(int generation) => !_disposed && generation == _generation;

  void _shuffle() {
    order = [0, 1, 2]..shuffle(_random);
    if (order.map((i) => word.word[i]).join() == word.word) {
      order = [2, 0, 1];
    }
  }

  void _cancelDelay() {
    _timer?.cancel();
    _timer = null;
    final delay = _delay;
    _delay = null;
    if (delay != null && !delay.isCompleted) delay.complete();
  }

  void _invalidate() {
    _generation++;
    _cancelDelay();
    _queue = Future.value();
    _jobs = 0;
    running = false;
    highlighted = null;
    audioUnavailable = false;
    _ready = stop().catchError((Object _) {});
  }

  Future<void> _pause(int milliseconds, int generation) async {
    if (!_current(generation)) return;
    final delay = Completer<void>();
    _delay = delay;
    _timer = Timer(Duration(milliseconds: milliseconds), () {
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
      await _pause(450, generation);
    } else {
      var success = false;
      try {
        success = await play(phrase);
      } catch (_) {/* Allow visual practice. */}
      if (!_current(generation)) return false;
      if (!success) {
        audioUnavailable = true;
        notifyListeners();
        await _pause(450, generation);
      }
    }
    return _current(generation);
  }

  void _enqueue(Future<void> Function(int generation) action) {
    final generation = _generation;
    _jobs++;
    running = true;
    notifyListeners();
    _queue = _queue.then((_) async {
      await _ready;
      if (!_current(generation)) return;
      await action(generation);
      if (!_current(generation)) return;
      _jobs--;
      running = _jobs > 0;
      notifyListeners();
    });
  }

  void introduce() {
    if (_disposed) return;
    _invalidate();
    phase = BlendingPhase.intro;
    _enqueue((generation) async {
      if (!await _cue('blend-intro', generation)) return;
      phase = BlendingPhase.puzzle;
    });
  }

  bool canPlace(int piece, int slot) =>
      !_disposed &&
      phase != BlendingPhase.intro &&
      piece >= 0 &&
      piece < 3 &&
      slot >= 0 &&
      slot < 3 &&
      !used(piece) &&
      _slots[slot] == null &&
      word.word[piece] == word.word[slot];

  void choose(int piece) {
    if (_disposed || piece < 0 || piece > 2 || used(piece)) return;
    selected = selected == piece ? null : piece;
    tryAnother = false;
    notifyListeners();
  }

  void reject() {
    if (_disposed || complete || phase == BlendingPhase.intro || tryAnother) {
      return;
    }
    tryAnother = true;
    _enqueue((generation) async {
      await _cue('blend-try-another', generation);
    });
  }

  bool place(int piece, int slot) {
    if (!canPlace(piece, slot)) {
      reject();
      return false;
    }
    _slots[slot] = piece;
    selected = null;
    tryAnother = false;
    _enqueue((generation) async {
      highlighted = slot;
      notifyListeners();
      if (!await _cue(word.soundAudio(slot), generation)) return;
      highlighted = null;
    });
    if (complete) _enqueue((generation) => _blend(generation, celebrate: true));
    return true;
  }

  Future<void> _blend(int generation, {required bool celebrate}) async {
    phase = celebrate ? BlendingPhase.blending : BlendingPhase.puzzle;
    joined = false;
    tryAnother = false;
    for (var slot = 0; slot < 3; slot++) {
      if (!_current(generation)) return;
      highlighted = slot;
      notifyListeners();
      if (!await _cue(word.soundAudio(slot), generation)) return;
      await _pause(160, generation);
    }
    if (!_current(generation)) return;
    highlighted = null;
    joined = celebrate;
    notifyListeners();
    await _pause(celebrate ? 550 : 100, generation);
    if (!await _cue(word.wordAudio, generation)) return;
    if (celebrate) {
      phase = BlendingPhase.complete;
      notifyListeners();
      await _cue(word.praiseAudio, generation);
    }
  }

  void hearAgain() {
    if (_disposed) return;
    _invalidate();
    phase = BlendingPhase.puzzle;
    _enqueue((generation) => _blend(generation, celebrate: complete));
  }

  void reset() {
    if (_disposed) return;
    _invalidate();
    _slots.fillRange(0, 3, null);
    selected = null;
    joined = false;
    tryAnother = false;
    phase = BlendingPhase.puzzle;
    _shuffle();
    notifyListeners();
  }

  void next() {
    if (_disposed || index == blendingLessonWords.length - 1) return;
    index++;
    reset();
  }

  void pause() {
    if (_disposed) return;
    _invalidate();
    if (phase != BlendingPhase.complete) phase = BlendingPhase.puzzle;
    notifyListeners();
  }

  void setVoiceEnabled(bool enabled) {
    if (voiceEnabled == enabled) return;
    voiceEnabled = enabled;
    pause();
  }

  @override
  void dispose() {
    _invalidate();
    _disposed = true;
    super.dispose();
  }
}
