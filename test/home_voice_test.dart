import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/home_narration.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

class _LocalCache extends AudioCache {
  @override
  Future<Uri> fetchToMemory(String name) async =>
      Uri.file('${Directory.current.path}/assets/$name');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AudioCache oldCache;
  late List<MethodCall> calls;
  setUp(() {
    mockProgressAudio();
    oldCache = AudioCache.instance;
    AudioCache.instance = _LocalCache();
    calls = [];
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
  });
  tearDown(() => AudioCache.instance = oldCache);

  List<String> sources() => calls
      .where((c) => c.method == 'setSourceUrl')
      .map((c) => (c.arguments as Map)['url'] as String)
      .toList();
  Future<void> waitFor(WidgetTester t, bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    expect(done(), isTrue,
        reason: calls.map((c) => '${c.method}: ${c.arguments}').join('\n'));
  }

  test('five real assets resolve and only the mixed intro is bundled',
      () async {
    for (final entry in homeNarrationAssets.entries) {
      expect(
          PhonicsAudioService.assetForPhrase('home-${entry.key}'), entry.value);
      expect((await rootBundle.load('assets/${entry.value}')).lengthInBytes,
          greaterThan(1000));
    }
    expect(Directory('assets/audio/home').listSync().whereType<File>(),
        hasLength(5));
  });

  testWidgets('intro, menu voices, skip, mute, lock and background lifecycle',
      (t) async {
    Future<void> finish(AppProvider p) async {
      await close(t, p);
      await t.runAsync(() async {
        await p.phonicsAudio.stop();
        p.phonicsAudio.dispose();
        p.audio.dispose();
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await t.pump();
    }

    SharedPreferences.setMockInitialValues({});
    var p = await mount(t, const HomeScreen());
    await t.pump();
    await waitFor(
        t, () => sources().any((s) => s.endsWith('kidsphonics_intro.mp3')));
    calls.clear();
    await t.tap(find.byKey(const ValueKey('home-skip-intro')));
    await waitFor(t, () => p.phonicsAudio.currentPhrase == null);
    await t.runAsync(() => p.toggleVoice());
    await t.runAsync(() => p.toggleVoice());
    await t.pump();
    expect(sources(), isEmpty);
    await finish(p);

    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    for (final destination in ['lessons', 'games', 'progress', 'parents']) {
      SharedPreferences.setMockInitialValues({});
      calls.clear();
      p = await mount(t, const HomeScreen());
      await t.pump();
      await t.ensureVisible(find.byKey(ValueKey('home-$destination')));
      await t.tap(find.byKey(ValueKey('home-$destination')));
      await waitFor(t,
          () => sources().any((s) => s.endsWith('${destination}_voice.mp3')));
      expect(find.byType(HomeScreen), findsNothing);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused
      ]) {
        t.binding.handleAppLifecycleStateChanged(state);
      }
      await t.pump();
      expect(p.phonicsAudio.currentPhrase, isNull);
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed
      ]) {
        t.binding.handleAppLifecycleStateChanged(state);
      }
      await finish(p);
    }
    SharedPreferences.setMockInitialValues(
        {'voice': false, 'gameAccess': false});
    calls.clear();
    p = await mount(t, const HomeScreen());
    await t.pump();
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(sources(), isEmpty);
    expect(p.gameAccess, isFalse);
    expect(t.widget<InkWell>(find.byKey(const ValueKey('home-games'))).onTap,
        isNull);
    await finish(p);
  });
}
