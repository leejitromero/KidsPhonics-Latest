/// A recording and the word positions it actually pronounces.
class MissingVowelSoundStep {
  const MissingVowelSoundStep(this.phrase, this.positions);
  final String phrase;
  final List<int> positions;
}

/// These catalog words use the supplied single-letter sound recordings without
/// silent letters, vowel teams, or a different vowel pronunciation.
const _singleLetterSoundWords = {
  'BAG',
  'DOG',
  'FAN',
  'HAND',
  'LIPS',
  'NET',
  'PEN',
  'TUB',
  'WEB',
  'ZIP',
  'FROG',
  'NEST',
};

// Long vowels reuse the matching recorded letter name (A /ay/, E /ee/,
// I /eye/, O /oh/). A group is highlighted together, including its silent E.
const _groupedSoundWords = <String, List<MissingVowelSoundStep>>{
  'AXE': [
    MissingVowelSoundStep('lesson-sound-A', [0]),
    MissingVowelSoundStep('lesson-sound-X', [1, 2])
  ],
  'GOAT': [
    MissingVowelSoundStep('lesson-sound-G', [0]),
    MissingVowelSoundStep('lesson-letter-O', [1, 2]),
    MissingVowelSoundStep('lesson-sound-T', [3])
  ],
  'ICE': [
    MissingVowelSoundStep('lesson-letter-I', [0, 2]),
    MissingVowelSoundStep('lesson-sound-S', [1])
  ],
  'KEY': [
    MissingVowelSoundStep('lesson-sound-K', [0]),
    MissingVowelSoundStep('lesson-letter-E', [1, 2])
  ],
  'ROSE': [
    MissingVowelSoundStep('lesson-sound-R', [0]),
    MissingVowelSoundStep('lesson-letter-O', [1, 3]),
    MissingVowelSoundStep('lesson-sound-Z', [2])
  ],
  'GRAPES': [
    MissingVowelSoundStep('lesson-sound-G', [0]),
    MissingVowelSoundStep('lesson-sound-R', [1]),
    MissingVowelSoundStep('lesson-letter-A', [2, 4]),
    MissingVowelSoundStep('lesson-sound-P', [3]),
    MissingVowelSoundStep('lesson-sound-S', [5])
  ],
  'LAMB': [
    MissingVowelSoundStep('lesson-sound-L', [0]),
    MissingVowelSoundStep('lesson-sound-A', [1]),
    MissingVowelSoundStep('lesson-sound-M', [2, 3])
  ],
  'PLATE': [
    MissingVowelSoundStep('lesson-sound-P', [0]),
    MissingVowelSoundStep('lesson-sound-L', [1]),
    MissingVowelSoundStep('lesson-letter-A', [2, 4]),
    MissingVowelSoundStep('lesson-sound-T', [3])
  ],
  'QUEEN': [
    MissingVowelSoundStep('lesson-sound-Q', [0, 1]),
    MissingVowelSoundStep('lesson-letter-E', [2, 3]),
    MissingVowelSoundStep('lesson-sound-N', [4])
  ],
  'RABBIT': [
    MissingVowelSoundStep('lesson-sound-R', [0]),
    MissingVowelSoundStep('lesson-sound-A', [1]),
    MissingVowelSoundStep('lesson-sound-B', [2, 3]),
    MissingVowelSoundStep('lesson-sound-I', [4]),
    MissingVowelSoundStep('lesson-sound-T', [5])
  ],
  'QUACK': [
    MissingVowelSoundStep('lesson-sound-Q', [0, 1]),
    MissingVowelSoundStep('lesson-sound-A', [2]),
    MissingVowelSoundStep('lesson-sound-K', [3, 4])
  ],
  'TRAIN': [
    MissingVowelSoundStep('lesson-sound-T', [0]),
    MissingVowelSoundStep('lesson-sound-R', [1]),
    MissingVowelSoundStep('lesson-letter-A', [2, 3]),
    MissingVowelSoundStep('lesson-sound-N', [4])
  ],
  'WHALE': [
    MissingVowelSoundStep('lesson-sound-W', [0, 1]),
    MissingVowelSoundStep('lesson-letter-A', [2, 4]),
    MissingVowelSoundStep('lesson-sound-L', [3])
  ],
};

List<MissingVowelSoundStep> missingVowelSoundSteps(String word) {
  final letters = word.toUpperCase();
  final all = List.generate(letters.length, (i) => i);
  final groups = _groupedSoundWords[letters];
  if (groups != null) return [...groups, MissingVowelSoundStep(word, all)];
  if (!_singleLetterSoundWords.contains(letters)) {
    // Keep the catalog and its correct pronunciation. Never substitute short
    // O for OO in MOON, or sound a silent letter, without a matching recording.
    return [MissingVowelSoundStep(word, all)];
  }
  return [
    for (var i = 0; i < letters.length; i++)
      MissingVowelSoundStep('lesson-sound-${letters[i]}', [i]),
    MissingVowelSoundStep(word, all),
  ];
}
