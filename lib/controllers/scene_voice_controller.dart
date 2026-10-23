import 'dart:async';
import 'package:flutter/widgets.dart';
import '../providers/app_provider.dart';
import '../services/phonics_audio_service.dart';

/// Completion is driven by the audio event, never a guessed delay.
class SceneVoiceController extends ChangeNotifier with WidgetsBindingObserver {
  SceneVoiceController(this.provider,
      {required this.isCurrent, this.replayOnResume = true}) {
    WidgetsBinding.instance.addObserver(this);
    provider.addListener(_settingsChanged);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }
  final AppProvider provider;
  final bool Function() isCurrent;
  final bool replayOnResume;
  bool _foreground = true, _disposed = false, _playing = false;
  int _request = 0;
  String? _phrase, _interrupted;
  bool get playing => _playing;
  bool get _allowed =>
      !_disposed &&
      _foreground &&
      isCurrent() &&
      provider.voiceEnabled &&
      !provider.timeLimitReached;

  Future<bool> play(String phrase) async {
    final request = ++_request;
    _interrupted = null;
    final previous = _phrase;
    _phrase = phrase;
    if (previous != null && provider.phonicsAudio.currentPhrase == previous) {
      unawaited(provider.phonicsAudio.stop());
    }
    if (!_allowed) {
      if (!_foreground && replayOnResume) _interrupted = phrase;
      _playing = false;
      notifyListeners();
      return false;
    }
    _playing = true;
    notifyListeners();
    try {
      await PhonicsAudioService.prepareInstruction(phrase);
      if (!_allowed || request != _request) return false;
      await provider.audio.stop();
      if (!_allowed || request != _request) return false;
      return await provider.phonicsAudio.playInstruction(phrase);
    } catch (_) {
      return false;
    } finally {
      if (!_disposed && request == _request) {
        _playing = false;
        notifyListeners();
      }
    }
  }

  void stop({bool notify = true}) {
    _request++;
    _playing = false;
    if (_phrase != null && provider.phonicsAudio.currentPhrase == _phrase) {
      unawaited(provider.phonicsAudio.stop());
    }
    if (notify && !_disposed) notifyListeners();
  }

  void _settingsChanged() {
    if (!provider.voiceEnabled || provider.timeLimitReached) {
      _interrupted = null;
    }
    if (!_allowed && _playing) stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      if (_playing && replayOnResume) _interrupted = _phrase;
      stop();
    } else if (_interrupted != null && _allowed) {
      unawaited(play(_interrupted!));
    }
  }

  @override
  void dispose() {
    stop(notify: false);
    _disposed = true;
    provider.removeListener(_settingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
