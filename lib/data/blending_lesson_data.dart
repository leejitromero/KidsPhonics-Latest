import 'cvc_lesson_data.dart';

class BlendingLessonWord extends CvcLessonWord {
  const BlendingLessonWord(super.word, super.emoji, {super.picture});
  @override
  String get wordAudio => 'blend-word-$slug';
  @override
  String get praiseAudio => 'blend-praise-$slug';
  @override
  String get praise => 'Great job! ${word.split('').join('-')} makes $slug!';
}

// Words supplied in the user's new Blending recording and picture collection.
const blendingLessonWords = [
  BlendingLessonWord('SUN', '', picture: 'assets/images/cvc_blending/sun.webp'),
  BlendingLessonWord('CUP', '', picture: 'assets/images/cvc_blending/cup.webp'),
  BlendingLessonWord('BUS', '', picture: 'assets/images/cvc_blending/bus.webp'),
  BlendingLessonWord('LOG', '', picture: 'assets/images/cvc_blending/log.webp'),
  BlendingLessonWord('CAP', '', picture: 'assets/images/cvc_blending/cap.webp'),
  BlendingLessonWord('VAN', '', picture: 'assets/images/cvc_blending/van.webp'),
  BlendingLessonWord('PAN', '', picture: 'assets/images/cvc_blending/pan.webp'),
  BlendingLessonWord('TEN', '', picture: 'assets/images/cvc_blending/ten.webp'),
  BlendingLessonWord('LEG', '', picture: 'assets/images/cvc_blending/leg.webp'),
  BlendingLessonWord('JET', '', picture: 'assets/images/cvc_blending/jet.webp'),
  BlendingLessonWord('WEB', '', picture: 'assets/images/cvc_blending/web.webp'),
  BlendingLessonWord('LIP', '', picture: 'assets/images/cvc_blending/lip.webp'),
  BlendingLessonWord('DIG', '', picture: 'assets/images/cvc_blending/dig.webp'),
  BlendingLessonWord('BOX', '', picture: 'assets/images/cvc_blending/box.webp'),
  BlendingLessonWord('MOP', '', picture: 'assets/images/cvc_blending/mop.webp'),
  BlendingLessonWord('MUG', '', picture: 'assets/images/cvc_blending/mug.webp'),
  BlendingLessonWord('NUT', '', picture: 'assets/images/cvc_blending/nut.webp'),
  BlendingLessonWord('HUT', '', picture: 'assets/images/cvc_blending/hut.webp'),
  BlendingLessonWord('BUG', '', picture: 'assets/images/cvc_blending/bug.webp'),
  BlendingLessonWord('SIT', '', picture: 'assets/images/cvc_blending/sit.webp'),
  BlendingLessonWord('TOP', '', picture: 'assets/images/cvc_blending/top.webp'),
  BlendingLessonWord('WIG', '', picture: 'assets/images/cvc_blending/wig.webp'),
];

String? blendingAudioAsset(String phrase) {
  if (phrase == 'blend-intro') return 'audio/blending_lesson/intro.mp3';
  if (phrase == 'blend-try-another') {
    return 'audio/blending_lesson/try-another.mp3';
  }
  for (final word in blendingLessonWords) {
    if (phrase == word.wordAudio) {
      return 'audio/blending_lesson/word-${word.slug}.mp3';
    }
    if (phrase == word.praiseAudio) {
      return 'audio/blending_lesson/praise-${word.slug}.mp3';
    }
  }
  return null;
}
