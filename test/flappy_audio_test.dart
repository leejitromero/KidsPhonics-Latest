import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/services/audio_service.dart';
import 'package:kidsphonics/services/local_audio_focus.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

class _LocalAssetCache extends AudioCache {
  @override
  Future<Uri> fetchToMemory(String fileName) async =>
      Uri.file('${Directory.current.path}/assets/$fileName');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('each flap mixes with speech and respects muted effects', () async {
    mockProgressAudio();
    final previousCache = AudioCache.instance;
    AudioCache.instance = _LocalAssetCache();
    addTearDown(() => AudioCache.instance = previousCache);
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'), (call) async {
      calls.add(call);
      if (call.method == 'create') {
        final id = (call.arguments as Map)['playerId'];
        messenger.setMockMethodCallHandler(
            MethodChannel('xyz.luan/audioplayers/events/$id'),
            (_) async => null);
      }
      if (call.method == 'setSourceUrl') {
        final id = (call.arguments as Map)['playerId'];
        await messenger.handlePlatformMessage(
            'xyz.luan/audioplayers/events/$id',
            const StandardMethodCodec().encodeSuccessEnvelope(
                {'event': 'audio.onPrepared', 'value': true}),
            (_) {});
      }
      return null;
    });
    final audio = AudioService();
    audio.enabled = true;
    final speechFocus = LocalAudioFocus.claim();
    await audio.playFlap();
    await audio.playFlap();
    expect(LocalAudioFocus.isCurrent(speechFocus), isTrue);
    final starts = calls.where((call) => call.method == 'resume').toList();
    expect(starts, hasLength(2),
        reason: calls.map((c) => '${c.method}: ${c.arguments}').join('\n'));
    final flapId = (starts.first.arguments as Map)['playerId'];
    expect(
        calls
            .where((call) => call.method == 'stop')
            .every((call) => (call.arguments as Map)['playerId'] == flapId),
        isTrue);
    audio.enabled = false;
    await audio.stop();
    calls.clear();
    await audio.playFlap();
    expect(calls, isEmpty);
    audio.dispose();
  });
}
