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
    (const Size(768, 1024), 1.0),
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
      ];
      final guide = find.byKey(const ValueKey('game-instruction-guide'));
      final scroll = find.byKey(const ValueKey('speech-content-scroll'));
      final guideRect = t.getRect(guide);
      final viewport = t.getRect(scroll);
      expect(find.byKey(const ValueKey('speech-tip-card')), findsNothing);
      expect(guideRect.top, greaterThanOrEqualTo(0));
      expect(guideRect.bottom, lessThanOrEqualTo(viewport.top));
      expect(t.getRect(parts.first).top, greaterThanOrEqualTo(viewport.top));
      // Content must stop painting at the viewport when it scrolls beneath
      // the fixed instruction bubble (the original overlap regression).
      expect(t.widget<SingleChildScrollView>(scroll).clipBehavior,
          isNot(Clip.none));
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
      expect(t.getRect(guide), guideRect);
      expect(t.takeException(), isNull);

      final word =
          t.widget<SpeechPictureCard>(find.byType(SpeechPictureCard)).word;
      speech.result!(word, true);
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump();
      expect(find.text('Recognized'), findsOneWidget);
      final next = find.byKey(const ValueKey('speech-next-word'));
      await t.ensureVisible(next);
      await t.pump();
      expect(t.getRect(guide), guideRect);
      expect(t.getRect(next).top, greaterThanOrEqualTo(viewport.top));
      expect(t.getRect(next).bottom, lessThanOrEqualTo(viewport.bottom));
      expect(find.text('Next Word').hitTestable(), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }
}
