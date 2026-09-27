import 'dart:math';
import '../data/letter_data.dart';
import '../data/lesson_example_data.dart';

enum MasteryQuestionType {
  soundLetter,
  pictureLetter,
  letterWord,
  soundPicture,
  missingLetter,
  soundPosition
}

class MasteryQuestion {
  final MasteryQuestionType type;
  final String prompt, answer;
  final List<String> options;
  final String? audioPhrase, picture;
  const MasteryQuestion(
      {required this.type,
      required this.prompt,
      required this.answer,
      required this.options,
      this.audioPhrase,
      this.picture});
  bool get requiresAudio => audioPhrase != null;
}

/// Lesson practice uses only the supplied picture vocabulary and new voice.
/// Spelling prompts also work for Giraffe and Xylophone without presenting
/// their initial sounds as hard G or /ks/.
List<MasteryQuestion> buildLessonPracticeQuestions(String letter,
    {Random? random}) {
  final rng = random ?? Random();
  final example =
      lessonExamples.firstWhere((e) => e.letter == letter.toUpperCase());
  final target = example.letter;
  List<String> choices(String answer, Iterable<String> pool) {
    final others = pool.where((value) => value != answer).toSet().toList()
      ..shuffle(rng);
    return [answer, ...others.take(3)]..shuffle(rng);
  }

  final letters = lessonExamples.map((e) => e.letter);
  final words = lessonExamples.map((e) => e.word);
  return [
    MasteryQuestion(
        type: MasteryQuestionType.soundLetter,
        prompt: 'Listen. Which letter comes first when you write the word?',
        audioPhrase: example.wordAudioKey,
        answer: target,
        options: choices(target, letters)),
    MasteryQuestion(
        type: MasteryQuestionType.pictureLetter,
        prompt: 'Which letter does ${example.word} start with?',
        picture: example.word,
        answer: target,
        options: choices(target, letters)),
    MasteryQuestion(
        type: MasteryQuestionType.letterWord,
        prompt: 'Which word starts with $target?',
        answer: example.word,
        options: choices(example.word, words)),
    MasteryQuestion(
        type: MasteryQuestionType.soundPicture,
        prompt: 'Listen. Which word do you hear?',
        audioPhrase: example.wordAudioKey,
        answer: example.word,
        options: choices(example.word, words)),
    MasteryQuestion(
        type: MasteryQuestionType.missingLetter,
        prompt:
            'Listen. Which letter is missing?\n_${example.word.substring(1)}',
        audioPhrase: example.wordAudioKey,
        answer: target,
        options: choices(target, letters)),
  ];
}

/// Uses existing project words, never lesson/quiz recordings that name the answer.
/// Introductory sounds come from the shared lesson scope. I uses medial short I;
/// X and Qu represent two sounds, never an isolated final/initial phoneme.
List<MasteryQuestion> buildMasteryQuestions(String letter, {Random? random}) {
  final rng = random ?? Random();
  final target = letter.toUpperCase();
  final content = letterContent(target);
  final words = <String>{
    ...allLetters.where((l) => l.letter != 'X').map((l) => l.word),
    'Ball',
    'Bat',
    'Bug',
    'Cake',
    'Cub',
    'Fin',
    'Fox',
    'Frog',
    'Hat',
    'Hog',
    'Lip',
    'Mop',
    'Rain',
    'Rat',
    'Snake',
    'Star',
    'Tree',
  }.toList();
  bool matches(String word) => target == 'I'
      ? {'Pig', 'Fin', 'Lip'}.contains(word)
      : target == 'X'
          ? word == 'Fox'
          : word.toUpperCase().startsWith(target);
  final examples = words.where(matches).toList()..shuffle(rng);
  if (examples.isEmpty) throw ArgumentError.value(letter, 'letter');
  String example(int index) => examples[index % examples.length];
  final position = content.position;
  final verb = target == 'X' ? 'ends' : 'starts';
  List<String> choices(String answer, Iterable<String> pool) {
    final distractors = pool.where((s) => s != answer).toSet().toList()
      ..shuffle(rng);
    return [answer, ...distractors.take(3)]..shuffle(rng);
  }

  final letters = allLetters.map((l) => l.letter);
  // C/K/Q and similar consonants can represent overlapping sounds. Keep those
  // out of one another's auditory distractors; spelling questions remain exact.
  final soundLetters = soundChoices(target, letters.toList());
  String picture(String word) {
    final matches = allLetters.where((l) => l.word == word);
    return matches.isEmpty ? word : '${matches.first.emoji} $word';
  }

  final soundWord = example(0);
  final visualWord = example(1);
  final matchingWord = example(2);
  // Transfer the heard beginning sound to a DIFFERENT word. Vowel spellings
  // alone do not establish matching sounds (Apple/Ape, Octopus/Oak).
  final canMatchSound =
      examples.length > 1 && !{'A', 'E', 'I', 'O', 'U', 'X'}.contains(target);
  final soundMatchCue = example(3);
  final soundMatchAnswer = example(4);
  final soundDistractors = words.where(
      (word) => !matches(word) && !(target == 'C' && word.startsWith('K')));
  final finalWord = example(rng.nextInt(examples.length));
  final masked =
      finalWord.replaceFirst(RegExp(target, caseSensitive: false), '_');
  // Cake has /k/ both initially (C) and later (K), so its sound position is
  // ambiguous even though the written C occurs only once.
  final canAskPosition = finalWord != 'Cake' &&
      target.allMatches(finalWord.toUpperCase()).length == 1;
  final usePosition = canMatchSound && canAskPosition && rng.nextBool();
  return [
    MasteryQuestion(
        type: MasteryQuestionType.soundLetter,
        prompt: target == 'Q'
            ? 'Listen. Which letters match the beginning sounds in the word?'
            : target == 'X'
                ? 'Listen. Which letter matches the ending /ks/ sounds?'
                : 'Listen. Which letter matches the $position sound in the word?',
        audioPhrase: soundWord,
        answer: letterChoiceLabel(target),
        options: choices(
            letterChoiceLabel(target), soundLetters.map(letterChoiceLabel))),
    MasteryQuestion(
        type: MasteryQuestionType.pictureLetter,
        prompt: target == 'I'
            ? 'Which letter is in the middle of $visualWord?'
            : 'Which letter does $visualWord ${target == 'X' ? 'end' : 'start'} with?',
        picture: picture(visualWord),
        answer: target,
        options: choices(target, letters)),
    MasteryQuestion(
        type: MasteryQuestionType.letterWord,
        prompt: target == 'I'
            ? 'Which word has I in the middle?'
            : 'Which word $verb with $target?',
        answer: matchingWord,
        options: choices(
            matchingWord,
            words.where((w) =>
                !matches(w) &&
                (target != 'I' || !w.toUpperCase().contains('I'))))),
    if (canMatchSound)
      MasteryQuestion(
          type: MasteryQuestionType.soundPicture,
          prompt: 'Listen. Which other word starts with the same sound?',
          audioPhrase: soundMatchCue,
          answer: picture(soundMatchAnswer),
          options:
              choices(picture(soundMatchAnswer), soundDistractors.map(picture)))
    else
      // With only one suitable example, test sound position instead of
      // awarding a point just for recognizing the word spoken aloud.
      MasteryQuestion(
          type: MasteryQuestionType.soundPosition,
          prompt:
              'Listen. Where do you hear ${content.phonemeDisplay} in the word?',
          audioPhrase: example(3),
          answer: target == 'X'
              ? 'End'
              : target == 'I'
                  ? 'Middle'
                  : 'Start',
          options: choices(
              target == 'X'
                  ? 'End'
                  : target == 'I'
                      ? 'Middle'
                      : 'Start',
              ['Start', 'Middle', 'End'])),
    if (usePosition)
      MasteryQuestion(
          type: MasteryQuestionType.soundPosition,
          prompt:
              'Listen. Where do you hear ${content.phonemeDisplay} in the word?',
          audioPhrase: finalWord,
          answer: target == 'X' ? 'End' : 'Start',
          options: choices(
              target == 'X' ? 'End' : 'Start', ['Start', 'Middle', 'End']))
    else
      MasteryQuestion(
          type: MasteryQuestionType.missingLetter,
          prompt: 'Listen. Which letter is missing?\n$masked',
          audioPhrase: finalWord,
          answer: target,
          options: choices(target, letters)),
  ];
}
