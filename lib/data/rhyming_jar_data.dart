import '../models/difficulty.dart';

class RhymingFamily {
  const RhymingFamily(this.target, this.rhymes);
  final String target;
  final List<String> rhymes;
  List<String> get words => [target, ...rhymes];
  String get praiseKey => 'rhyme-praise-${target.toLowerCase()}';
}

const rhymingFamilies = [
  RhymingFamily('LIP', ['HIP', 'DIP', 'SIP']),
  RhymingFamily('CAT', ['BAT', 'HAT', 'MAT']),
  RhymingFamily('SUN', ['FUN', 'RUN', 'BUN']),
  RhymingFamily('PEN', ['HEN', 'TEN', 'MEN']),
  RhymingFamily('PIG', ['BIG', 'WIG', 'DIG']),
  RhymingFamily('TOP', ['HOP', 'MOP', 'POP']),
  RhymingFamily('FAN', ['MAN', 'PAN', 'CAN']),
  RhymingFamily('BUG', ['HUG', 'MUG', 'RUG']),
  RhymingFamily('PIN', ['FIN', 'WIN', 'BIN']),
  RhymingFamily('BED', ['RED', 'FED', 'LED']),
];

String rhymeWordKey(String word) => 'rhyme-word-${word.toLowerCase()}';

String? rhymingAudioAsset(String key) {
  if (key == 'rhyme-intro') return 'audio/rhyming_jar/intro.mp3';
  for (final family in rhymingFamilies) {
    if (key == family.praiseKey) {
      return 'audio/rhyming_jar/praise-${family.target.toLowerCase()}.mp3';
    }
    for (final word in family.words) {
      if (key == rhymeWordKey(word)) {
        return 'audio/rhyming_jar/word-${word.toLowerCase()}.mp3';
      }
    }
  }
  return null;
}

List<String> rhymingChoices(RhymingFamily family, Difficulty difficulty) {
  // Every distractor belongs to a different ending-sound family.
  final others = rhymingFamilies.where((f) => f != family).toList()..shuffle();
  return [
    ...family.rhymes,
    ...others.take(2 + difficulty.index * 2).map((f) => f.target),
  ]..shuffle();
}
