import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/services/background_music_service.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

class MusicPlayer extends AudioPlayer {
  PlayerState current = PlayerState.stopped;
  final events = StreamController<PlayerState>.broadcast(sync: true);
  final completions = StreamController<void>.broadcast(sync: true);
  int starts = 0, loads = 0;
  double actualVolume = 0;
  ReleaseMode? actualReleaseMode;
  bool fail = false;
  @override
  PlayerState get state => current;
  @override
  Stream<PlayerState> get onPlayerStateChanged => events.stream;
  @override
  Stream<void> get onPlayerComplete => completions.stream;
  @override
  Future<void> setVolume(double value) async => actualVolume = value;
  @override
  Future<void> setReleaseMode(ReleaseMode value) async => actualReleaseMode = value;
  @override
  Future<void> setAudioContext(AudioContext ctx) async {}
  @override
  Future<void> setSource(Source source) async {
    loads++;
  }

  @override
  Future<void> resume() async {
    starts++;
    current = PlayerState.playing;
  }

  @override
  Future<void> pause() async {
    current = PlayerState.paused;
  }

  @override
  Future<void> play(Source source,
      {double? volume,
      double? balance,
      AudioContext? ctx,
      Duration? position,
      PlayerMode? mode}) async {
    if (fail) throw StateError('decoder failure');
    current = PlayerState.playing;
    events.add(current);
    starts++;
  }

  void complete() {
    current = PlayerState.completed;
    events.add(current);
  }

  @override
  Future<void> dispose() async {
    await events.close();
    await completions.close();
    await super.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({});
  });

  test(
      'music loops softly, pauses for overlapping holds and resumes its source',
      () async {
    final player = MusicPlayer();
    final music = BackgroundMusicService(player: player);
    await music.setActive(true);
    expect(player.actualReleaseMode, ReleaseMode.loop);
    expect(player.actualVolume, .12);
    final voice = Object(), microphone = Object();
    await music.hold(voice);
    await music.hold(microphone);
    expect(player.state, PlayerState.paused);
    await music.release(voice);
    expect(player.state, PlayerState.paused);
    await music.release(microphone);
    expect(player.state, PlayerState.playing);
    expect(player.loads, 1);
    await music.setActive(false);
    await music.configure(enabled: true, volume: .2);
    expect(player.state, PlayerState.paused);
    await music.setActive(true);
    await music.configure(enabled: false, volume: .2);
    expect(player.state, PlayerState.paused);
    await player.dispose();
  });

  test('speech completion, stale requests and decoder failure release music',
      () async {
    final player = MusicPlayer(), speech = MusicPlayer();
    final music = BackgroundMusicService(player: player);
    await music.setActive(true);
    await music.playForeground(speech, AssetSource('word.wav'),
        isCurrent: () => true);
    expect(player.state, PlayerState.paused);
    speech.complete();
    await music.configure(enabled: true, volume: .12);
    expect(player.state, PlayerState.playing);
    await music.playForeground(speech, AssetSource('word.wav'),
        isCurrent: () => false);
    expect(speech.starts, 1);
    expect(player.state, PlayerState.playing);
    speech.fail = true;
    await expectLater(
        music.playForeground(speech, AssetSource('bad.wav'),
            isCurrent: () => true),
        throwsStateError);
    expect(player.state, PlayerState.playing);
    music.forget(speech);
    await music.setActive(false);
    await speech.dispose();
    await player.dispose();
  });

  test('music controls persist separately from voice and effects', () async {
    final provider = AppProvider();
    await provider.ready;
    await provider.setMusicVolume(.24);
    await provider.toggleMusic();
    provider.dispose();
    final restored = AppProvider();
    await restored.ready;
    expect(restored.musicEnabled, false);
    expect(restored.musicVolume, .24);
    expect(restored.voiceEnabled, true);
    expect(restored.sfxEnabled, true);
    await restored.setMusicVolume(9);
    expect(restored.musicVolume, .4);
    restored.dispose();
  });

  test('music and attribution are bundled offline', () {
    final audio = File('assets/audio/carefree.mp3').readAsBytesSync();
    expect(audio.length, greaterThan(1000000));
    expect(String.fromCharCodes(audio.take(3)), 'ID3');
    final credit = File('assets/audio/carefree-LICENSE.txt').readAsStringSync();
    expect(credit, contains('Kevin MacLeod'));
    expect(credit, contains('https://creativecommons.org/licenses/by/4.0/'));
  });
}
