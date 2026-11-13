import 'dart:math';
import '../models/smart_review.dart';
import '../models/difficulty.dart';
import '../services/phonics_audio_service.dart';
import 'blending_lesson_data.dart';
import 'cvc_lesson_data.dart';
import 'game_word_data.dart';
import 'letter_data.dart';
import 'phonics_activity_data.dart';
import 'rhyming_jar_data.dart';

class ReviewQuestion {
  const ReviewQuestion(
      {required this.target,
      required this.prompt,
      required this.display,
      required this.expected,
      required this.options,
      required this.phrases,
      required this.explanation});
  final ReviewTarget target;
  final String prompt, display, expected, explanation;
  final List<String> options, phrases;
  String get heading => switch (target.skill) {
        ReviewSkill.recognition => 'Letter Pairs',
        ReviewSkill.sound => 'Letter Sounds',
        ReviewSkill.vowel => 'Short Vowels',
        ReviewSkill.word => 'Word Reading',
        ReviewSkill.rhyme => 'Rhyming Words',
        ReviewSkill.position => 'Sound Positions',
      };
}

/// Reuses the approved word lists and recordings; never infers new phonemes.
class SmartReviewCatalog {
  static final _wordAudio = <String, String>{
    for (final item in allLetters)
      if (PhonicsAudioService.assetForPhrase(item.word) != null)
        item.word.toUpperCase(): item.word,
    for (final word in gameWords) word.word.toUpperCase(): word.audioKey,
    for (final word in blendingLessonWords) word.word: word.wordAudio,
    for (final word in cvcLessonWords) word.word: word.wordAudio,
  };
  static final _positions = [
    for (final difficulty in Difficulty.values) ...positionRoundsFor(difficulty)
  ];
  static bool supported(ReviewTarget target) => switch (target.skill) {
        ReviewSkill.recognition ||
        ReviewSkill.sound =>
          target.focus.isEmpty && RegExp(r'^[A-Z]$').hasMatch(target.value),
        ReviewSkill.vowel =>
          target.focus.isEmpty && RegExp(r'^[AEIOU]$').hasMatch(target.value),
        ReviewSkill.word =>
          target.focus.isEmpty && _wordAudio.containsKey(target.value),
        ReviewSkill.rhyme => target.focus.isEmpty &&
            rhymingFamilies.any((f) => f.target == target.value),
        ReviewSkill.position => _positions.any((p) =>
            p.word.toUpperCase() == target.value &&
            p.targetLetter == target.focus),
      };

  static List<ReviewQuestion> plan(Iterable<ReviewEvidence> evidence,
      {Random? random}) {
    final rng = random ?? Random();
    final targets = evidence
        .where((e) => e.needsReview && supported(e.target))
        .take(5)
        .map((e) => e.target)
        .toList();
    if (targets.isEmpty) return const [];
    // Two opportunities per focus when the backlog is small, up to five items.
    final selected = [...targets, ...targets].take(5).toList();
    final variants = <String, int>{};
    return List.unmodifiable([
      for (final target in selected)
        question(target, rng,
            variant: variants.update(target.key, (value) => value + 1,
                ifAbsent: () => rng.nextInt(100000)))
    ]);
  }

  static ReviewQuestion question(ReviewTarget target, Random rng,
      {int variant = 0}) {
    if (!supported(target)) throw ArgumentError.value(target.key, 'target');
    List<String> choices(String answer, Iterable<String> pool) {
      final others = pool.toSet().where((o) => o != answer).toList()
        ..shuffle(rng);
      return List.unmodifiable([answer, ...others.take(2)]..shuffle(rng));
    }

    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    switch (target.skill) {
      case ReviewSkill.recognition:
        final answer = target.value.toLowerCase();
        return ReviewQuestion(
            target: target,
            prompt: 'Choose the matching little letter.',
            display: target.value,
            expected: answer,
            options: choices(answer, letters.toLowerCase().split('')),
            phrases: [target.value],
            explanation: '${target.value} and $answer are the same letter.');
      case ReviewSkill.sound:
        return ReviewQuestion(
            target: target,
            prompt: 'Listen. Which letter makes this sound?',
            display: '',
            expected: target.value,
            options: choices(
                target.value,
                letters.split('').where((letter) =>
                    !({'C', 'K'}.contains(target.value) &&
                        {'C', 'K'}.contains(letter) &&
                        letter != target.value))),
            phrases: ['lesson-sound-${target.value}'],
            explanation: '${target.value} makes the sound you heard.');
      case ReviewSkill.vowel:
        final words =
            cvcLessonWords.where((w) => w.vowel == target.value).toList();
        final word = words[variant % words.length];
        return ReviewQuestion(
            target: target,
            prompt: 'Listen. Choose the missing vowel.',
            display: '${word.word[0]}_${word.word[2]}',
            expected: target.value,
            options: choices(target.value, 'AEIOU'.split('')),
            phrases: [word.wordAudio],
            explanation:
                '${word.word} has the short ${target.value} sound in the middle.');
      case ReviewSkill.word:
        final length = target.value.length;
        return ReviewQuestion(
            target: target,
            prompt: 'Listen. Choose the word you hear.',
            display: '',
            expected: target.value,
            options: choices(target.value,
                _wordAudio.keys.where((w) => (w.length - length).abs() <= 1)),
            phrases: [_wordAudio[target.value]!],
            explanation: 'The word is ${target.value}.');
      case ReviewSkill.rhyme:
        final family =
            rhymingFamilies.firstWhere((f) => f.target == target.value);
        final answer = family.rhymes[variant % family.rhymes.length];
        final others = rhymingFamilies
            .where((f) => f.target != family.target)
            .map((f) => f.target);
        return ReviewQuestion(
            target: target,
            prompt: 'Which word rhymes with ${target.value}?',
            display: target.value,
            expected: answer,
            options: choices(answer, others),
            phrases: [rhymeWordKey(target.value)],
            explanation:
                '${target.value} and $answer have the same ending sound.');
      case ReviewSkill.position:
        final item = _positions.firstWhere((p) =>
            p.word.toUpperCase() == target.value &&
            p.targetLetter == target.focus);
        final phrase =
            target.focus == 'SH' ? 'SH' : 'lesson-sound-${target.focus}';
        final wordPhrase = _wordAudio[target.value] ??
            '${item.word[0]}${item.word.substring(1).toLowerCase()}';
        return ReviewQuestion(
            target: target,
            prompt: 'Where is the ${target.focus} sound in ${target.value}?',
            display: target.value,
            expected: item.correctPos.label,
            options: choices(item.correctPos.label,
                SoundPosition.values.map((p) => p.label)),
            phrases: [
              wordPhrase,
              if (PhonicsAudioService.assetForPhrase(phrase) != null) phrase
            ],
            explanation:
                'The ${target.focus} sound is at the ${item.correctPos.label.toLowerCase()} of ${target.value}.');
    }
  }
}
