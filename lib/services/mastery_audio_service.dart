import 'dart:async';
import 'background_music_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'phonics_audio_service.dart';

abstract interface class MasteryAudio {
  /// True only after the requested local recording finishes playing.
  Future<bool> play(String phrase);
  Future<void> stop();
  Future<void> dispose();
}

class LocalMasteryAudio implements MasteryAudio {
  final AudioPlayer _player = AudioPlayer();
  Completer<bool>? _finished;
  bool _disposed = false;
  int _request = 0;

  @override
  Future<bool> play(String phrase) async {
    if (_disposed) return false;
    final request = _request + 1;
    await stop();
    if (_disposed || request != _request) return false;
    final asset = PhonicsAudioService.assetForPhrase(phrase);
    if (asset == null) return false;
    final finished = Completer<bool>();
    _finished = finished;
    final subscription = _player.onPlayerComplete.listen((_) {
      if (request == _request && !finished.isCompleted) finished.complete(true);
    }, onError: (Object _) {
      if (!finished.isCompleted) finished.complete(false);
    });
    try {
      await rootBundle.load('assets/$asset');
      if (_disposed || request != _request || finished.isCompleted) {
        return false;
      }
      await BackgroundMusicService.instance.playForeground(
          _player, AssetSource(asset),
          isCurrent: () => !_disposed && request == _request);
      return await finished.future
          .timeout(const Duration(seconds: 30), onTimeout: () => false);
    } catch (_) {
      return false;
    } finally {
      await subscription.cancel();
      if (identical(_finished, finished)) _finished = null;
      if (!_disposed && request == _request) await stop();
    }
  }

  @override
  Future<void> stop() async {
    _request++;
    final finished = _finished;
    if (finished != null && !finished.isCompleted) finished.complete(false);
    if (!_disposed) {
      try {
        await _player.stop();
      } catch (_) {/* Playback failure stays unscored. */}
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    BackgroundMusicService.instance.forget(_player);
    await stop();
    await _player.dispose();
  }
}
