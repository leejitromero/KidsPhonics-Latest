import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/models/mastery_question.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';

void main() {
  test('A practice varies examples without ambiguous starting-letter choices',
      () {
    for (var seed = 0; seed < 20; seed++) {
      final questions = buildLessonPracticeQuestions('A', random: Random(seed));
      final words = {
        questions[0].audioPhrase == 'lesson-word-A'
            ? 'Ant'
            : questions[0].audioPhrase,
        questions[1].picture,
        questions[2].answer,
        questions[3].answer,
      };
      expect(words, {'Ant', 'Axe', 'Apple', 'Airplane'});
      expect(questions[2].options.where((word) => word.startsWith('A')),
          [questions[2].answer]);
    }
  });
  test('lesson practice uses only new recordings and supplied picture words',
      () {
    for (final letter in allLetters) {
      final questions =
          buildLessonPracticeQuestions(letter.letter, random: Random(4));
      expect(questions, hasLength(5));
      expect(questions.where((q) => q.requiresAudio), hasLength(3));
      for (final question in questions) {
        expect(
            question.options.where((o) => o == question.answer), hasLength(1));
        expect(question.options.toSet().length, question.options.length);
        if (question.requiresAudio) {
          final path =
              PhonicsAudioService.assetForPhrase(question.audioPhrase!)!;
          expect(
              path,
              anyOf(
                  contains('/lesson_audio/words/'), contains('/game_words/')));
          expect(File('assets/$path').existsSync(), isTrue);
        }
      }
      expect(questions[1].picture, isNotNull);
      expect(questions[4].answer, letter.letter);
    }
  });
  test(
      'every letter has five varied questions, unique choices and local word audio',
      () {
    for (final letter in allLetters) {
      for (var seed = 0; seed < 30; seed++) {
        final questions =
            buildMasteryQuestions(letter.letter, random: Random(seed));
        expect(questions, hasLength(5));
        expect(questions.map((q) => q.type).toSet(), hasLength(5));
        expect(questions.where((q) => q.requiresAudio), hasLength(3));
        expect(questions.map((q) => q.prompt).toSet(), hasLength(5));
        for (final q in questions) {
          expect(q.options.toSet().length, q.options.length);
          expect(q.options.where((option) => option == q.answer), hasLength(1));
          if (q.requiresAudio) {
            if (q.type == MasteryQuestionType.soundPicture) {
              expect(q.answer, isNot(endsWith(q.audioPhrase!)));
              expect(q.options.any((o) => o.endsWith(q.audioPhrase!)), isFalse);
              expect(q.prompt, contains('same sound'));
              if (letter.letter == 'C') {
                expect(q.options.any((o) => o.endsWith('Kite')), isFalse);
              }
            }
            if (q.type == MasteryQuestionType.soundPosition) {
              expect(q.audioPhrase, isNot('Cake'));
            }
            final asset = PhonicsAudioService.assetForPhrase(q.audioPhrase!);
            expect(asset, isNotNull, reason: q.audioPhrase);
            expect(File('assets/$asset').existsSync(), isTrue, reason: asset);
            expect(asset, anyOf(contains('/word_'), contains('/game_words/')));
            expect(q.audioPhrase, isNot(contains('says')));
            expect(q.prompt, isNot(contains(q.audioPhrase!)));
          }
        }
        expect(questions.first.prompt, isNot(contains(' ${letter.letter} ')));
      }
    }
  });

  test('X uses existing final-sound Fox content, never misleading X assets',
      () {
    final questions = buildMasteryQuestions('X', random: Random(1));
    expect(questions.first.prompt, contains('ending /ks/ sounds'));
    for (final q in questions.where((q) => q.requiresAudio)) {
      expect(q.audioPhrase, 'Fox');
      expect(PhonicsAudioService.assetForPhrase(q.audioPhrase!),
          endsWith('word_fox.mp3'));
    }
  });

  test('B examples vary across the existing vocabulary', () {
    final questions = buildMasteryQuestions('B', random: Random(3));
    expect(
        questions
            .where((q) => q.requiresAudio)
            .map((q) => q.audioPhrase)
            .toSet()
            .length,
        greaterThan(1));
  });

  test('limited vocabulary and vowels use sound position, not word recognition',
      () {
    for (final letter in ['A', 'E', 'I', 'O', 'U', 'D', 'X']) {
      final questions = buildMasteryQuestions(letter, random: Random(7));
      expect(questions[3].type, MasteryQuestionType.soundPosition);
      expect(questions[4].type, MasteryQuestionType.missingLetter);
    }
  });
}
