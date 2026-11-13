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
      this.playIntroduction,
      List<BlendingLessonWord> words = blendingLessonWords,
      Random? random})
      : words = List.unmodifiable(words),
        _random = random ?? Random() {
    if (this.words.isEmpty ||
        this
            .words
            .any((word) => !RegExp(r'^[A-Z]{3,7}$').hasMatch(word.word))) {
      throw ArgumentError.value(words, 'words',
          'Provide at least one word with 3 to 7 uppercase letters.');
    }
    _clearSlots();
    _shuffle();
  }
  final Future<bool> Function(String) play;
  final Future<void> Function() stop;
  Future<bool> Function()? playIntroduction;
  final Random _random;
  final List<BlendingLessonWord> words;
  bool voiceEnabled;
  int index = 0;
  final List<int?> _slots = [];
  List<int?> get slots => List.unmodifiable(_slots);
  List<int> order = [];
  int? selected, highlighted;
  Set<int> highlightedLetters = const {};
  bool tryAnother = false,
      joined = false,
      running = false,
      audioUnavailable = false;
  BlendingPhase phase = BlendingPhase.puzzle;
  BlendingLessonWord get word => words[index];
  bool get complete => _slots.every((piece) => piece != null);
  bool used(int piece) => _slots.contains(piece);
  int _generation = 0, _jobs = 0;
  bool _disposed = false;
  Future<void> _queue = Future.value(), _ready = Future.value();
  Timer? _timer;
  Completer<void>? _delay;
  bool _current(int generation) => !_disposed && generation == _generation;

  void _highlight(Iterable<int> letters) {
    highlightedLetters = Set.unmodifiable(letters);
    highlighted = highlightedLetters.isEmpty ? null : highlightedLetters.first;
  }

  void _shuffle() {
    order = List.generate(word.word.length, (i) => i)..shuffle(_random);
    if (order.map((i) => word.word[i]).join() == word.word) {
      order = [
        word.word.length - 1,
        for (var i = 0; i < word.word.length - 1; i++) i
      ];
    }
  }

  void _clearSlots() {
    _slots
      ..clear()
      ..addAll(List<int?>.filled(word.word.length, null));
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
    _highlight(const []);
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
      if (playIntroduction != null) {
        if (!await playIntroduction!()) return;
      } else {
        if (!await _cue('blend-intro-1', generation)) return;
        if (!await _cue('blend-intro-2', generation)) return;
      }
      if (!_current(generation)) return;
      phase = BlendingPhase.puzzle;
    });
  }

  bool canPlace(int piece, int slot) =>
      !_disposed &&
      phase != BlendingPhase.intro &&
      piece >= 0 &&
      piece < _slots.length &&
      slot >= 0 &&
      slot < _slots.length &&
      !used(piece) &&
      _slots[slot] == null &&
      word.word[piece] == word.word[slot];

  void choose(int piece) {
    if (_disposed || piece < 0 || piece >= _slots.length || used(piece)) return;
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
      final sound = word.placementSound(slot);
      _highlight(sound.letters);
      notifyListeners();
      if (!await _cue(sound.audio, generation)) return;
      _highlight(const []);
    });
    if (complete) _enqueue((generation) => _blend(generation, celebrate: true));
    return true;
  }

  Future<void> _blend(int generation, {required bool celebrate}) async {
    phase = celebrate ? BlendingPhase.blending : BlendingPhase.puzzle;
    joined = false;
    tryAnother = false;
    for (final sound in word.sounds) {
      if (!_current(generation)) return;
      _highlight(sound.letters);
      notifyListeners();
      if (!await _cue(sound.audio, generation)) return;
      await _pause(160, generation);
    }
    if (!_current(generation)) return;
    _highlight(word.wholeWordOnly
        ? List.generate(word.word.length, (i) => i)
        : const []);
    joined = celebrate;
    notifyListeners();
    await _pause(celebrate ? 550 : 100, generation);
    if (!await _cue(word.wordAudio, generation)) return;
    _highlight(const []);
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
    _clearSlots();
    selected = null;
    joined = false;
    tryAnother = false;
    phase = BlendingPhase.puzzle;
    _shuffle();
    notifyListeners();
  }

  void next() {
    if (_disposed || index == words.length - 1) return;
    index++;
    reset();
  }

  void previous() {
    if (_disposed || index == 0) return;
    index--;
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
