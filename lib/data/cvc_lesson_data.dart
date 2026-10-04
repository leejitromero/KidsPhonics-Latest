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
      '$word! Great job! ${word.split('').join('-')} makes $word!';
  String? get imageAsset => picture ?? gameWordFor(word)?.frames.first;
}

// Column groups from the user's CVC WORDS LESSON SCENARIO.docx.
const cvcLessonWords = [
  CvcLessonWord('CAT', '🐱', picture: 'assets/images/lesson_frames/cat_C.png'),
  CvcLessonWord('BAT', '🦇'),
  CvcLessonWord('HAT', '🎩', picture: 'assets/images/lesson_frames/hat_H.png'),
  CvcLessonWord('MAP', '🗺️'),
  CvcLessonWord('FAN', '🪭'),
  CvcLessonWord('BED', '🛏️'),
  CvcLessonWord('HEN', '🐔'),
  CvcLessonWord('PEN', '🖊️'),
  CvcLessonWord('NET', '🥅'),
  CvcLessonWord('PET', '🐶'),
  CvcLessonWord('PIG', '🐷'),
  CvcLessonWord('WIG', ''),
  CvcLessonWord('FIN', ''),
  CvcLessonWord('PIN', '📌'),
  CvcLessonWord('SIT', ''),
  CvcLessonWord('DOG', '🐶'),
  CvcLessonWord('LOG', '🪵'),
  CvcLessonWord('FOX', '🦊'),
  CvcLessonWord('TOP', ''),
  CvcLessonWord('HOP', '🐇'),
  CvcLessonWord('SUN', '☀️', picture: 'assets/images/lesson_frames/sun_S.png'),
  CvcLessonWord('BUS', '🚌'),
  CvcLessonWord('CUP', '🥤'),
  CvcLessonWord('BUG', '🐞'),
  CvcLessonWord('RUN', '🏃'),
];

String? cvcAudioAsset(String phrase) {
  if (phrase == 'cvc-intro') return 'audio/cvc_lesson/intro.wav';
  for (final word in cvcLessonWords) {
    if (phrase == word.wordAudio) {
      return 'audio/cvc_lesson/word-${word.slug}.wav';
    }
    if (phrase == word.praiseAudio) {
      return 'audio/cvc_lesson/praise-${word.slug}.wav';
    }
  }
  return null;
}
