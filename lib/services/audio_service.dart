import 'package:audioplayers/audioplayers.dart';
import 'local_audio_focus.dart';
import 'background_music_service.dart';
import 'phonics_audio_service.dart';

/// Answer effects share a channel; button clicks and flaps mix independently.
class AudioService {
  static AudioService _instance = AudioService._internal();
  factory AudioService() =>
      _instance._disposed ? _instance = AudioService._internal() : _instance;
  AudioService._internal();
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _tapPlayer = AudioPlayer();
  Future<void>? _tapSetup;
  Future<void> _tapPending = Future.value();
  int _tapRequest = 0;
  // Flaps mix with speech: frequent taps must never cancel a letter recording.
  final AudioPlayer _flapPlayer = AudioPlayer();
  Future<void>? _flapSetup;
  Future<void> _flapPending = Future.value();
  bool _enabled = true;
  bool _disposed = false;
  int _request = 0;
  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;
    if (!value) {
      stop();
      _stopTap();
    }
  }

  // Speech and screen transitions stop answer effects, while a button's short
  // click can finish. Muting or disposing stops the click channel as well.
  Future<void> stop() async {
    _request++;
    if (_disposed) return;
    try {
      await _player.stop();
      await _flapPlayer.stop();
    } catch (_) {}
  }

  Future<void> _play(String asset) async {
    if (!_enabled || _disposed) return;
    final focus = LocalAudioFocus.claim();
    final request = _request + 1;
    await stop();
    await PhonicsAudioService().stop();
    if (_disposed ||
        !_enabled ||
        request != _request ||
        !LocalAudioFocus.isCurrent(focus)) {
      return;
    }
    try {
      await BackgroundMusicService.instance.playForeground(
          _player, AssetSource('audio/$asset'),
          isCurrent: () =>
              !_disposed &&
              _enabled &&
              request == _request &&
              LocalAudioFocus.isCurrent(focus));
    } catch (_) {}
  }

  Future<void> playTap() {
    if (!_enabled || _disposed) return Future.value();
    final request = ++_tapRequest;
    _tapPending = _tapPending.then((_) async {
      bool isCurrent() => _enabled && !_disposed && request == _tapRequest;
      if (!isCurrent()) return;
      await (_tapSetup ??= _configureTap());
      if (!isCurrent()) return;
      await _tapPlayer.stop();
      if (!isCurrent()) return;
      await _tapPlayer.play(AssetSource('audio/button_click.wav'));
      if (!isCurrent()) await _tapPlayer.stop();
    }).catchError((Object _) {
      // An unavailable audio device must never prevent a button action.
      _tapSetup = null;
    });
    return _tapPending;
  }

  Future<void> _configureTap() async {
    await _tapPlayer.setAudioContext(AudioContext(
      android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    ));
    await _tapPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> _stopTap() async {
    _tapRequest++;
    try {
      await _tapPlayer.stop();
    } catch (_) {}
  }

  Future<void> playFlap() {
    if (!_enabled || _disposed) return Future.value();
    final request = _request;
    _flapPending = _flapPending.then((_) async {
      if (!_enabled || _disposed || request != _request) return;
      await (_flapSetup ??= _configureFlap());
      if (!_enabled || _disposed || request != _request) return;
      await _flapPlayer.stop();
      await _flapPlayer.play(AssetSource('audio/tap.mp3'), volume: .45);
    }).catchError((Object _) {});
    return _flapPending;
  }

  Future<void> _configureFlap() async {
    await _flapPlayer.setAudioContext(AudioContext(
      android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    ));
    await _flapPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> playWin() => _play('win.mp3');
  Future<void> playFlip() => _play('flip.mp3');
  Future<void> playCorrect() => _play('correct.mp3');
  Future<void> playWrong() => _play('wrong.mp3');
  void dispose() {
    if (_disposed) return;
    stop();
    _stopTap();
    _disposed = true;
    BackgroundMusicService.instance.forget(_player);
    _player.dispose();
    _tapPlayer.dispose();
    _flapPlayer.dispose();
  }
}
