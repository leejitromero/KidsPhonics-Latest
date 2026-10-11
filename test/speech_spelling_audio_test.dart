import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/voice_recognition_screen.dart';
import 'package:kidsphonics/widgets/game_design.dart';
import 'package:kidsphonics/widgets/speech_practice_design.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'quiz_audio_harness.dart';
import 'speech_practice_test.dart' show FakeSpeech;

Future<void> flushAudio(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await t.pump();
  }
}

Future<void> waitForStart(
    WidgetTester t, QuizAudioHarness audio, int count) async {
  for (var i = 0; i < 80 && audio.starts.length < count; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await t.pump();
  }
  expect(audio.starts.length, count);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'Hear Word enlarges N E T with letter names, then reads Net; interruptions stop spelling',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    final original = voiceWords[Difficulty.easy]!;
    voiceWords[Difficulty.easy] = [
      {'word': 'Net', 'hint': 'Net', 'emoji': ''}
    ];
    addTearDown(() => voiceWords[Difficulty.easy] = original);
    final audio = QuizAudioHarness()..install();
    final speech = FakeSpeech();
    final p = await mount(t, VoiceRecognitionScreen(speech: speech));
    await t.runAsync(() => p.toggleSfx());
    await t.pump();
    final hear = find.byKey(const ValueKey('speech-hear-word'));
    final mic = find.byKey(const ValueKey('speech-microphone'));
    t.widget<ForestAudioButton>(hear).onPressed!();
    await t.pump();
    for (var index = 0; index < 3; index++) {
      await waitForStart(t, audio, index + 1);
      final letter = 'NET'[index].toLowerCase();
      expect(audio.starts.last, endsWith('/letters/letter-$letter.mp3'));
      expect(
          t
              .widget<SpeechPictureCard>(find.byType(SpeechPictureCard))
              .activeLetter,
          index);
      for (var slot = 0; slot < 3; slot++) {
        expect(
            t
                .widget<AnimatedScale>(
                    find.byKey(ValueKey('speech-letter-$slot')))
                .scale,
            slot == index ? 1.23 : 1);
      }
      expect(t.widget<ElevatedButton>(mic).onPressed, isNull);
      expect(t.widget<ForestAudioButton>(hear).onPressed, isNull);
      await t.pump(const Duration(seconds: 2));
      expect(audio.starts.length, index + 1,
          reason: 'Wait for the real letter playback-complete event');
      await t
          .runAsync(() => audio.completeSource('/letters/letter-$letter.mp3'));
    }
    await waitForStart(t, audio, 4);
    expect(audio.starts.last, endsWith('/audio/game_words/net.mp3'));
    expect(audio.starts.any((s) => s.contains('/sounds/sound-')), isFalse);
    expect(
        t.widget<SpeechPictureCard>(find.byType(SpeechPictureCard)).readingWord,
        isTrue);
    await t.pump(const Duration(seconds: 2));
    expect(t.widget<ElevatedButton>(mic).onPressed, isNull);
    await t.runAsync(() => audio.completeSource('/audio/game_words/net.mp3'));
    await flushAudio(t);
    expect(t.widget<ElevatedButton>(mic).onPressed, isNotNull);
    expect(speech.starts, 0);
    expect(p.stars, 0,
        reason: 'Listening to spelling does not award an answer');

    // Backgrounding cancels all remaining letters; resuming stays silent.
    t.widget<ForestAudioButton>(hear).onPressed!();
    await t.pump();
    await waitForStart(t, audio, 5);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    await flushAudio(t);
    await t.pump(const Duration(seconds: 3));
    expect(audio.starts.length, 5);
    expect(t.widget<SpeechPictureCard>(find.byType(SpeechPictureCard)).spelling,
        isFalse);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    expect(audio.starts.length, 5);

    // Voice mute stops the sequence and leaves the microphone usable.
    t.widget<ForestAudioButton>(hear).onPressed!();
    await t.pump();
    await waitForStart(t, audio, 6);
    await t.runAsync(() => p.toggleVoice());
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    expect(audio.starts.length, 6);
    expect(find.text('Audio is turned off.'), findsOneWidget);
    expect(t.widget<ForestAudioButton>(hear).onPressed, isNull);
    expect(t.widget<ElevatedButton>(mic).onPressed, isNotNull);
    await t.runAsync(() => p.toggleVoice());
    await t.pump();
    t.widget<ForestAudioButton>(hear).onPressed!();
    await t.pump();
    await waitForStart(t, audio, 7);
    final gameContext = t.element(find.byType(VoiceRecognitionScreen));
    showDialog<void>(
        context: gameContext,
        builder: (_) => const AlertDialog(title: Text('Help')));
    await t.pump();
    await flushAudio(t);
    await t.pump(const Duration(seconds: 2));
    expect(audio.starts.length, 7);
    expect(t.widget<SpeechPictureCard>(find.byType(SpeechPictureCard)).spelling,
        isFalse);
    Navigator.of(gameContext).pop();
    await t.pump(const Duration(milliseconds: 400));
    expect(audio.starts.length, 7);
    t.widget<ForestAudioButton>(hear).onPressed!();
    await t.pump();
    await waitForStart(t, audio, 8);
    await t.runAsync(() async {
      await p.parentAuth.setup('2580', '2580');
      await p.toggleGameAccess();
    });
    await t.pump();
    await flushAudio(t);
    await t.pump(const Duration(seconds: 2));
    expect(audio.starts.length, 8);
    expect(t.widget<SpeechPictureCard>(find.byType(SpeechPictureCard)).spelling,
        isFalse);
    await close(t, p);
    await t.pump(const Duration(seconds: 1));
    expect(t.takeException(), isNull);
  });
}
