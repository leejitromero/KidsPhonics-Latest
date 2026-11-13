import 'game_word_data.dart';

class CvcLessonWord {
  const CvcLessonWord(this.word, this.emoji,
      {this.picture, this.encouragement});
  final String word, emoji;
  final String? picture;
  final String? encouragement;
  String get vowel => word[1];
  String get slug => word.toLowerCase();
  String get wordAudio => 'cvc-word-$slug';
  String get praiseAudio => 'cvc-praise-$slug';
  String soundAudio(int index) => 'lesson-sound-${word[index]}';
  String get praise => encouragement == null
      ? '${word[0]}${word.substring(1).toLowerCase()}! Nice work! ${word.split('').join('-')} makes $slug!'
      : '$encouragement! ${word.split('').join('-')} makes $slug!';
  String? get imageAsset => picture ?? gameWordFor(word)?.frames.first;
}

// Original illustrated collection, also used by picture-based games.
// Keep this pool separate from the words-only CVC expansion.
const cvcIllustratedWords = [
  CvcLessonWord('CAT', '', picture: 'assets/images/cvc_blending/cat.webp'),
  CvcLessonWord('BAT', '', picture: 'assets/images/cvc_blending/bat.webp'),
  CvcLessonWord('HAT', '', picture: 'assets/images/cvc_blending/hat.webp'),
  CvcLessonWord('MAP', '', picture: 'assets/images/cvc_blending/map.webp'),
  CvcLessonWord('FAN', '', picture: 'assets/images/cvc_blending/fan.webp'),
  CvcLessonWord('BAG', '', picture: 'assets/images/cvc_blending/bag.webp'),
  CvcLessonWord('BED', '', picture: 'assets/images/cvc_blending/bed.webp'),
  CvcLessonWord('HEN', '', picture: 'assets/images/cvc_blending/hen.webp'),
  CvcLessonWord('PEN', '', picture: 'assets/images/cvc_blending/pen.webp'),
  CvcLessonWord('NET', '', picture: 'assets/images/cvc_blending/net.webp'),
  CvcLessonWord('RED', '', picture: 'assets/images/cvc_blending/red.webp'),
  CvcLessonWord('PIG', '', picture: 'assets/images/cvc_blending/pig.webp'),
  CvcLessonWord('PIN', '', picture: 'assets/images/cvc_blending/pin.webp'),
  CvcLessonWord('DOG', '', picture: 'assets/images/cvc_blending/dog.webp'),
  CvcLessonWord('POT', '', picture: 'assets/images/cvc_blending/pot.webp'),
  CvcLessonWord('RUG', '', picture: 'assets/images/cvc_blending/rug.webp'),
  CvcLessonWord('RUN', '', picture: 'assets/images/cvc_blending/run.webp'),
];

// Append new recordings without changing the original navigation order.
// Together these provide fourteen short-vowel words for each of A, E, I, O and U.
const cvcLessonWords = [
  ...cvcIllustratedWords,
  CvcLessonWord('MAT', '', encouragement: 'Nice work'),
  CvcLessonWord('RAT', '', encouragement: 'Great job'),
  CvcLessonWord('CAN', '', encouragement: 'Wonderful'),
  CvcLessonWord('JAM', '', encouragement: 'Well done'),
  CvcLessonWord('PET', '', encouragement: 'Excellent'),
  CvcLessonWord('WET', '', encouragement: 'Awesome'),
  CvcLessonWord('GET', '', encouragement: 'Fantastic'),
  CvcLessonWord('LET', '', encouragement: 'Amazing'),
  CvcLessonWord('SET', '', encouragement: 'Super work'),
  CvcLessonWord('BIN', '', encouragement: 'Good job'),
  CvcLessonWord('TIN', '', encouragement: 'Nice blending'),
  CvcLessonWord('FIN', '', encouragement: 'Great blending'),
  CvcLessonWord('WIN', '', encouragement: 'Nice work'),
  CvcLessonWord('BIG', '', encouragement: 'Great job'),
  CvcLessonWord('HIT', '', encouragement: 'Wonderful'),
  CvcLessonWord('FIT', '', encouragement: 'Well done'),
  CvcLessonWord('KID', '', encouragement: 'Excellent'),
  CvcLessonWord('HOT', '', encouragement: 'Awesome'),
  CvcLessonWord('DOT', '', encouragement: 'Fantastic'),
  CvcLessonWord('HOP', '', encouragement: 'Amazing'),
  CvcLessonWord('POP', '', encouragement: 'Super work'),
  CvcLessonWord('NOD', '', encouragement: 'Good job'),
  CvcLessonWord('GOT', '', encouragement: 'Nice blending'),
  CvcLessonWord('NOT', '', encouragement: 'Great blending'),
  CvcLessonWord('LOT', '', encouragement: 'Nice work'),
  CvcLessonWord('BUN', '', encouragement: 'Great job'),
  CvcLessonWord('TUB', '', encouragement: 'Wonderful'),
  CvcLessonWord('JUG', '', encouragement: 'Well done'),
  CvcLessonWord('GUM', '', encouragement: 'Excellent'),
  CvcLessonWord('PUP', '', encouragement: 'Awesome'),
  CvcLessonWord('CUB', '', encouragement: 'Fantastic'),
  CvcLessonWord('MUD', '', encouragement: 'Amazing'),
  CvcLessonWord('FUN', '', encouragement: 'Super work'),
  ...cvcAdditionalWords,
];

// Additional user-supplied word/praise recordings; the earlier order is retained.
const cvcAdditionalWords = [
  CvcLessonWord('DAD', '', encouragement: 'Nice work'),
  CvcLessonWord('PAD', '', encouragement: 'Great job'),
  CvcLessonWord('NAP', '', encouragement: 'Wonderful'),
  CvcLessonWord('TAP', '', encouragement: 'Well done'),
  CvcLessonWord('DEN', '', encouragement: 'Excellent'),
  CvcLessonWord('PEG', '', encouragement: 'Awesome'),
  CvcLessonWord('VET', '', encouragement: 'Fantastic'),
  CvcLessonWord('FED', '', encouragement: 'Amazing'),
  CvcLessonWord('LID', '', encouragement: 'Super work'),
  CvcLessonWord('ZIP', '', encouragement: 'Good job'),
  CvcLessonWord('DIP', '', encouragement: 'Nice blending'),
  CvcLessonWord('SIP', '', encouragement: 'Great blending'),
  CvcLessonWord('COT', '', encouragement: 'Nice work'),
  CvcLessonWord('FOG', '', encouragement: 'Great job'),
  CvcLessonWord('ROD', '', encouragement: 'Wonderful'),
  CvcLessonWord('JOB', '', encouragement: 'Well done'),
  CvcLessonWord('HUG', '', encouragement: 'Excellent'),
  CvcLessonWord('CUT', '', encouragement: 'Awesome'),
  CvcLessonWord('RUB', '', encouragement: 'Fantastic'),
  CvcLessonWord('TUG', '', encouragement: 'Amazing'),
];

String? cvcAudioAsset(String phrase) {
  for (final word in cvcLessonWords) {
    if (phrase == word.wordAudio) {
      return 'audio/cvc_lesson/word-${word.slug}.mp3';
    }
    if (phrase == word.praiseAudio) {
      return 'audio/cvc_lesson/praise-${word.slug}.mp3';
    }
  }
  return null;
}
