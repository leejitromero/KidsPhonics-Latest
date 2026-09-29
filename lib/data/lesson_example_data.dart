import 'game_word_data.dart';

/// Supplied artwork and audio used throughout Lessons and letter practice.
/// Matching words reuse the latest Game Zone artwork and recordings.
class LessonExample {
  const LessonExample(this.letter, this.slug, this.word);
  final String letter, slug, word;
  String get example => '$letter is for $word.';
  String get letterAudioKey => 'lesson-letter-$letter';
  String get wordAudioKey => 'lesson-word-$letter';
  String get soundAudioKey => 'lesson-sound-$letter';
  List<String> get frames =>
      gameWordFor(word)?.frames ??
      [
        for (final suffix in ['', '1', '2'])
          'assets/images/lesson_frames/${slug}_$letter$suffix.png',
      ];

  String? get soundNote => switch (letter) {
        'G' =>
          'Giraffe starts with soft G, like J in jam. The SOUND button plays hard G, as in goat.',
        'X' =>
          'Xylophone starts with /z/. The SOUND button plays /ks/, as at the end of fox.',
        'O' => 'Orange names our picture. For short O, think of octopus.',
        _ => null,
      };
}

const lessonExamples = [
  LessonExample('A', 'ant', 'Ant'),
  LessonExample('B', 'ball', 'Ball'),
  LessonExample('C', 'cat', 'Cat'),
  LessonExample('D', 'drum', 'Drum'),
  LessonExample('E', 'egg', 'Egg'),
  LessonExample('F', 'fish', 'Fish'),
  LessonExample('G', 'giraffe', 'Giraffe'),
  LessonExample('H', 'hat', 'Hat'),
  LessonExample('I', 'igloo', 'Igloo'),
  LessonExample('J', 'juice', 'Juice'),
  LessonExample('K', 'kite', 'Kite'),
  LessonExample('L', 'lion', 'Lion'),
  LessonExample('M', 'monkey', 'Monkey'),
  LessonExample('N', 'nest', 'Nest'),
  LessonExample('O', 'orange', 'Orange'),
  LessonExample('P', 'penguin', 'Penguin'),
  LessonExample('Q', 'queen', 'Queen'),
  LessonExample('R', 'rabbit', 'Rabbit'),
  LessonExample('S', 'sun', 'Sun'),
  LessonExample('T', 'turtle', 'Turtle'),
  LessonExample('U', 'umbrella', 'Umbrella'),
  LessonExample('V', 'van', 'Van'),
  LessonExample('W', 'whale', 'Whale'),
  LessonExample('X', 'xylophone', 'Xylophone'),
  LessonExample('Y', 'yoyo', 'Yo-yo'),
  LessonExample('Z', 'zebra', 'Zebra'),
];

/// Quick Check vocabulary with existing pictures and recordings.
final practiceExamples = <LessonExample>[
  ...lessonExamples,
  for (final word in gameWords)
    if (!lessonExamples.any((example) => example.word == word.word))
      LessonExample(word.letter, word.slug, word.word),
];
