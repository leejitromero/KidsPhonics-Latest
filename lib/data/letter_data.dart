import 'game_word_data.dart';
// Central introductory sound scope. Teacher review: PHONICS_TEACHER_VALIDATION.md.
import '../models/difficulty.dart';

class LetterItem {
  final String letter, emoji, word, phonemeDisplay;
  final String position;
  const LetterItem(
      {required this.letter,
      required this.emoji,
      required this.word,
      required this.phonemeDisplay,
      this.position = 'beginning'});
  String get lowercase => letter.toLowerCase();
  bool get isVowel => 'AEIOU'.contains(letter);
  String get letterAudioKey => letter;
  // No existing recording is a verified isolated sound. NEEDS_REPLACEMENT.
  String? get soundAudioKey => null;
  String get wordAudioKey => word;
  String get sound {
    if (letter == 'Q') {
      return 'Q is often followed by U. Qu can make /kw/, as in queen.';
    }
    if (letter == 'X') return 'X can make /ks/, as at the end of fox.';
    if (isVowel) return '$letter has a short sound: $phonemeDisplay.';
    return '$letter can make the $phonemeDisplay sound.';
  }

  String get example => position == 'beginning'
      ? '$letter is for $word.'
      : position == 'end'
          ? '$letter is at the end of ${word.toLowerCase()}.'
          : '$letter is in the middle of ${word.toLowerCase()}.';
  String get soundQuestion => letter == 'Q'
      ? 'Listen. Which letters match the beginning sounds?'
      : letter == 'X'
          ? 'Listen. Which letter matches the ending /ks/ sounds?'
          : 'Listen. Which letter matches the $position sound?';
}

const List<LetterItem> allLetters = [
  LetterItem(
      letter: 'A',
      emoji: '🍎',
      word: 'Apple',
      phonemeDisplay: '/æ/',
      position: 'beginning'),
  LetterItem(
      letter: 'B',
      emoji: '🍌',
      word: 'Banana',
      phonemeDisplay: '/b/',
      position: 'beginning'),
  LetterItem(
      letter: 'C',
      emoji: '🐱',
      word: 'Cat',
      phonemeDisplay: '/k/',
      position: 'beginning'),
  LetterItem(
      letter: 'D',
      emoji: '🐶',
      word: 'Dog',
      phonemeDisplay: '/d/',
      position: 'beginning'),
  LetterItem(
      letter: 'E',
      emoji: '🥚',
      word: 'Egg',
      phonemeDisplay: '/ɛ/',
      position: 'beginning'),
  LetterItem(
      letter: 'F',
      emoji: '🐟',
      word: 'Fish',
      phonemeDisplay: '/f/',
      position: 'beginning'),
  LetterItem(
      letter: 'G',
      emoji: '🍇',
      word: 'Grapes',
      phonemeDisplay: '/g/',
      position: 'beginning'),
  LetterItem(
      letter: 'H',
      emoji: '🏠',
      word: 'House',
      phonemeDisplay: '/h/',
      position: 'beginning'),
  LetterItem(
      letter: 'I',
      emoji: '🐷',
      word: 'Pig',
      phonemeDisplay: '/ɪ/',
      position: 'middle'),
  LetterItem(
      letter: 'J',
      emoji: '🥤',
      word: 'Juice',
      phonemeDisplay: '/dʒ/',
      position: 'beginning'),
  LetterItem(
      letter: 'K',
      emoji: '🪁',
      word: 'Kite',
      phonemeDisplay: '/k/',
      position: 'beginning'),
  LetterItem(
      letter: 'L',
      emoji: '🦁',
      word: 'Lion',
      phonemeDisplay: '/l/',
      position: 'beginning'),
  LetterItem(
      letter: 'M',
      emoji: '🌙',
      word: 'Moon',
      phonemeDisplay: '/m/',
      position: 'beginning'),
  LetterItem(
      letter: 'N',
      emoji: '🌰',
      word: 'Nut',
      phonemeDisplay: '/n/',
      position: 'beginning'),
  LetterItem(
      letter: 'O',
      emoji: '🐙',
      word: 'Octopus',
      phonemeDisplay: '/ɒ/',
      position: 'beginning'),
  LetterItem(
      letter: 'P',
      emoji: '🐷',
      word: 'Pig',
      phonemeDisplay: '/p/',
      position: 'beginning'),
  LetterItem(
      letter: 'Q',
      emoji: '👑',
      word: 'Queen',
      phonemeDisplay: '/kw/',
      position: 'beginning'),
  LetterItem(
      letter: 'R',
      emoji: '🌈',
      word: 'Rainbow',
      phonemeDisplay: '/r/',
      position: 'beginning'),
  LetterItem(
      letter: 'S',
      emoji: '☀️',
      word: 'Sun',
      phonemeDisplay: '/s/',
      position: 'beginning'),
  LetterItem(
      letter: 'T',
      emoji: '🐢',
      word: 'Turtle',
      phonemeDisplay: '/t/',
      position: 'beginning'),
  LetterItem(
      letter: 'U',
      emoji: '☂️',
      word: 'Umbrella',
      phonemeDisplay: '/ʌ/',
      position: 'beginning'),
  LetterItem(
      letter: 'V',
      emoji: '🎻',
      word: 'Violin',
      phonemeDisplay: '/v/',
      position: 'beginning'),
  LetterItem(
      letter: 'W',
      emoji: '🐋',
      word: 'Whale',
      phonemeDisplay: '/w/',
      position: 'beginning'),
  LetterItem(
      letter: 'X',
      emoji: '🦊',
      word: 'Fox',
      phonemeDisplay: '/ks/',
      position: 'end'),
  LetterItem(
      letter: 'Y',
      emoji: '🧶',
      word: 'Yarn',
      phonemeDisplay: '/y/',
      position: 'beginning'),
  LetterItem(
      letter: 'Z',
      emoji: '🦓',
      word: 'Zebra',
      phonemeDisplay: '/z/',
      position: 'beginning'),
];

LetterItem letterContent(String letter) =>
    allLetters.firstWhere((item) => item.letter == letter.toUpperCase());
String letterChoiceLabel(String letter) => letter == 'Q' ? 'Qu' : letter;

// Do not present alternative spellings of the same sound as wrong answers.
List<String> soundChoices(String target, List<String> original) {
  final excluded = <String>{target};
  if (target == 'C' || target == 'K') excluded.addAll(['C', 'K', 'Q']);
  if (target == 'S') excluded.addAll(['C', 'X']);
  if (target == 'J') excluded.add('G');
  if (target == 'X') excluded.addAll(['S', 'Z']);
  final choices = <String>[target];
  for (final candidate in [
    ...original,
    'B',
    'D',
    'F',
    'L',
    'M',
    'N',
    'R',
    'T',
    'V'
  ]) {
    if (!excluded.contains(candidate) && !choices.contains(candidate)) {
      choices.add(candidate);
    }
    if (choices.length == original.length) break;
  }
  return List.unmodifiable(choices);
}

class SoundRound {
  final String correctLetter;
  final GameWord? artwork;
  final List<String> options;
  SoundRound(this.correctLetter, List<String> choices, {this.artwork})
      : options = soundChoices(correctLetter, choices);
  LetterItem get content => letterContent(correctLetter);
  String get emoji => content.emoji;
  String get word => artwork?.word ?? content.word;
  String get voiceHint => word;
  String get question => artwork == null
      ? content.soundQuestion
      : 'Listen. Which letter starts this word?';
}

class QuizQuestion extends SoundRound {
  QuizQuestion(super.correctLetter, super.choices, {super.artwork});
}

final List<SoundRound> soundRounds = [
  SoundRound('A', ['A', 'B', 'C', 'D']),
  SoundRound('D', ['B', 'D', 'F', 'G']),
  SoundRound('S', ['S', 'T', 'P', 'R']),
  SoundRound('F', ['E', 'F', 'H', 'K']),
  SoundRound('R', ['L', 'M', 'R', 'N']),
];
final List<SoundRound> soundRoundsEasy = [
  SoundRound('S', ['S', 'T', 'R']),
  SoundRound('T', ['S', 'T', 'U']),
  SoundRound('U', ['U', 'V', 'O']),
  SoundRound('V', ['V', 'W', 'B']),
  SoundRound('W', ['W', 'V', 'Y']),
  SoundRound('X', ['X', 'Z', 'S']),
];
final List<SoundRound> soundRoundsMedium = [
  SoundRound('N', ['N', 'M', 'R', 'L']),
  SoundRound('O', ['O', 'U', 'A', 'E']),
  SoundRound('P', ['P', 'B', 'D', 'T']),
  SoundRound('Q', ['Q', 'K', 'C', 'G']),
  SoundRound('R', ['R', 'L', 'W', 'N']),
  SoundRound('S', ['S', 'Z', 'C', 'X']),
  SoundRound('T', ['T', 'D', 'S', 'P']),
];
final List<SoundRound> soundRoundsHard = [
  SoundRound('U', ['U', 'A', 'O', 'E', 'I']),
  SoundRound('V', ['V', 'B', 'F', 'W', 'P']),
  SoundRound('W', ['W', 'V', 'Y', 'M', 'H']),
  SoundRound('X', ['X', 'Z', 'S', 'C', 'J']),
  SoundRound('Y', ['Y', 'J', 'W', 'I', 'E']),
  SoundRound('Z', ['Z', 'S', 'X', 'C', 'J']),
  SoundRound('Q', ['Q', 'K', 'C', 'G', 'W']),
];
List<SoundRound> soundRoundsForDifficulty(Difficulty d) => [
      for (final w in gameWordsFor(d))
        SoundRound(
            w.letter,
            [
              w.letter,
              ...'BCDFHKLMNPRSTVW'
                  .split('')
                  .where((l) => l != w.letter)
                  .take(d.index + 2)
            ],
            artwork: w),
    ];
final List<QuizQuestion> quizQuestions = [
  QuizQuestion('D', ['B', 'C', 'D', 'G']),
  QuizQuestion('S', ['S', 'P', 'T', 'R']),
  QuizQuestion('A', ['A', 'E', 'I', 'O']),
  QuizQuestion('F', ['H', 'F', 'V', 'B']),
  QuizQuestion('R', ['L', 'W', 'R', 'N']),
];
final List<QuizQuestion> quizQuestionsEasy = [
  QuizQuestion('A', ['A', 'B', 'C']),
  QuizQuestion('B', ['B', 'C', 'D']),
  QuizQuestion('C', ['A', 'C', 'D']),
  QuizQuestion('D', ['B', 'D', 'F']),
  QuizQuestion('E', ['A', 'E', 'I']),
];
final List<QuizQuestion> quizQuestionsMedium = [
  QuizQuestion('F', ['H', 'F', 'V', 'B']),
  QuizQuestion('G', ['G', 'J', 'K', 'H']),
  QuizQuestion('H', ['H', 'J', 'K', 'G']),
  QuizQuestion('I', ['A', 'E', 'I', 'O']),
  QuizQuestion('J', ['J', 'G', 'K', 'H']),
  QuizQuestion('K', ['K', 'C', 'G', 'Q']),
];
final List<QuizQuestion> quizQuestionsHard = [
  QuizQuestion('S', ['S', 'Z', 'C', 'X']),
  QuizQuestion('T', ['T', 'D', 'S', 'P']),
  QuizQuestion('U', ['U', 'A', 'O', 'E']),
  QuizQuestion('V', ['V', 'B', 'F', 'W']),
  QuizQuestion('W', ['W', 'V', 'H', 'M']),
  QuizQuestion('Y', ['Y', 'J', 'W', 'I']),
  QuizQuestion('Z', ['Z', 'S', 'X', 'C']),
];
List<QuizQuestion> quizQuestionsForDifficulty(Difficulty d) => [
      for (final w in gameWordsFor(d))
        QuizQuestion(
            w.letter,
            [
              w.letter,
              ...'BCDFHKLMNPRSTVW'
                  .split('')
                  .where((l) => l != w.letter)
                  .take(d.index + 2)
            ],
            artwork: w),
    ];

class MemoryPair {
  final String letter;
  const MemoryPair(this.letter);
  String get emoji => letterContent(letter).emoji;
  String get word => letterContent(letter).word;
}

const List<MemoryPair> memoryPairs = [
  MemoryPair('A'),
  MemoryPair('B'),
  MemoryPair('C'),
  MemoryPair('D'),
  MemoryPair('S'),
  MemoryPair('F')
];
const List<MemoryPair> memoryPairsEasy = [
  MemoryPair('A'),
  MemoryPair('B'),
  MemoryPair('C'),
  MemoryPair('D')
];
const List<MemoryPair> memoryPairsMedium = [
  MemoryPair('E'),
  MemoryPair('F'),
  MemoryPair('G'),
  MemoryPair('H'),
  MemoryPair('I'),
  MemoryPair('J')
];
const List<MemoryPair> memoryPairsHard = [
  MemoryPair('K'),
  MemoryPair('L'),
  MemoryPair('M'),
  MemoryPair('N'),
  MemoryPair('O'),
  MemoryPair('P'),
  MemoryPair('Q'),
  MemoryPair('R')
];
List<MemoryPair> memoryPairsForDifficulty(Difficulty d) => switch (d) {
      Difficulty.easy => memoryPairsEasy,
      Difficulty.medium => memoryPairsMedium,
      Difficulty.hard => memoryPairsHard,
    };

// Whole-word recognition practice, not pronunciation assessment.
final Map<Difficulty, List<Map<String, String>>> voiceWords = {
  for (final d in Difficulty.values)
    d: [
      for (final w in gameWordsFor(d))
        {'word': w.word, 'emoji': '', 'hint': w.audioKey},
    ],
};
