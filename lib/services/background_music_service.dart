import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Independent music channel. Speech/effects have priority over the music.
class BackgroundMusicService {
  BackgroundMusicService({AudioPlayer? player}) : _player = player;
  static final instance = BackgroundMusicService();
  AudioPlayer? _player;
  bool _enabled = true, _active = false, _loaded = false;
  double _volume = .12;
  final Set<Object> _holds = {};
  final Map<AudioPlayer, StreamSubscription<PlayerState>> _subscriptions = {};
  final Map<AudioPlayer, StreamSubscription<void>> _completions = {};
  final Map<AudioPlayer, Object> _foregroundOwners = {};
  Future<void> _pending = Future.value();

  bool get shouldPlay => _enabled && _active && _volume > 0 && _holds.isEmpty;

  Future<void> configure({required bool enabled, required double volume}) {
    _enabled = enabled;
    _volume = volume.isFinite ? volume.clamp(0, .4) : .12;
    return _sync();
  }

  Future<void> setActive(bool value) {
    _active = value;
    return _sync();
  }

  Future<void> hold(Object owner) {
    _holds.add(owner);
    return _sync();
  }

  Future<void> release(Object owner) {
    _holds.remove(owner);
    return _sync();
  }

  Future<void> _sync() {
    _pending = _pending.then((_) async {
      if (!shouldPlay) {
        if (_player?.state == PlayerState.playing) await _player!.pause();
        return;
      }
      final player = _player ??= AudioPlayer();
      await player.setVolume(_volume);
      if (!shouldPlay) return;
      if (!_loaded) {
        await player.setReleaseMode(ReleaseMode.loop);
        // Mix with instructional players; explicit holds handle priority.
        await player.setAudioContext(AudioContext(
          android:
              const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        ));
        await player.setSource(AssetSource('audio/carefree.mp3'));
        _loaded = true;
      }
      if (shouldPlay && player.state != PlayerState.playing) {
        await player.resume();
      }
    }).catchError((Object _) {
      // Music is optional: a decoder/device failure must not block a lesson.
    });
    return _pending;
  }

  Future<void> playForeground(AudioPlayer player, Source source,
      {required bool Function() isCurrent}) async {
    _subscriptions.putIfAbsent(
        player,
        () => player.onPlayerStateChanged.listen(
              (state) {
                if (state != PlayerState.playing) _releasePlayer(player);
              },
              onError: (Object _) => _releasePlayer(player),
            ));
    _completions.putIfAbsent(
        player,
        () => player.onPlayerComplete.listen((_) => _releasePlayer(player),
            onError: (Object _) => _releasePlayer(player)));
    final owner = Object();
    final previous = _foregroundOwners[player];
    if (previous != null) _holds.remove(previous);
    _foregroundOwners[player] = owner;
    await hold(owner);
    if (!isCurrent() || _foregroundOwners[player] != owner) {
      if (_foregroundOwners[player] == owner) _foregroundOwners.remove(player);
      await release(owner);
      return;
    }
    try {
      await player.play(source);
    } catch (_) {
      if (_foregroundOwners[player] == owner) _foregroundOwners.remove(player);
      await release(owner);
      rethrow;
    }
  }

  void forget(AudioPlayer player) {
    unawaited(_subscriptions.remove(player)?.cancel());
    unawaited(_completions.remove(player)?.cancel());
    _releasePlayer(player);
  }

  void _releasePlayer(AudioPlayer player) {
    final owner = _foregroundOwners.remove(player);
    if (owner != null) unawaited(release(owner));
  }
}
