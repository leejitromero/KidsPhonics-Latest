import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/controllers/cvc_lesson_controller.dart';
import 'package:kidsphonics/data/cvc_lesson_data.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/models/letter_adventure.dart';
import 'package:kidsphonics/models/word_lesson_progress.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';

void main() {
  const original = [
    'CAT',
    'BAT',
    'HAT',
    'MAP',
    'FAN',
    'BAG',
    'BED',
    'HEN',
    'PEN',
    'NET',
    'RED',
    'PIG',
    'PIN',
    'DOG',
    'POT',
    'RUG',
    'RUN',
  ];
  final added = ('MAT RAT CAN JAM PET WET GET LET SET BIN TIN FIN WIN BIG HIT '
          'FIT KID HOT DOT HOP POP NOD GOT NOT LOT BUN TUB JUG GUM PUP CUB MUD FUN')
      .split(' ');

  test(
      'exact approved expansion preserves the original word order and progress',
      () {
    expect(cvcIllustratedWords.map((w) => w.word), original);
    expect(cvcLessonWords.take(50).map((w) => w.word), [...original, ...added]);
    final restored = WordLessonProgress.fromJson(
        {'started': true, 'completed': original}, WordLesson.cvc);
    expect(restored.started, isTrue);
    expect(restored.completed, original.toSet());
    expect(restored.completed.intersection(added.toSet()), isEmpty);
    expect(WordLesson.cvc.words, hasLength(70));
    expect(cvcLessonWords[17].praise, 'Nice work! M-A-T makes mat!');
    expect(cvcLessonWords[49].praise, 'Super work! F-U-N makes fun!');
    expect(cvcLessonWords.skip(17).map((w) => w.encouragement).toSet().length,
        greaterThan(5));
  });

  test('all imported recordings match source hashes and keep old recordings',
      () {
    final report = jsonDecode(
            File('tools/cvc_expansion_audio_import.json').readAsStringSync())
        as Map;
    expect(report['imported'], isTrue);
    expect(report['validatedCount'], 66);
    final rows = report['recordings'] as List;
    expect(rows, hasLength(66));
    final targets = <String>{};
    for (final row in rows) {
      final word = row['word'] as String;
      final kind = row['kind'] as String;
      expect(added, contains(word.toUpperCase()));
      final asset = PhonicsAudioService.assetForPhrase('cvc-$kind-$word');
      expect('assets/$asset', row['target']);
      expect(targets.add(row['target']), isTrue);
      expect(sha256.convert(File(row['target']).readAsBytesSync()).toString(),
          row['sha256']);
      expect(row['durationSeconds'], inExclusiveRange(.2, 20));
      expect(row['nearFullScalePercent'], 0);
    }
    final originals = report['originalHashes'] as Map;
    expect(originals, hasLength(34));
    for (final entry in originals.entries) {
      expect(
          sha256
              .convert(File('assets/audio/cvc_lesson/${entry.key}')
                  .readAsBytesSync())
              .toString(),
          entry.value);
    }
    for (final word in added) {
      for (final kind in ['word', 'praise']) {
        expect(
            targets,
            contains(
                'assets/audio/cvc_lesson/$kind-${word.toLowerCase()}.mp3'));
      }
    }
  });

  test('picture-based quiz and adventure retain their existing content', () {
    final illustrated = original.where((w) => w != 'RED' && w != 'RUN').toSet();
    for (final difficulty in Difficulty.values) {
      final questions = quizQuestionsForDifficulty(difficulty);
      expect(questions.map((q) => q.word).toSet(), illustrated);
      expect(questions.length, 15 * quizPositionsFor(difficulty).length);
      for (final question in questions) {
        expect(question.pictureAsset, isNotNull);
        expect(File(question.pictureAsset!).existsSync(), isTrue);
      }
    }
    // This game previously used its own Tub recording; CVC must not shadow it.
    expect(adventureWordKey('Tub'), 'Tub');
  });

  testWidgets('every new word completes its own phonemes, word and praise cues',
      (tester) async {
    for (var index = 17; index < cvcLessonWords.length; index++) {
      final word = cvcLessonWords[index];
      final heard = <String>[];
      final lesson = CvcLessonController(
          play: (phrase) async {
            heard.add(phrase);
            return true;
          },
          stop: () async {});
      final completed = lesson.select(index);
      for (var step = 0; step < 60; step++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await completed;
      expect(
          heard,
          [
            word.wordAudio,
            for (var repeat = 0; repeat < 3; repeat++)
              for (var letter = 0; letter < 3; letter++)
                word.soundAudio(letter),
            word.wordAudio,
            word.praiseAudio,
          ],
          reason: word.word);
      expect(lesson.phase, CvcPhase.complete);
      expect(lesson.running, isFalse);
      lesson.dispose();
    }
  });
}
