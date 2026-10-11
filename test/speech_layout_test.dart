import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/voice_recognition_screen.dart';
import 'package:kidsphonics/widgets/speech_practice_design.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'speech_practice_test.dart' show FakeSpeech;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(390, 844), 1.8),
  ]) {
    testWidgets(
        'speech reference ordering and readable controls at $size x$scale',
        (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      mockProgressAudio();
      final speech = FakeSpeech();
      final p = await mount(
          t,
          MediaQuery(
              data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true),
              child: VoiceRecognitionScreen(
                  difficulty: Difficulty.hard, speech: speech)));
      final parts = [
        find.byKey(const ValueKey('speech-picture-card')),
        find.byKey(const ValueKey('speech-hear-word')),
        find.byKey(const ValueKey('speech-microphone')),
        find.byKey(const ValueKey('speech-heard-card')),
        find.byKey(const ValueKey('speech-tip-card')),
      ];
      for (var i = 1; i < parts.length; i++) {
        expect(t.getRect(parts[i]).top,
            greaterThanOrEqualTo(t.getRect(parts[i - 1]).bottom));
      }
      expect(t.getSize(parts[2]).height, greaterThanOrEqualTo(48));
      expect(t.takeException(), isNull);
      final mic = t.widget<ElevatedButton>(parts[2]);
      mic.onPressed!();
      for (var i = 0; i < 8; i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await t.pump();
      }
      expect(speech.starts, 1);
      speech.result!(
          'a very long recognized phrase that needs to fit inside the pink feedback card',
          false);
      await t.pump();
      expect(find.text('Listening...'), findsOneWidget);
      expect(t.widget<SpeechHeardCard>(find.byType(SpeechHeardCard)).heard,
          startsWith('a very long recognized phrase'));
      await t.ensureVisible(parts.last);
      await t.pump();
      expect(t.getRect(parts.last).bottom, lessThanOrEqualTo(size.height));
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }
}
