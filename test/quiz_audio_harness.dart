import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _LocalQuizCache extends AudioCache {
  @override
  Future<Uri> fetchToMemory(String fileName) async =>
      Uri.file('${Directory.current.path}/assets/$fileName');
}

/// Keeps speech pending until the test sends the real playback-complete event.
class QuizAudioHarness {
  final sources = <String>[];
  final starts = <String>[];
  final calls = <String>[];
  final _players = <String, String>{};
  final _messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void install() {
    final previous = AudioCache.instance;
    AudioCache.instance = _LocalQuizCache();
    addTearDown(() => AudioCache.instance = previous);
    _messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'), (call) async {
      final arguments = call.arguments as Map;
      final id = arguments['playerId'] as String;
      calls.add('${call.method}:$id');
      if (call.method == 'create') {
        _messenger.setMockMethodCallHandler(
            MethodChannel('xyz.luan/audioplayers/events/$id'),
            (_) async => null);
      }
      if (call.method == 'setSourceUrl') {
        final source =
            Uri.decodeFull(arguments['url'] as String).replaceAll('\\', '/');
        sources.add(source);
        _players[id] = source;
        await _event(id, 'audio.onPrepared', value: true);
      }
      if (call.method == 'resume' && _players.containsKey(id)) {
        starts.add(_players[id]!);
      }
      return null;
    });
  }

  Future<void> _event(String id, String event, {Object? value}) async {
    await _messenger.handlePlatformMessage(
        'xyz.luan/audioplayers/events/$id',
        const StandardMethodCodec().encodeSuccessEnvelope(
            {'event': event, if (value != null) 'value': value}),
        (_) {});
  }

  Future<void> completeSound(String letter) async {
    final suffix = '/sounds/sound-${letter.toLowerCase()}.mp3';
    await completeSource(suffix);
  }

  /// Verify the entry recording, then count the activity's audio separately.
  Future<void> finishGameIntro(WidgetTester t, String filename) async {
    final suffix = '/game_instructions/$filename';
    for (var i = 0; i < 150 && !starts.any((s) => s.endsWith(suffix)); i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    expect(starts.where((s) => s.endsWith(suffix)), hasLength(1));
    await t.runAsync(() => completeSource(suffix));
    for (var i = 0; i < 3; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    starts.clear();
    sources.clear();
  }

  Future<void> completeSource(String suffix) async {
    final id =
        _players.entries.singleWhere((e) => e.value.endsWith(suffix)).key;
    await _event(id, 'audio.onComplete');
  }
}
