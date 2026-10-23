/// Display the introduction before returning to the lesson's short action hint.
const lessonInstructionScripts = <String, List<String>>{
  'lesson-instruction-alphabet-pictures': [
    'Look at the letter and picture. Listen and say it with me!',
    'Tap Next to see another letter. Tap Sound to listen again!',
  ],
  'lesson-instruction-recognition': [
    'Tap Sound and say the letter name.',
    'Tap Next for another letter!',
  ],
  'lesson-instruction-sounds': [
    'Tap Sound, listen, and repeat the sound.',
    'Tap Next for another letter!',
  ],
  'lesson-instruction-vowels': [
    'Choose a vowel, then tap Sound.',
    'Say its sound, then tap Next!',
  ],
  'cvc-intro': [
    'Tap Hear Again and blend the sounds.',
    'Say the word, then tap Next!',
  ],
  'blend-intro': [
    'Drag the letters to build the word.',
    'Blend the sounds, then tap Next!',
  ],
};

const lessonInstructionRecordings = <String, List<String>>{
  'lesson-instruction-alphabet-pictures': [
    'alphabet_pictures_1.mp3',
    'alphabet_picture_2.mp3',
  ],
  'lesson-instruction-recognition': [
    'letter_recognition_1.mp3',
    'letter_recognition_2.mp3',
  ],
  'lesson-instruction-sounds': ['letter_sounds_1.mp3', 'letter_sounds_2.mp3'],
  'lesson-instruction-vowels': ['short_vowel_1.mp3', 'short_vowel_2.mp3'],
  'cvc-intro': ['cvc_word_1.mp3', 'cvc_word_2.mp3'],
  'blend-intro': ['blending_sounds_1.mp3', 'blending_sounds_2.mp3'],
};

const lessonInstructionDefaults = <String, String>{
  'lesson-instruction-alphabet-pictures':
      'See the letter and picture. Tap Next to listen.',
  'lesson-instruction-recognition': 'Tap Sound to hear the letter name.',
  'lesson-instruction-sounds': 'Tap Sound to hear the letter sound.',
  'lesson-instruction-vowels': 'Choose a vowel, then tap Sound.',
  'cvc-intro': 'Tap Hear Again to blend the word.',
  'blend-intro': 'Drag the letters to build the word.',
};

String? lessonInstructionAsset(String phrase) {
  for (final entry in lessonInstructionRecordings.entries) {
    for (var i = 0; i < entry.value.length; i++) {
      if (phrase == '${entry.key}-${i + 1}') {
        return 'audio/lesson_instructions/${entry.value[i]}';
      }
    }
  }
  return null;
}

enum LessonIntroductionStatus { pending, second, finished, interrupted }
