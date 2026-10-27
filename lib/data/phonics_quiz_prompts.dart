enum QuizSoundPosition {
  beginning,
  middle,
  end;

  String get question => 'What sound do you hear '
      '${this == beginning ? 'at the beginning' : this == middle ? 'in the middle' : 'at the end'}?';
  String get audioKey => 'quiz-question-$name';
  String get audioAsset => phonicsQuizPromptRecordings[audioKey]!;
  int get wordIndex => switch (this) { beginning => 0, middle => 1, end => 2 };
}

const phonicsQuizPromptRecordings = {
  'quiz-question-beginning': 'audio/game_instructions/quiz_beginning.mp3',
  'quiz-question-middle': 'audio/game_instructions/quiz_middle.mp3',
  'quiz-question-end': 'audio/game_instructions/quiz_end.mp3',
};

String? phonicsQuizPromptAsset(String phrase) {
  return phonicsQuizPromptRecordings[phrase];
}
