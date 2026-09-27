import 'game_word_data.dart';
// Proposed activity content; teacher approval is pending. See PHONICS_TEACHER_VALIDATION.md.
import '../models/difficulty.dart';
import 'letter_data.dart';

// ── Data model ────────────────────────────────────────────────────────────

class RhymeRound {
  final String emoji;
  final String word;
  final String correctRhyme;
  final List<RhymeOption> options;
  final String hint;

  const RhymeRound({
    required this.emoji,
    required this.word,
    required this.correctRhyme,
    required this.options,
    required this.hint,
  });
}

class RhymeOption {
  final String word;
  final String emoji;
  const RhymeOption(this.word, this.emoji);
}

// ── Difficulty-tiered round lists ─────────────────────────────────────────

// Easy — 3 options, very common short words
// Each cue has supplied three-frame artwork and a new word recording.
// Choices without matching artwork remain text.
List<RhymeRound> rhymeRoundsForDifficulty(Difficulty d) {
  final pairs = switch (d) {
    Difficulty.easy => [
        ('CAT', 'HAT'),
        ('HAT', 'CAT'),
        ('SUN', 'FUN'),
        ('BALL', 'TALL')
      ],
    Difficulty.medium => [
        ('FISH', 'DISH'),
        ('NEST', 'BEST'),
        ('VAN', 'FAN'),
        ('KITE', 'NIGHT'),
        ('QUEEN', 'GREEN'),
        ('WHALE', 'TAIL')
      ],
    Difficulty.hard => [
        ('CAT', 'MAT'),
        ('HAT', 'BAT'),
        ('SUN', 'RUN'),
        ('BALL', 'WALL'),
        ('FISH', 'WISH'),
        ('QUEEN', 'SEEN'),
        ('WHALE', 'SNAIL')
      ],
  };
  const pool = [
    'ANT',
    'DRUM',
    'EGG',
    'FISH',
    'KITE',
    'QUEEN',
    'VAN',
    'NEST',
    'SUN',
    'BALL',
    'WHALE'
  ];
  return [
    for (var i = 0; i < pairs.length; i++)
      RhymeRound(
        emoji: '',
        word: pairs[i].$1,
        correctRhyme: pairs[i].$2,
        options: [
          RhymeOption(pairs[i].$2, ''),
          ...[for (var j = 0; j < pool.length; j++) pool[(i + j) % pool.length]]
              .where((word) => word != pairs[i].$1 && word != pairs[i].$2)
              .take(d.index + 2)
              .map((word) => RhymeOption(word, ''))
        ],
        hint: 'Listen for the same ending sounds.',
      ),
  ];
}
// ── Screen ────────────────────────────────────────────────────────────────

// ── Data model ────────────────────────────────────────────────────────────
//
// [blanks] is a List<String?> where null means "blank to fill".
// [correctLetters] is the ordered list of answers for each blank.
// [tiles] are the letter choices shown to the child.

class WordPuzzle {
  final String emoji;
  final String word;
  final List<String?> blanks; // null = blank slot
  final List<String> correctLetters; // one per blank slot, in order
  final List<String> tiles; // letter choices shown
  final String voiceHint;

  const WordPuzzle({
    required this.emoji,
    required this.word,
    required this.blanks,
    required this.correctLetters,
    required this.tiles,
    required this.voiceHint,
  });
}

// ── Easy — 1 blank (simple CVC) ─────────────────────────────────────────
final wordPuzzlesEasy = [
  const WordPuzzle(
    emoji: '🐱',
    word: 'CAT',
    blanks: ['C', null, 'T'],
    correctLetters: ['A'],
    tiles: ['A', 'B', 'E', 'O'],
    voiceHint: 'C... blank... T. What is in the middle?',
  ),
  const WordPuzzle(
    emoji: '🐶',
    word: 'DOG',
    blanks: ['D', null, 'G'],
    correctLetters: ['O'],
    tiles: ['O', 'U', 'A', 'I'],
    voiceHint: 'D... blank... G. Fill in the middle!',
  ),
  const WordPuzzle(
    emoji: '☀️',
    word: 'SUN',
    blanks: ['S', null, 'N'],
    correctLetters: ['U'],
    tiles: ['U', 'A', 'O', 'I'],
    voiceHint: 'S... blank... N. What letter goes here?',
  ),
];

// ── Medium — 2 blanks ────────────────────────────────────────────────────
final wordPuzzlesMedium = [
  const WordPuzzle(
    emoji: '🍇',
    word: 'GRAPES',
    blanks: ['G', null, 'A', 'P', null, 'S'],
    correctLetters: ['R', 'E'],
    tiles: ['R', 'E', 'T', 'O', 'U', 'N'],
    voiceHint: 'G... blank... A... P... blank... S. What letters are missing?',
  ),
  const WordPuzzle(
    emoji: '🏠',
    word: 'HOUSE',
    blanks: [null, 'O', 'U', 'S', null],
    correctLetters: ['H', 'E'],
    tiles: ['H', 'E', 'B', 'A', 'I', 'T'],
    voiceHint: 'blank... O... U... S... blank. What are the missing letters?',
  ),
  const WordPuzzle(
    emoji: '🌙',
    word: 'MOON',
    blanks: ['M', null, null, 'N'],
    correctLetters: ['O', 'O'],
    tiles: ['O', 'A', 'U', 'I', 'E', 'Y'],
    voiceHint: 'M... blank... blank... N. Two letters are missing!',
  ),
  const WordPuzzle(
    emoji: '🐟',
    word: 'FISH',
    blanks: ['F', null, 'S', null],
    correctLetters: ['I', 'H'],
    tiles: ['I', 'H', 'A', 'E', 'O', 'T'],
    voiceHint: 'F... blank... S... blank. Fill in the two missing letters!',
  ),
  const WordPuzzle(
    emoji: '🦁',
    word: 'LION',
    blanks: ['L', null, 'O', null],
    correctLetters: ['I', 'N'],
    tiles: ['I', 'N', 'A', 'E', 'M', 'T'],
    voiceHint: 'L... blank... O... blank. What letters come next?',
  ),
];

// ── Hard — 2 to 3 blanks ─────────────────────────────────────────────────
final wordPuzzlesHard = [
  const WordPuzzle(
    emoji: '🌈',
    word: 'RAINBOW',
    blanks: ['R', null, 'I', null, 'B', null, 'W'],
    correctLetters: ['A', 'N', 'O'],
    tiles: ['A', 'N', 'O', 'E', 'T', 'U'],
    voiceHint:
        'R... blank... I... blank... B... blank... W. Three letters missing!',
  ),
  const WordPuzzle(
    emoji: '☂️',
    word: 'UMBRELLA',
    blanks: [null, 'M', null, 'R', 'E', null, 'L', 'A'],
    correctLetters: ['U', 'B', 'L'],
    tiles: ['U', 'B', 'L', 'O', 'A', 'T'],
    voiceHint:
        'blank... M... blank... R... E... blank... L... A. Three missing!',
  ),
  const WordPuzzle(
    emoji: '🦓',
    word: 'ZEBRA',
    blanks: [null, 'E', null, 'R', null],
    correctLetters: ['Z', 'B', 'A'],
    tiles: ['Z', 'B', 'A', 'X', 'D', 'O'],
    voiceHint: 'Listen to zebra. Fill in the missing letters.',
  ),
  const WordPuzzle(
    emoji: '🐢',
    word: 'TURTLE',
    blanks: ['T', null, 'R', null, 'L', null],
    correctLetters: ['U', 'T', 'E'],
    tiles: ['U', 'T', 'E', 'A', 'O', 'S'],
    voiceHint: 'T... blank... R... blank... L... blank. Three letters to find!',
  ),
  const WordPuzzle(
    emoji: '🍌',
    word: 'BANANA',
    blanks: ['B', null, 'N', null, 'N', null],
    correctLetters: ['A', 'A', 'A'],
    tiles: ['A', 'E', 'I', 'O', 'U', 'B'],
    voiceHint:
        'B... blank... N... blank... N... blank. What vowel fills all three?',
  ),
];

List<WordPuzzle> wordPuzzlesForDifficulty(Difficulty d) => [
      for (final item in gameWordsFor(d).where((w) => !w.word.contains(' ')))
        _wordPuzzle(item, d.index + 1),
    ];
WordPuzzle _wordPuzzle(GameWord item, int count) {
  final letters = item.word.toUpperCase().split('');
  final indices = List.generate(
      count, (i) => ((i + 1) * letters.length / (count + 1)).floor()).toSet();
  final answers = [
    for (var i = 0; i < letters.length; i++)
      if (indices.contains(i)) letters[i]
  ];
  return WordPuzzle(
      emoji: '',
      word: item.word.toUpperCase(),
      blanks: [
        for (var i = 0; i < letters.length; i++)
          indices.contains(i) ? null : letters[i]
      ],
      correctLetters: answers,
      tiles: {...answers, ...'AEIOTR'.split('')}.toList(),
      voiceHint: item.audioKey);
}

// ── Screen ────────────────────────────────────────────────────────────────

// ── Data ──────────────────────────────────────────────────────────────────

class VowelPuzzle {
  final String emoji;
  final String word; // full word e.g. "CAT"
  final String display; // display with blank e.g. "C_T"
  final String vowel; // correct vowel e.g. "A"
  final String hint;

  const VowelPuzzle({
    required this.emoji,
    required this.word,
    required this.display,
    required this.vowel,
    required this.hint,
  });
}

const vowelPuzzlesEasy = [
  VowelPuzzle(
      emoji: '🐱',
      word: 'CAT',
      display: 'C _ T',
      vowel: 'A',
      hint: 'C... A... T. Cat!'),
  VowelPuzzle(
      emoji: '🥚',
      word: 'EGG',
      display: '_ G G',
      vowel: 'E',
      hint: 'E... G... G. Egg!'),
  VowelPuzzle(
      emoji: '🐟',
      word: 'FIN',
      display: 'F _ N',
      vowel: 'I',
      hint: 'F... I... N. Fin!'),
];

// Medium — completely different words from Easy, all vowels in A/E/I/O/U set
const vowelPuzzlesMedium = [
  VowelPuzzle(
      emoji: '🐷',
      word: 'PIG',
      display: 'P _ G',
      vowel: 'I',
      hint: 'P... I... G. Pig!'),
  VowelPuzzle(
      emoji: '☀️',
      word: 'SUN',
      display: 'S _ N',
      vowel: 'U',
      hint: 'S... U... N. Sun!'),
  VowelPuzzle(
      emoji: '🐶',
      word: 'DOG',
      display: 'D _ G',
      vowel: 'O',
      hint: 'Listen to dog. Fill in the missing vowel.'),
  VowelPuzzle(
      emoji: '🐗',
      word: 'HOG',
      display: 'H _ G',
      vowel: 'O',
      hint: 'H... O... G. Hog!'),
  VowelPuzzle(
      emoji: '🦁',
      word: 'CUB',
      display: 'C _ B',
      vowel: 'U',
      hint: 'C... U... B. Cub!'),
];

// Hard — completely different words from Easy and Medium
const vowelPuzzlesHard = [
  VowelPuzzle(
      emoji: '🐟',
      word: 'FIN',
      display: 'F _ N',
      vowel: 'I',
      hint: 'F... I... N. Fin!'),
  VowelPuzzle(
      emoji: '🌰',
      word: 'NUT',
      display: 'N _ T',
      vowel: 'U',
      hint: 'N... U... T. Nut!'),
  VowelPuzzle(
      emoji: '🧹',
      word: 'MOP',
      display: 'M _ P',
      vowel: 'O',
      hint: 'M... O... P. Mop!'),
  VowelPuzzle(
      emoji: '🐭',
      word: 'RAT',
      display: 'R _ T',
      vowel: 'A',
      hint: 'R... A... T. Rat!'),
  VowelPuzzle(
      emoji: '🐱',
      word: 'CAT',
      display: 'C _ T',
      vowel: 'A',
      hint: 'Listen to cat. Fill in the missing vowel.'),
  VowelPuzzle(
      emoji: '💋',
      word: 'LIP',
      display: 'L _ P',
      vowel: 'I',
      hint: 'L... I... P. Lip!'),
  VowelPuzzle(
      emoji: '🐗',
      word: 'HOG',
      display: 'H _ G',
      vowel: 'O',
      hint: 'Listen to hog. Fill in the missing vowel.'),
];

List<VowelPuzzle> vowelPuzzlesFor(Difficulty d) => [
      for (final item in gameWordsFor(d).where((w) => !w.word.contains(' ')))
        if (RegExp('[AEIOU]').hasMatch(item.word.toUpperCase()))
          _vowelPuzzle(item),
    ];
VowelPuzzle _vowelPuzzle(GameWord item) {
  final word = item.word.toUpperCase();
  final index = word.indexOf(RegExp('[AEIOU]'));
  return VowelPuzzle(
      emoji: '',
      word: word,
      display: word.replaceRange(index, index + 1, '_').split('').join(' '),
      vowel: word[index],
      hint: item.audioKey);
}

List<String> vowelChoicesFor(Difficulty d, String correctVowel) {
  // Build the vowel set for this difficulty, always ensuring
  // the correct answer is present — swap out last distractor if needed.
  List<String> base;
  switch (d) {
    case Difficulty.easy:
      base = ['A', 'E', 'I'];
      break;
    case Difficulty.medium:
      base = ['A', 'E', 'I', 'O'];
      break;
    case Difficulty.hard:
      base = ['A', 'E', 'I', 'O', 'U'];
      break;
  }
  // If correct vowel is already in set, return as-is
  if (base.contains(correctVowel)) return base;
  // Otherwise replace the last element with the correct vowel
  final result = List<String>.from(base);
  result[result.length - 1] = correctVowel;
  return result;
}

// ── Screen ────────────────────────────────────────────────────────────────

enum SoundPosition { beginning, middle, end }

extension SoundPositionLabel on SoundPosition {
  String get label {
    switch (this) {
      case SoundPosition.beginning:
        return 'Beginning';
      case SoundPosition.middle:
        return 'Middle';
      case SoundPosition.end:
        return 'End';
    }
  }

  String get emoji {
    switch (this) {
      case SoundPosition.beginning:
        return '⬅️';
      case SoundPosition.middle:
        return '⬛';
      case SoundPosition.end:
        return '➡️';
    }
  }
}

class SoundPositionRound {
  final String emoji;
  final String word;
  final String targetLetter;
  final SoundPosition correctPos;
  final List<SoundPosition> options;
  final String hint;
  String get soundDisplay => targetLetter == 'SH'
      ? '/sh/'
      : letterContent(targetLetter).phonemeDisplay;

  const SoundPositionRound({
    required this.emoji,
    required this.word,
    required this.targetLetter,
    required this.correctPos,
    required this.options,
    required this.hint,
  });
}

// Easy — only BEGINNING position, 3 unique words, 2 choices (Beginning/End)
const positionRoundsEasy = [
  SoundPositionRound(
      emoji: '🍎',
      word: 'APPLE',
      targetLetter: 'A',
      correctPos: SoundPosition.beginning,
      options: [SoundPosition.beginning, SoundPosition.end],
      hint: 'Listen to apple. The sound is at the beginning.'),
  SoundPositionRound(
      emoji: '🍌',
      word: 'BANANA',
      targetLetter: 'B',
      correctPos: SoundPosition.beginning,
      options: [SoundPosition.beginning, SoundPosition.end],
      hint: 'Listen to banana. The sound is at the beginning.'),
  SoundPositionRound(
      emoji: '🥚',
      word: 'EGG',
      targetLetter: 'E',
      correctPos: SoundPosition.beginning,
      options: [SoundPosition.beginning, SoundPosition.end],
      hint: 'Listen to egg. The sound is at the beginning.'),
];

// Medium — BEGINNING + END, 5 unique words (none from Easy), 2 choices
const positionRoundsMedium = [
  SoundPositionRound(
      emoji: '🐟',
      word: 'FISH',
      targetLetter: 'F',
      correctPos: SoundPosition.beginning,
      options: [SoundPosition.beginning, SoundPosition.end],
      hint: 'Listen to fish. The sound is at the beginning.'),
  SoundPositionRound(
      emoji: '🐟',
      word: 'FISH',
      targetLetter: 'SH',
      correctPos: SoundPosition.end,
      options: [SoundPosition.beginning, SoundPosition.end],
      hint: 'Listen to fish. The sound is at the end.'),
  SoundPositionRound(
      emoji: '🌙',
      word: 'MOON',
      targetLetter: 'M',
      correctPos: SoundPosition.beginning,
      options: [SoundPosition.beginning, SoundPosition.end],
      hint: 'Listen to moon. The sound is at the beginning.'),
  SoundPositionRound(
      emoji: '🌙',
      word: 'MOON',
      targetLetter: 'N',
      correctPos: SoundPosition.end,
      options: [SoundPosition.beginning, SoundPosition.end],
      hint: 'Listen to moon. The sound is at the end.'),
  SoundPositionRound(
      emoji: '🪁',
      word: 'KITE',
      targetLetter: 'K',
      correctPos: SoundPosition.beginning,
      options: [SoundPosition.beginning, SoundPosition.end],
      hint: 'Listen to kite. The sound is at the beginning.'),
];

// Hard — BEGINNING + MIDDLE + END, 7 unique words (none from Easy/Medium), 3 choices
const positionRoundsHard = [
  SoundPositionRound(
      emoji: '🦁',
      word: 'LION',
      targetLetter: 'L',
      correctPos: SoundPosition.beginning,
      options: [
        SoundPosition.beginning,
        SoundPosition.middle,
        SoundPosition.end
      ],
      hint: 'Listen to lion. The sound is at the beginning.'),
  SoundPositionRound(
      emoji: '🐷',
      word: 'PIG',
      targetLetter: 'I',
      correctPos: SoundPosition.middle,
      options: [
        SoundPosition.beginning,
        SoundPosition.middle,
        SoundPosition.end
      ],
      hint: 'Listen to pig. The sound is in the middle.'),
  SoundPositionRound(
      emoji: '🦁',
      word: 'LION',
      targetLetter: 'N',
      correctPos: SoundPosition.end,
      options: [
        SoundPosition.beginning,
        SoundPosition.middle,
        SoundPosition.end
      ],
      hint: 'Listen to lion. The sound is at the end.'),
  SoundPositionRound(
      emoji: '🌈',
      word: 'RAIN',
      targetLetter: 'R',
      correctPos: SoundPosition.beginning,
      options: [
        SoundPosition.beginning,
        SoundPosition.middle,
        SoundPosition.end
      ],
      hint: 'Listen to rain. The sound is at the beginning.'),
  SoundPositionRound(
      emoji: '🐱',
      word: 'CAT',
      targetLetter: 'A',
      correctPos: SoundPosition.middle,
      options: [
        SoundPosition.beginning,
        SoundPosition.middle,
        SoundPosition.end
      ],
      hint: 'Listen to cat. The sound is in the middle.'),
  SoundPositionRound(
      emoji: '🌈',
      word: 'RAIN',
      targetLetter: 'N',
      correctPos: SoundPosition.end,
      options: [
        SoundPosition.beginning,
        SoundPosition.middle,
        SoundPosition.end
      ],
      hint: 'Listen to rain. The sound is at the end.'),
  SoundPositionRound(
      emoji: '🐋',
      word: 'WHALE',
      targetLetter: 'W',
      correctPos: SoundPosition.beginning,
      options: [
        SoundPosition.beginning,
        SoundPosition.middle,
        SoundPosition.end
      ],
      hint: 'Listen to whale. The sound is at the beginning.'),
];

List<SoundPositionRound> positionRoundsFor(Difficulty d) {
  switch (d) {
    case Difficulty.easy:
      return positionRoundsEasy;
    case Difficulty.medium:
      return positionRoundsMedium;
    case Difficulty.hard:
      return positionRoundsHard;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────

// ── Data ──────────────────────────────────────────────────────────────────

class PictureWordRound {
  final String word; // word to match
  final String correctEmoji; // correct picture
  final List<String> options; // all emojis shown (incl. correct)
  final List<String> labels; // word labels for each emoji
  final String hint;

  const PictureWordRound({
    required this.word,
    required this.correctEmoji,
    required this.options,
    required this.labels,
    required this.hint,
  });
}

const pictureRoundsEasy = [
  PictureWordRound(
      word: 'CAT',
      correctEmoji: '🐱',
      options: ['🐱', '🐶', '🌈'],
      labels: ['Cat', 'Dog', 'Rainbow'],
      hint: 'Cat! C-A-T, Cat!'),
  PictureWordRound(
      word: 'SUN',
      correctEmoji: '☀️',
      options: ['🌙', '☀️', '🍎'],
      labels: ['Moon', 'Sun', 'Apple'],
      hint: 'Sun! S-U-N, Sun!'),
  PictureWordRound(
      word: 'EGG',
      correctEmoji: '🥚',
      options: ['🥚', '🐟', '🏠'],
      labels: ['Egg', 'Fish', 'House'],
      hint: 'Egg! E-G-G, Egg!'),
  PictureWordRound(
      word: 'BEE',
      correctEmoji: '🐝',
      options: ['🐱', '🐝', '🌙'],
      labels: ['Cat', 'Bee', 'Moon'],
      hint: 'Bee! B-E-E, Bee!'),
];

const pictureRoundsMedium = [
  PictureWordRound(
      word: 'FISH',
      correctEmoji: '🐟',
      options: ['🐱', '🐟', '🌈', '🏠'],
      labels: ['Cat', 'Fish', 'Rainbow', 'House'],
      hint: 'Fish! F-I-S-H!'),
  PictureWordRound(
      word: 'MOON',
      correctEmoji: '🌙',
      options: ['☀️', '🌙', '🥚', '🐷'],
      labels: ['Sun', 'Moon', 'Egg', 'Pig'],
      hint: 'Moon! M-O-O-N!'),
  PictureWordRound(
      word: 'KITE',
      correctEmoji: '🪁',
      options: ['🪁', '🐶', '🍎', '🐢'],
      labels: ['Kite', 'Dog', 'Apple', 'Turtle'],
      hint: 'Kite! K-I-T-E!'),
  PictureWordRound(
      word: 'LION',
      correctEmoji: '🦁',
      options: ['🦁', '🐋', '🎻', '🌙'],
      labels: ['Lion', 'Whale', 'Violin', 'Moon'],
      hint: 'Lion! L-I-O-N!'),
  PictureWordRound(
      word: 'APPLE',
      correctEmoji: '🍎',
      options: ['🍌', '🍎', '🐱', '☀️'],
      labels: ['Banana', 'Apple', 'Cat', 'Sun'],
      hint: 'Apple! A-P-P-L-E!'),
];

const pictureRoundsHard = [
  PictureWordRound(
      word: 'RAINBOW',
      correctEmoji: '🌈',
      options: ['🌈', '🐟', '🥚', '🐱', '🌙'],
      labels: ['Rainbow', 'Fish', 'Egg', 'Cat', 'Moon'],
      hint: 'Rainbow! R-A-I-N-B-O-W!'),
  PictureWordRound(
      word: 'UMBRELLA',
      correctEmoji: '☂️',
      options: ['☂️', '🦁', '🍎', '🐋', '🎻'],
      labels: ['Umbrella', 'Lion', 'Apple', 'Whale', 'Violin'],
      hint: 'Umbrella! U-M-B-R-E-L-L-A!'),
  PictureWordRound(
      word: 'ZEBRA',
      correctEmoji: '🦓',
      options: ['🦓', '🐶', '🌈', '🪁', '🥚'],
      labels: ['Zebra', 'Dog', 'Rainbow', 'Kite', 'Egg'],
      hint: 'Zebra! Z-E-B-R-A!'),
  PictureWordRound(
      word: 'VIOLIN',
      correctEmoji: '🎻',
      options: ['🎻', '🏠', '☀️', '🐷', '🌙'],
      labels: ['Violin', 'House', 'Sun', 'Pig', 'Moon'],
      hint: 'Violin! V-I-O-L-I-N!'),
  PictureWordRound(
      word: 'OCTOPUS',
      correctEmoji: '🐙',
      options: ['🐙', '🦁', '🍌', '☂️', '🦓'],
      labels: ['Octopus', 'Lion', 'Banana', 'Umbrella', 'Zebra'],
      hint: 'Octopus! O-C-T-O-P-U-S!'),
  PictureWordRound(
      word: 'FOX',
      correctEmoji: '🦊',
      options: ['🦊', '🐙', '🦓', '🎻', '☂️'],
      labels: ['Fox', 'Octopus', 'Zebra', 'Violin', 'Umbrella'],
      hint: 'Fox! F-O-X!'),
];

List<PictureWordRound> pictureRoundsFor(Difficulty d) {
  final pool = gameWordsFor(d);
  return [
    for (var i = 0; i < pool.length; i++)
      PictureWordRound(
        word: pool[i].word.toUpperCase(),
        correctEmoji: pool[i].word,
        options: [
          for (var j = 0; j < d.index + 3; j++) pool[(i + j) % pool.length].word
        ],
        labels: [
          for (var j = 0; j < d.index + 3; j++) pool[(i + j) % pool.length].word
        ],
        hint: pool[i].audioKey,
      )
  ];
}

// ── Screen ────────────────────────────────────────────────────────────────
