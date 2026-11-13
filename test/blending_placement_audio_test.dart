import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/controllers/blending_lesson_controller.dart';
import 'package:kidsphonics/data/blending_lesson_data.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';

import 'learning_progress_test.dart' show mockProgressAudio;
import 'quiz_audio_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(mockProgressAudio);

  for (final name in ['SKUNK', 'HELMET', 'BLANKET']) {
    testWidgets('$name placements play sound files before word and praise',
        (tester) async {
      final audio = QuizAudioHarness()..install();
      late PhonicsAudioService speech;
      await tester.runAsync(() async => speech = PhonicsAudioService());
      final word = blendingLessonWords.singleWhere((w) => w.word == name);
      expect(word.wholeWordOnly, isTrue);
      final lesson = BlendingLessonController(
          words: [word], play: speech.playInstruction, stop: speech.stop);
      final slots = List.generate(name.length, (i) => name.length - 1 - i);
      for (final slot in slots) {
        expect(lesson.place(slot, slot), isTrue);
      }
      final expected = [
        for (final slot in slots)
          '/audio/phonics/lesson_audio/sounds/sound-${name[slot].toLowerCase()}.mp3',
        '/audio/blending_lesson/word-${name.toLowerCase()}.mp3',
        '/audio/blending_lesson/praise-${name.toLowerCase()}.mp3',
      ];
      for (var i = 0; i < expected.length; i++) {
        for (var tick = 0; tick < 150 && audio.starts.length <= i; tick++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 5)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(audio.starts, hasLength(i + 1));
        expect(audio.starts.last, endsWith(expected[i]));
        expect(audio.starts.any((source) => source.contains('/letters/')),
            isFalse);
        if (i < slots.length) {
          expect(lesson.highlightedLetters, {slots[i]});
        }
        // An unfinished clip holds the queue, even after several seconds.
        await tester.pump(const Duration(seconds: 3));
        expect(audio.starts, hasLength(i + 1));
        await tester.runAsync(() => audio.completeSource(expected[i]));
        await tester.pump();
      }
      for (var i = 0; i < 10 && lesson.running; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)));
        await tester.pump();
      }
      expect(lesson.phase, BlendingPhase.complete);
      expect(lesson.running, isFalse);
      expect(lesson.highlightedLetters, isEmpty);
      expect(lesson.audioUnavailable, isFalse);
      lesson.dispose();
      await tester.runAsync(() async {
        speech.dispose();
        await Future<void>.delayed(Duration.zero);
      });
      expect(tester.takeException(), isNull);
    });
  }
}
