import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/data/lesson_example_data.dart';
import 'package:kidsphonics/data/game_word_data.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';

void main() {
  test('every lesson has real PNG/WebP frames and distinct local audio tracks',
      () {
    expect(lessonExamples.map((e) => e.letter).join(),
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    for (final example in lessonExamples) {
      expect(example.frames.length, inInclusiveRange(2, 3));
      for (final frame in example.frames) {
        final bytes = File(frame).readAsBytesSync();
        if (frame.endsWith('.png')) {
          expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
        } else {
          expect(frame.endsWith('.webp'), isTrue);
          expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
          expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WEBP');
        }
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

  test(
      '19 PNG fallbacks preserve all 57 original canvases, alpha and order; seven overrides remain intact',
      () {
    final imported = jsonDecode(
        File('tools/alphabet_picture_import.json').readAsStringSync()) as Map;
    final originals = {
      for (final frame in imported['files'] as List)
        frame['path'] as String: frame
    };
    final fallbackLetters = <String>[];
    final overrideLetters = <String>[];
    var fallbackCount = 0;
    for (final example in lessonExamples) {
      final override = gameWordFor(example.word);
      if (override != null) {
        overrideLetters.add(example.letter);
        expect(example.frames, orderedEquals(override.frames));
        continue;
      }
      fallbackLetters.add(example.letter);
      expect(example.frames, [
        for (final suffix in ['', '1', '2'])
          'assets/images/lesson_frames/${example.slug}_${example.letter}$suffix.png'
      ]);
      final canvases = <String>{};
      for (final path in example.frames) {
        fallbackCount++;
        final reference = originals[path];
        expect(reference, isNotNull, reason: path);
        final bytes = File(path).readAsBytesSync();
        expect(
            sha256.convert(bytes).toString().toUpperCase(), reference['sha256'],
            reason:
                'Original pixels, padding, metadata and color information must remain unchanged: $path');
        final header = ByteData.sublistView(bytes);
        expect(header.getUint32(16), reference['width']);
        expect(header.getUint32(20), reference['height']);
        expect(bytes[25], 6,
            reason: 'Preserve the original RGBA PNG color type');
        canvases.add('${header.getUint32(16)}x${header.getUint32(20)}');
      }
      expect(canvases, hasLength(1), reason: 'Animation canvases must align');
    }
    expect(fallbackCount, 57);
    expect(fallbackLetters.join(), 'ABCDEFGHIJKLPSTVXYZ');
    expect(overrideLetters.join(), 'MNOQRUW');
  });

  test('exceptional picture words explain the sound difference', () {
    for (final letter in ['G', 'O', 'X']) {
      expect(lessonExamples.firstWhere((e) => e.letter == letter).soundNote,
          isNotNull);
    }
  });
}
