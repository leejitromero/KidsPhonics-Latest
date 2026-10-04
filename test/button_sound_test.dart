import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/services/audio_service.dart';
import 'package:kidsphonics/services/local_audio_focus.dart';
import 'package:kidsphonics/widgets/button_sound.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

class _LocalAssetCache extends AudioCache {
  @override
  Future<Uri> fetchToMemory(String fileName) async =>
      Uri.file('${Directory.current.path}/assets/$fileName');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AudioService audio;
  late AudioCache previousCache;
  late List<MethodCall> calls;

  setUp(() {
    mockProgressAudio();
    calls = [];
    previousCache = AudioCache.instance;
    AudioCache.instance = _LocalAssetCache();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'), (call) async {
      calls.add(call);
      final id = (call.arguments as Map)['playerId'];
      if (call.method == 'create') {
        messenger.setMockMethodCallHandler(
            MethodChannel('xyz.luan/audioplayers/events/$id'),
            (_) async => null);
      }
      if (call.method == 'setSourceUrl') {
        await messenger.handlePlatformMessage(
            'xyz.luan/audioplayers/events/$id',
            const StandardMethodCodec().encodeSuccessEnvelope(
                {'event': 'audio.onPrepared', 'value': true}),
            (_) {});
      }
      return null;
    });
    audio = AudioService();
    audio.enabled = true;
  });

  tearDown(() {
    audio.dispose();
    AudioCache.instance = previousCache;
  });

  test('click uses the WAV and leaves speech and answer playback alone',
      () async {
    final speechFocus = LocalAudioFocus.claim();
    await audio.playTap();
    expect(LocalAudioFocus.isCurrent(speechFocus), isTrue);
    final clickSource = calls.singleWhere((c) => c.method == 'setSourceUrl');
    expect((clickSource.arguments as Map)['url'], endsWith('button_click.wav'));
    final clickId = (clickSource.arguments as Map)['playerId'];
    expect(
        calls
            .where((c) => c.method == 'stop')
            .every((c) => (c.arguments as Map)['playerId'] == clickId),
        isTrue);

    calls.clear();
    await audio.playCorrect();
    expect(
        calls
            .where((c) => c.method == 'stop')
            .any((c) => (c.arguments as Map)['playerId'] == clickId),
        isFalse);
    calls.clear();
    await audio.playTap();
    expect(
        calls
            .where((c) => c.method == 'stop')
            .every((c) => (c.arguments as Map)['playerId'] == clickId),
        isTrue);
  });

  test('muting cancels pending clicks and still allows button actions',
      () async {
    final pending = audio.playTap();
    audio.enabled = false;
    await pending;
    expect(calls.where((c) => c.method == 'resume'), isEmpty);
    var actions = 0;
    withButtonSound(() => actions++)!();
    await audio.playTap();
    expect(actions, 1);
    expect(calls.where((c) => c.method == 'resume'), isEmpty);
    expect(withButtonSound(null), isNull);
    expect(withSelectionSound<int>(null), isNull);
  });

  test('selection callbacks preserve their values', () async {
    int? selected;
    withSelectionSound<int>((value) => selected = value)!(3);
    expect(selected, 3);
    // Drain asynchronous player work before disposing the service.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(calls.where((c) => c.method == 'resume'), hasLength(1));
  });

  testWidgets('shared card plays one click for its nested action button',
      (tester) async {
    var actions = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: LearnerActivityCard(
                title: 'Lesson',
                description: 'Practice',
                icon: Icons.school,
                onPressed: () => actions++))));
    await tester.runAsync(() async {
      await tester.tap(find.text('Play'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    expect(actions, 1);
    expect(calls.where((c) => c.method == 'resume'), hasLength(1),
        reason: calls.map((c) => '${c.method}: ${c.arguments}').join('\n'));
    await tester.runAsync(() async {
      audio.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
  });

  testWidgets('disabled buttons stay silent; keyboard activation clicks',
      (tester) async {
    var actions = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      ElevatedButton(
          onPressed: withButtonSound(null), child: const Text('Off')),
      ElevatedButton(
          autofocus: true,
          onPressed: withButtonSound(() => actions++),
          child: const Text('Go')),
    ]))));
    await tester.pump();
    await tester.tap(find.text('Off'));
    expect(calls.where((c) => c.method == 'resume'), isEmpty);
    await tester.runAsync(() async {
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    expect(actions, 1);
    expect(calls.where((c) => c.method == 'resume'), hasLength(1),
        reason: calls.map((c) => '${c.method}: ${c.arguments}').join('\n'));
    await tester.runAsync(() async {
      audio.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
  });
}
