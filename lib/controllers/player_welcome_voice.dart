import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import '../providers/app_provider.dart';
import '../services/background_music_service.dart';
import '../services/local_audio_focus.dart';

/// Personalized startup speech only; lesson/game recordings stay unchanged.
class PlayerWelcomeVoice extends ChangeNotifier with WidgetsBindingObserver {
  PlayerWelcomeVoice(this.provider, {required this.isCurrent}) {
    WidgetsBinding.instance.addObserver(this);
    provider.addListener(_settingsChanged);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  static const channel = MethodChannel('kidsphonics/player_welcome');
  static int _sequence = 0;
  final AppProvider provider;
  final bool Function() isCurrent;
  bool _foreground = true, _disposed = false, _playing = false;
  String? _request;
  Completer<bool>? _cancelled;
  String _name = '', _text = '';
  bool get playing => _playing;
  String get text => _text;
  bool get _allowed =>
      !_disposed &&
      _foreground &&
      isCurrent() &&
      provider.isReady &&
      provider.voiceEnabled &&
      !provider.timeLimitReached;

  static String greeting(String name, {required bool returning}) {
    final clean = name
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .characters
        .take(24)
        .toString();
    return '${returning ? 'Welcome back' : 'Welcome'}, $clean! Let\'s learn and play!';
  }

  Future<void> _stopNative(String id) async {
    try {
      await channel.invokeMethod<bool>(
          'stop', {'id': id}).timeout(const Duration(seconds: 2));
    } catch (_) {/* Missing/unsupported speech must never block navigation. */}
  }

  Future<bool> play(String name, {required bool returning}) async {
    stop(notify: false);
    if (!_allowed || name.trim().isEmpty) return false;
    final id =
        'welcome-${DateTime.now().microsecondsSinceEpoch}-${++_sequence}';
    final cancelled = _cancelled = Completer<bool>();
    _request = id;
    _name = provider.studentName;
    _text = greeting(name, returning: returning);
    _playing = true;
    notifyListeners();
    final focus = LocalAudioFocus.claim();
    final musicOwner = Object();
    bool current() =>
        _request == id && _allowed && LocalAudioFocus.isCurrent(focus);
    try {
      await provider.audio.stop();
      await provider.phonicsAudio.stop();
      if (!current()) return false;
      await BackgroundMusicService.instance.hold(musicOwner);
      if (!current()) return false;
      final spoken = await Future.any<bool>([
        channel.invokeMethod<bool>(
            'speak', {'id': id, 'text': _text}).then((value) => value == true),
        cancelled.future,
      ]).timeout(const Duration(seconds: 22), onTimeout: () => false);
      return current() && spoken;
    } catch (_) {
      return false;
    } finally {
      // A timeout also stops native output before the opening MP3 may start.
      await _stopNative(id);
      await BackgroundMusicService.instance.release(musicOwner);
      if (!_disposed && _request == id) {
        _request = null;
        _cancelled = null;
        _playing = false;
        notifyListeners();
      }
    }
  }

  void stop({bool notify = true}) {
    final id = _request;
    if (id == null) return;
    _request = null;
    final cancelled = _cancelled;
    _cancelled = null;
    _playing = false;
    if (cancelled != null && !cancelled.isCompleted) cancelled.complete(false);
    unawaited(_stopNative(id));
    if (notify && !_disposed) notifyListeners();
  }

  void _settingsChanged() {
    if (_playing && (!_allowed || provider.studentName != _name)) stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) stop();
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
