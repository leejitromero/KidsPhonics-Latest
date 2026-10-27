class GameInstructionScript {
  const GameInstructionScript(this.key, this.text, this.asset);
  final String key, text, asset;
}

/// Display instructions and the supplied game recording paths.
const gameInstructionScripts = <String, GameInstructionScript>{
  'Flappy Letters': GameInstructionScript(
      'flappy-letters',
      'Tap to fly through the gaps and avoid the pipes!',
      'audio/game_instructions/flappy_letters.mp3'),
  'Sound Match': GameInstructionScript(
      'sound-match',
      'Tap Hear Sound, then choose the matching letter!',
      'audio/game_instructions/sound_match.mp3'),
  'Memory Flip': GameInstructionScript(
      'memory-flip',
      'Tap two cards to find matching pictures!',
      'audio/game_instructions/memory_flip.mp3'),
  'Phonics Quiz': GameInstructionScript(
      'phonics-quiz',
      'Listen to the word, choose your answer, then tap Check Answer!',
      'audio/game_instructions/phonics_quiz.mp3'),
  'Word Builder': GameInstructionScript(
      'word-builder',
      'Tap the missing letters to complete the word!',
      'audio/game_instructions/world_builder.mp3'),
  'Speak & Recognize': GameInstructionScript(
      'speak-recognize',
      'Tap Start Listening and say the word clearly!',
      'audio/game_instructions/speak_recognize.mp3'),
  'Alphabet Order': GameInstructionScript(
      'alphabet-order',
      'Tap the letters in order, starting with A!',
      'audio/game_instructions/alphabet_order.mp3'),
  'Missing Vowel': GameInstructionScript(
      'missing-vowel',
      'Tap the missing vowel to complete the word!',
      'audio/game_instructions/missing_vowel.mp3'),
  'Picture Match': GameInstructionScript(
      'picture-match',
      'Listen to the word and tap the matching picture!',
      'audio/game_instructions/picture_match.mp3'),
  'Rumbled Words': GameInstructionScript(
      'rumbled-words',
      'Tap a letter, drag it into place, then tap Check Word!',
      'audio/game_instructions/rumbled_word.mp3'),
  'Rhyming Words': GameInstructionScript(
      'rhyming-words',
      'Find three words that rhyme with the word you hear!',
      'audio/rhyming_jar/intro.mp3'),
};

String? gameInstructionAsset(String phrase) {
  for (final script in gameInstructionScripts.values) {
    if (phrase == 'game-instruction-${script.key}') return script.asset;
  }
  return null;
}
