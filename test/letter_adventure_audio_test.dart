import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/letter_mastery_check_screen.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'letter_mastery_check_test.dart' show press, flushAdventure;
import 'quiz_audio_harness.dart';

// Keep real AudioPlayer lifecycle tests isolated from injected fake players.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(TestWidgetsFlutterBinding
        .instance.platformDispatcher.clearAccessibilityFeaturesTestValue);
  });
  testWidgets(
      'local recording completion unlocks sound choice on the production audio path',
      (t) async {
    final harness = QuizAudioHarness()..install();
    late AppProvider p;
    await t.runAsync(() async {
      p = AppProvider();
      await p.ready;
      await p.toggleSfx();
      // Test essential sound completion independently of optional narration.
      // Interruptible narration has dedicated tests below.
      await p.toggleVoice();
    });
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            home: LetterMasteryCheckScreen(letter: letterContent('B')))));
    await press(t, find.byKey(const ValueKey('start-adventure')));
    await press(t, find.byKey(const ValueKey('adventure-option-b')));
    await press(t, find.text('Next Challenge'));
    await press(t, find.byKey(const ValueKey('listen-lesson-sound-B')));
    bool soundStarted() =>
        harness.starts.any((s) => s.endsWith('/sounds/sound-b.mp3'));
    for (var i = 0; i < 80 && !soundStarted(); i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump();
    }
    expect(soundStarted(), isTrue);
    ElevatedButton choice() => t.widget<ElevatedButton>(
        find.byKey(const ValueKey('adventure-option-B')));
    expect(choice().onPressed, isNull);
    await t.runAsync(() => harness.completeSound('B'));
    await flushAdventure(t);
    expect(choice().onPressed, isNotNull);
    await press(t, find.byKey(const ValueKey('adventure-option-B')));
    expect(find.text('Answer saved!'), findsOneWidget);
    expect(p.adventureProgress('B').completed, 0);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await flushAdventure(t);
    p.dispose();
  });

  testWidgets(
      'production instruction playback stops when an enabled control is tapped',
      (t) async {
    final harness = QuizAudioHarness()..install();
    late AppProvider p;
    await t.runAsync(() async {
      p = AppProvider();
      await p.ready;
      await p.toggleSfx();
    });
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p,
        child: MaterialApp(
            home: LetterMasteryCheckScreen(letter: letterContent('B')))));

    Future<void> waitForAudio(String suffix) async {
      for (var i = 0;
          i < 100 && !harness.starts.any((s) => s.endsWith(suffix));
          i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await t.pump();
      }
      expect(harness.starts.any((s) => s.endsWith(suffix)), isTrue);
    }

    await waitForAudio('/quick_check/intro.mp3');
    final stopsBefore =
        harness.calls.where((c) => c.startsWith('stop:')).length;
    await press(t, find.byKey(const ValueKey('start-adventure')));
    await waitForAudio('/quick_check/match.mp3');
    expect(harness.calls.where((c) => c.startsWith('stop:')).length,
        greaterThan(stopsBefore));
    await press(t, find.byKey(const ValueKey('adventure-option-b')));
    await waitForAudio('/quick_check/saved.mp3');
    await press(t, find.text('Next Challenge'));
    await waitForAudio('/quick_check/sound.mp3');
    await press(t, find.byKey(const ValueKey('listen-lesson-sound-B')));
    await waitForAudio('/sounds/sound-b.mp3');
    ElevatedButton choice() => t.widget<ElevatedButton>(
        find.byKey(const ValueKey('adventure-option-B')));
    expect(choice().onPressed, isNull);
    await t.runAsync(() => harness.completeSound('B'));
    await flushAdventure(t);
    expect(choice().onPressed, isNotNull);
    expect(find.textContaining('recording did not finish'), findsNothing);
    expect(p.adventureProgress('B').completed, 0);
    expect(p.dailyActivity, isEmpty);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await flushAdventure(t);
    p.dispose();
  });
}
