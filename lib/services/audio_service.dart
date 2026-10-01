import 'package:audioplayers/audioplayers.dart';
import 'local_audio_focus.dart';
import 'background_music_service.dart';
import 'phonics_audio_service.dart';

/// Existing local effects share a single playback channel.
class AudioService {
  static AudioService _instance = AudioService._internal();
  factory AudioService() =>
      _instance._disposed ? _instance = AudioService._internal() : _instance;
  AudioService._internal();
  final AudioPlayer _player = AudioPlayer();
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
    if (!value) stop();
  }

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

  Future<void> playTap() => _play('tap.mp3');
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
    _disposed = true;
    BackgroundMusicService.instance.forget(_player);
    _player.dispose();
    _flapPlayer.dispose();
  }
}
