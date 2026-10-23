import 'dart:async';
import 'package:flutter/widgets.dart';
import '../data/lesson_instruction_scripts.dart';

/// One sentence per supplied recording. Spoken steps advance on completion only.
class LessonIntroductionSequence extends ValueNotifier<LessonIntroductionStatus>
    with WidgetsBindingObserver {
  LessonIntroductionSequence() : super(LessonIntroductionStatus.pending) {
    WidgetsBinding.instance.addObserver(this);
  }
  int _generation = 0;
  bool _disposed = false;
  Timer? _silentTimer;
  Completer<void>? _silentDelay;
  Future<void> Function()? _stop;
  bool get finished =>
      value == LessonIntroductionStatus.finished ||
      value == LessonIntroductionStatus.interrupted;

  Future<void> _captionFrame() {
    final rendered = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => rendered.complete());
    WidgetsBinding.instance.scheduleFrame();
    return rendered.future;
  }

  void _cancelSilentDelay() {
    _silentTimer?.cancel();
    _silentTimer = null;
    final delay = _silentDelay;
    _silentDelay = null;
    if (delay != null && !delay.isCompleted) delay.complete();
  }

  Future<void> _readSilently(String text) async {
    final delay = _silentDelay = Completer<void>();
    final words = text.split(RegExp(r'\s+')).length;
    _silentTimer = Timer(Duration(milliseconds: 1200 + words * 350), () {
      if (!delay.isCompleted) delay.complete();
    });
    await delay.future;
    if (identical(delay, _silentDelay)) _cancelSilentDelay();
  }

  Future<bool> run({
    required String lesson,
    required Future<bool> Function(String) play,
    required Future<void> Function() stop,
    required bool Function() voiceEnabled,
    required bool Function() isCurrent,
  }) async {
    final generation = ++_generation;
    _cancelSilentDelay();
    _stop = stop;
    bool current() => !_disposed && generation == _generation && isCurrent();
    final script = lessonInstructionScripts[lesson]!;
    for (var part = 0; part < 2; part++) {
      if (!current()) return false;
      value = part == 0
          ? LessonIntroductionStatus.pending
          : LessonIntroductionStatus.second;
      // Paint the exact sentence before starting its corresponding MP3.
      await _captionFrame();
      if (!current()) return false;
      final spoken = voiceEnabled();
      var completed = false;
      if (spoken) {
        try {
          completed = await play('$lesson-${part + 1}');
        } catch (_) {
          /* Keep the instruction readable if audio is unavailable. */
        }
      }
      if (!current()) return false;
      if (spoken && !voiceEnabled()) {
        interrupt();
        return false;
      }
      if (!completed) {
        // A reading fallback only for Voice Off or a failed file; never a clock
        // for advancing speech that is still playing.
        await _readSilently(script[part]);
        if (!current()) return false;
      }
    }
    _stop = null;
    value = LessonIntroductionStatus.finished;
    await _captionFrame();
    return current();
  }

  void interrupt() {
    if (_disposed) return;
    _generation++;
    _cancelSilentDelay();
    final stop = _stop;
    _stop = null;
    value = LessonIntroductionStatus.interrupted;
    if (stop != null) unawaited(stop());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) interrupt();
  }

  @override
  void dispose() {
    interrupt();
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
