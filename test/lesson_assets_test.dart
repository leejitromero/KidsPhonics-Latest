import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/data/lesson_example_data.dart';
import 'package:kidsphonics/data/game_word_data.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';

void main() {
  test('every lesson has supplied PNG frames and distinct local audio tracks',
      () {
    expect(lessonExamples.map((e) => e.letter).join(),
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    for (final example in lessonExamples) {
      expect(example.frames.length, inInclusiveRange(2, 3));
      for (final frame in example.frames) {
        final bytes = File(frame).readAsBytesSync();
        expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      }
      final paths = [
        example.letterAudioKey,
        example.soundAudioKey,
        example.wordAudioKey
      ].map(PhonicsAudioService.assetForPhrase).toList();
      expect(paths.toSet(), hasLength(3));
      for (final path in paths) {
        expect(path, isNotNull);
        expect(File('assets/$path').lengthSync(), greaterThan(1000));
      }
      expect(paths, [
        'audio/phonics/lesson_audio/letters/letter-${example.letter.toLowerCase()}.mp3',
        'audio/phonics/lesson_audio/sounds/sound-${example.letter.toLowerCase()}.mp3',
        gameWordFor(example.word)?.audioAsset ??
            'audio/phonics/lesson_audio/words/word-${example.slug}.mp3',
      ]);
    }
  });

  test('exceptional picture words explain the sound difference', () {
    for (final letter in ['G', 'O', 'X']) {
      expect(lessonExamples.firstWhere((e) => e.letter == letter).soundNote,
          isNotNull);
    }
  });
}
