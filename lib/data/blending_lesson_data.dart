import 'cvc_lesson_data.dart';

class BlendingLessonWord extends CvcLessonWord {
  const BlendingLessonWord(super.word, super.emoji, {super.picture});
  @override
  String get wordAudio => 'blend-word-$slug';
  @override
  String get praiseAudio => 'blend-praise-$slug';
  @override
  String get praise => 'Great job! ${word.split('').join('-')} makes $word!';
}

// DOG introduces the interaction, followed by the examples and vowel table.
const blendingLessonWords = [
  BlendingLessonWord('DOG', '🐶'),
  BlendingLessonWord('CAT', '🐱',
      picture: 'assets/images/lesson_frames/cat_C.png'),
  BlendingLessonWord('SUN', '☀️',
      picture: 'assets/images/lesson_frames/sun_S.png'),
  BlendingLessonWord('PIG', '🐷'),
  BlendingLessonWord('HAT', '🎩',
      picture: 'assets/images/lesson_frames/hat_H.png'),
  BlendingLessonWord('BED', '🛏️'),
  BlendingLessonWord('PEN', '🖊️'),
  BlendingLessonWord('FOX', '🦊'),
  BlendingLessonWord('CUP', '🥤'),
  BlendingLessonWord('MAP', '🗺️'),
  BlendingLessonWord('BUS', '🚌'),
  BlendingLessonWord('LOG', '🪵'),
  BlendingLessonWord('HEN', '🐔'),
  BlendingLessonWord('FIN', ''),
  BlendingLessonWord('RUG', ''),
  BlendingLessonWord('CAP', '🧢'),
  BlendingLessonWord('BAG', '🎒'),
  BlendingLessonWord('VAN', '🚐',
      picture: 'assets/images/lesson_frames/van_V.png'),
  BlendingLessonWord('PAN', '🍳'),
  BlendingLessonWord('RAM', '🐏'),
  BlendingLessonWord('RED', '🔴'),
  BlendingLessonWord('TEN', '🔟'),
  BlendingLessonWord('LEG', '🦵'),
  BlendingLessonWord('JET', '✈️'),
  BlendingLessonWord('WEB', '🕸️'),
  BlendingLessonWord('BIG', ''),
  BlendingLessonWord('LIP', '👄',
      picture: 'assets/images/game_words/lips-0.png'),
  BlendingLessonWord('DIG', ''),
  BlendingLessonWord('KID', '🧒'),
  BlendingLessonWord('RIB', ''),
  BlendingLessonWord('BOX', '📦'),
  BlendingLessonWord('MOP', ''),
  BlendingLessonWord('POT', '🍲'),
  BlendingLessonWord('HOT', '🔥'),
  BlendingLessonWord('COT', '🛏️'),
  BlendingLessonWord('MUG', '☕'),
  BlendingLessonWord('HUG', ''),
  BlendingLessonWord('NUT', '🥜'),
  BlendingLessonWord('HUT', '🛖'),
  BlendingLessonWord('PUP', '🐶'),
];

String? blendingAudioAsset(String phrase) {
  if (phrase == 'blend-intro') return 'audio/blending_lesson/intro.wav';
  if (phrase == 'blend-try-another') {
    return 'audio/blending_lesson/try-another.wav';
  }
  for (final word in blendingLessonWords) {
    if (phrase == word.wordAudio) {
      final existing = cvcLessonWords.any((item) => item.word == word.word);
      return 'audio/${existing ? 'cvc_lesson' : 'blending_lesson'}/word-${word.slug}.wav';
    }
    if (phrase == word.praiseAudio) {
      return 'audio/blending_lesson/praise-${word.slug}.wav';
    }
  }
  return null;
}
