import 'game_word_data.dart';

class CvcLessonWord {
  const CvcLessonWord(this.word, this.emoji, {this.picture});
  final String word, emoji;
  final String? picture;
  String get vowel => word[1];
  String get slug => word.toLowerCase();
  String get wordAudio => 'cvc-word-$slug';
  String get praiseAudio => 'cvc-praise-$slug';
  String soundAudio(int index) => 'lesson-sound-${word[index]}';
  String get praise =>
      '${word[0]}${word.substring(1).toLowerCase()}! Nice work! ${word.split('').join('-')} makes $slug!';
  String? get imageAsset => picture ?? gameWordFor(word)?.frames.first;
}

// Words supplied in the user's new CVC recording and picture collection.
const cvcLessonWords = [
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
