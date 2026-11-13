/// One existing letter-sound recording for the missing written vowel.
class MissingVowelSoundStep {
  const MissingVowelSoundStep(this.phrase, this.positions);
  final String phrase;
  final List<int> positions;
}

List<MissingVowelSoundStep> missingVowelSoundSteps(String word) {
  final letters = word.toUpperCase();
  final blank = letters.indexOf(RegExp('[AEIOU]'));
  if (blank < 0) return const [];
  return [
    MissingVowelSoundStep('lesson-sound-${letters[blank]}', [blank])
  ];
}
