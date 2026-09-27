import 'dart:io';
import 'package:kidsphonics/data/lesson_example_data.dart';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/data/phonics_activity_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/models/mastery_question.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';

String title(String s) => s[0].toUpperCase() + s.substring(1).toLowerCase();
void hasWordAudio(String word) {
  final path = PhonicsAudioService.assetForPhrase(title(word));
  expect(path, isNotNull, reason: word);
  expect(path, anyOf(contains('/word_'), contains('/game_words/')),
      reason: word);
  expect(File('assets/$path').existsSync(), isTrue, reason: path);
}

void main() {
  test('all lessons distinguish names, introductory sounds and word recordings',
      () {
    expect(allLetters.map((l) => l.letter).toSet(), hasLength(26));
    for (final l in allLetters) {
      expect(l.sound,
          isNot(matches(RegExp(r'\b(Buh|Cuh|Duh|Guh|Juh|Kuh|Puh|Tuh)\b'))));
      expect(l.soundAudioKey, isNull);
      expect(l.sound, contains(l.phonemeDisplay));
      final name = PhonicsAudioService.assetForPhrase(l.letterAudioKey)!;
      expect(name, endsWith('letter-${l.lowercase}.mp3'));
      expect(File('assets/$name').existsSync(), isTrue);
      hasWordAudio(l.word);
    }
    expect(letterContent('I').word, 'Pig');
    expect(letterContent('I').position, 'middle');
    expect(letterContent('X').word, 'Fox');
    expect(letterContent('Q').sound, contains('Qu'));
    expect(letterContent('C').sound, contains('can'));
    expect(letterContent('G').sound, contains('can'));
  });

  test('sound questions have word cues and no equivalent-sound distractors',
      () {
    for (final d in Difficulty.values) {
      for (final q in [
        ...soundRoundsForDifficulty(d),
        ...quizQuestionsForDifficulty(d)
      ]) {
        hasWordAudio(q.voiceHint);
        expect(q.voiceHint, q.word);
        expect(q.options.toSet(), hasLength(q.options.length));
        expect(q.options.where((o) => o == q.correctLetter), hasLength(1));
        expect(q.question, contains('Listen'));
        if (q.correctLetter == 'K') expect(q.options, isNot(contains('C')));
        if (q.correctLetter == 'J') expect(q.options, isNot(contains('G')));
        if (q.correctLetter == 'S') expect(q.options, isNot(contains('C')));
      }
    }
  });

  test('rhyme sets have one answer and new artwork/audio for every cue', () {
    // Explicit rime groups; spelling resemblance is not the test oracle.
    const groups = [
      {'CAT', 'BAT', 'HAT', 'MAT'},
      {'SUN', 'FUN', 'RUN'},
      {'BALL', 'TALL', 'WALL'},
      {'FISH', 'DISH', 'WISH'},
      {'NEST', 'BEST'},
      {'VAN', 'FAN'},
      {'KITE', 'NIGHT'},
      {'QUEEN', 'GREEN', 'SEEN'},
      {'WHALE', 'TAIL', 'SNAIL'},
      {'BEE', 'TREE'},
      {'MOON', 'SPOON', 'BALLOON'},
      {'PIG', 'BIG'},
      {'BUG', 'MUG'},
      {'FROG', 'LOG'},
      {'STAR', 'CAR'},
      {'CAKE', 'LAKE', 'SNAKE'},
      {'HOUSE', 'MOUSE'},
      {'FOX', 'BOX'},
    ];
    for (final d in Difficulty.values) {
      for (final q in rhymeRoundsForDifficulty(d)) {
        final group = groups.singleWhere((g) => g.contains(q.word));
        expect(
            q.options.where((o) => group.contains(o.word)).map((o) => o.word),
            [q.correctRhyme]);
        expect(
            q.options.map((o) => o.word).toSet(), hasLength(q.options.length));
        final cue =
            lessonExamples.singleWhere((e) => e.word.toUpperCase() == q.word);
        final asset = PhonicsAudioService.assetForPhrase(cue.wordAudioKey)!;
        expect(asset,
            anyOf(contains('/lesson_audio/words/'), contains('/game_words/')));
        expect(File('assets/$asset').existsSync(), isTrue);
        expect(cue.frames.every((frame) => File(frame).existsSync()), isTrue);
        expect(q.options.length, d.index + 3);
        expect(q.hint, isNot(contains('Both end in')));
      }
    }
  });

  test('word builders reconstruct the named audio clue exactly', () {
    for (final d in Difficulty.values) {
      for (final q in wordPuzzlesForDifficulty(d)) {
        var index = 0;
        final rebuilt =
            q.blanks.map((c) => c ?? q.correctLetters[index++]).join();
        expect(rebuilt, q.word);
        expect(index, q.correctLetters.length);
        expect(q.tiles.toSet(), hasLength(q.tiles.length));
        for (final answer in q.correctLetters) {
          expect(q.tiles, contains(answer));
        }
        hasWordAudio(q.word);
      }
      for (final q in vowelPuzzlesFor(d)) {
        expect(
            q.display.replaceAll(' ', '').replaceFirst('_', q.vowel), q.word);
        expect(vowelChoicesFor(d, q.vowel).where((v) => v == q.vowel),
            hasLength(1));
        expect({'BEE', 'APE', 'OAK'}, isNot(contains(q.word)));
        hasWordAudio(q.word);
      }
    }
  });

  test('sound positions use actual sounds, including sh as a unit', () {
    for (final d in Difficulty.values) {
      for (final q in positionRoundsFor(d)) {
        hasWordAudio(q.word);
        expect(q.options.where((o) => o == q.correctPos), hasLength(1));
        if (q.word == 'FISH' && q.correctPos == SoundPosition.end) {
          expect(q.targetLetter, 'SH');
          expect(q.soundDisplay, '/sh/');
        }
        if (q.targetLetter == 'I') expect(q.word, 'PIG');
        if (q.targetLetter == 'A' && q.correctPos == SoundPosition.middle) {
          expect(q.word, 'CAT');
        }
      }
    }
  });

  test('mastery keeps five questions while short vowels stay in scope', () {
    for (var seed = 0; seed < 100; seed++) {
      for (final letter in ['A', 'E', 'I', 'O', 'U', 'Q', 'X']) {
        final qs = buildMasteryQuestions(letter, random: Random(seed));
        expect(qs, hasLength(5));
        for (final q in qs.where((q) => q.requiresAudio)) {
          hasWordAudio(q.audioPhrase!);
          expect({'Ape', 'Oak', 'Ice Cream'}, isNot(contains(q.audioPhrase)));
          if (letter == 'I') {
            expect({'Pig', 'Fin', 'Lip'}, contains(q.audioPhrase));
          }
        }
        if (letter == 'Q') expect(qs.first.answer, 'Qu');
        if (letter == 'I') {
          final wordQuestion = qs[2];
          expect(
              wordQuestion.options.where((w) => w.toUpperCase().contains('I')),
              [wordQuestion.answer]);
        }
        if (letter == 'X') expect(qs.first.prompt, contains('/ks/ sounds'));
      }
    }
  });

  test('recognition words are unique and displayed whole, with local audio',
      () {
    final words = voiceWords.values.expand((list) => list).toList();
    expect(words.map((w) => w['word']).toSet(), hasLength(words.length));
    for (final word in words) {
      expect(word['hint'], word['word']);
      hasWordAudio(word['word']!);
    }
  });

  test('retired misleading recordings cannot resolve through phrase playback',
      () {
    for (final phrase in [
      'B says Buh! Like Banana!',
      'I says Ihh! Like Ice Cream!',
      'X says Ksss! Like X-Sign!',
      'X-Sign',
      'X-Sign! X-S-I-G-N',
      'Dog! Duh... Dog! The first sound is D!',
      'Dog! Duh... Dog!',
      'Cat... Bat! Both end in A-T!',
    ]) {
      expect(PhonicsAudioService.assetForPhrase(phrase), isNull);
    }
  });
}
