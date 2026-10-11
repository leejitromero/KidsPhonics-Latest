import 'dart:math';
import '../data/cvc_lesson_data.dart';
import '../data/blending_lesson_data.dart';
import '../data/game_word_data.dart';
import '../data/lesson_example_data.dart';
import '../data/letter_data.dart';

enum AdventureSkill { matching, sound, spelling, soundPicture, hunt }

extension AdventureSkillLabel on AdventureSkill {
  String get label => const [
        'Big and little letters',
        'Letter sounds',
        'Missing letters',
        'Sounds in words',
        'Letter hunt'
      ][index];
}

class AdventureContent {
  const AdventureContent(this.letter, this.word, this.pictureWord,
      [this.position = 'beginning']);
  final String letter, word, pictureWord, position;
  String get maskedWord => word.toUpperCase().replaceFirst(letter, '_');
  String get soundKey => 'lesson-sound-$letter';
}

// Explicit sound scope, not inferred from the first written letter.
// C/G are hard, vowels short, Qu is /kw/, and X is final /ks/.
const adventureContents = [
  AdventureContent('A', 'Cat', 'Apple'),
  AdventureContent('B', 'Bag', 'Bag'),
  AdventureContent('C', 'Cat', 'Cow'),
  AdventureContent('D', 'Dog', 'Dog'),
  AdventureContent('E', 'Bed', 'Eggplant'),
  AdventureContent('F', 'Fan', 'Fan'),
  AdventureContent('G', 'Bag', 'Goat'),
  AdventureContent('H', 'Hen', 'Hat'),
  AdventureContent('I', 'Pin', 'Pig', 'middle'),
  AdventureContent('J', 'Jacket', 'Jar'),
  AdventureContent('K', 'Book', 'Key'),
  AdventureContent('L', 'Lip', 'Lamb'),
  AdventureContent('M', 'Mop', 'Monkey'),
  AdventureContent('N', 'Pen', 'Nest'),
  AdventureContent('O', 'Pot', 'Octopus'),
  AdventureContent('P', 'Pig', 'Pen'),
  AdventureContent('Q', 'Queen', 'Quack'),
  AdventureContent('R', 'Rug', 'Rabbit'),
  AdventureContent('S', 'Sun', 'Spoon'),
  AdventureContent('T', 'Cat', 'Train'),
  AdventureContent('U', 'Sun', 'Tub', 'middle'),
  AdventureContent('V', 'Van', 'Vase'),
  AdventureContent('W', 'Wig', 'Web'),
  AdventureContent('X', 'Box', 'Box', 'end'),
  AdventureContent('Y', 'Yarn', 'Yogurt'),
  AdventureContent('Z', 'Zebra', 'Zebra'),
];

String adventureWordKey(String word) {
  for (final item in cvcLessonWords) {
    if (item.word.toLowerCase() == word.toLowerCase()) return item.wordAudio;
  }
  for (final item in blendingLessonWords) {
    if (item.word.toLowerCase() == word.toLowerCase()) return item.wordAudio;
  }
  final lesson = lessonExamples.where((e) => e.word == word);
  return gameWordFor(word) == null && lesson.isNotEmpty
      ? lesson.first.wordAudioKey
      : word;
}

String adventurePicture(String word) {
  for (final item in [...cvcLessonWords, ...blendingLessonWords]) {
    if (item.word.toLowerCase() == word.toLowerCase() &&
        item.imageAsset != null) {
      return item.imageAsset!;
    }
  }
  return gameWordFor(word)?.frames.first ??
      lessonExamples.firstWhere((e) => e.word == word).frames.first;
}

class AdventureSession {
  AdventureSession(String letter, {Random? random})
      : content = adventureContents.singleWhere((c) => c.letter == letter),
        id =
            '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 30)}' {
    final rng = random ?? Random();
    List<String> options(String answer, Iterable<String> pool) {
      final other = pool.where((v) => v != answer).toSet().toList()
        ..shuffle(rng);
      return [answer, ...other.take(3)]..shuffle(rng);
    }

    final letters = adventureContents.map((c) => c.letter).toList();
    matchOptions =
        options(letter.toLowerCase(), letters.map((s) => s.toLowerCase()));
    soundOptions = options(letter, soundChoices(letter, letters));
    spellingOptions = options(letter, letters);
    final picturePool = switch (letter) {
      'I' => ['Cat', 'Dog', 'Sun'],
      'U' => ['Cat', 'Pig', 'Dog'],
      'X' => ['Sun', 'Cat', 'Pig'],
      _ => adventureContents
          .where((c) =>
              c.position == 'beginning' &&
              c.letter != letter &&
              !({'C', 'K', 'Q'}.contains(letter) &&
                  {'C', 'K', 'Q'}.contains(c.letter)))
          .map((c) => c.pictureWord)
          .toList(),
    };
    pictureOptions = options(content.pictureWord, picturePool);
    final distractors = letters.where((l) => l != letter).toList()
      ..shuffle(rng);
    huntLetters = [
      letter,
      letter.toLowerCase(),
      letter,
      letter.toLowerCase(),
      ...distractors
          .take(8)
          .toList()
          .asMap()
          .entries
          .map((e) => e.key.isEven ? e.value : e.value.toLowerCase())
    ]..shuffle(rng);
  }
  final AdventureContent content;
  final String id;
  late final List<String> matchOptions,
      soundOptions,
      spellingOptions,
      pictureOptions,
      huntLetters;
  final List<bool?> firstAnswers = List.filled(5, null);
  final Set<int> hunted = {};
  bool huntMistake = false;
  int get score => firstAnswers.where((v) => v == true).length;
  bool get complete => firstAnswers.every((v) => v != null);
  bool submit(AdventureSkill skill, bool correct) {
    if (firstAnswers[skill.index] != null) return false;
    firstAnswers[skill.index] = correct;
    return true;
  }

  bool hunt(int index) {
    if (firstAnswers[4] != null || hunted.contains(index)) return false;
    if (huntLetters[index].toUpperCase() != content.letter) {
      huntMistake = true;
      return false;
    }
    hunted.add(index);
    if (hunted.length == 4) submit(AdventureSkill.hunt, !huntMistake);
    return true;
  }
}

class AdventurePolicy {
  static const minimumScore = 4; // Configurable after educator validation.
  static bool passes(List<bool> answers) =>
      answers.length == 5 &&
      answers.where((v) => v).length >= minimumScore &&
      answers[1] &&
      answers[3];
}

class AdventureProgress {
  const AdventureProgress(
      {this.completed = 0,
      this.best = 0,
      this.mastered = false,
      this.masteredAt,
      this.lastAnswers = const [],
      this.sessionId = ''});
  final int completed, best;
  final bool mastered;
  final String? masteredAt;
  final List<bool> lastAnswers;
  final String sessionId;
  int get lastScore => lastAnswers.where((v) => v).length;
  String get status => mastered
      ? 'Mastered'
      : completed > 0
          ? 'Practicing'
          : 'Not Started';
  Map<String, Object> toJson() => {
        'version': 1,
        'completed': completed,
        'best': best,
        'mastered': mastered,
        'masteredAt': masteredAt ?? '',
        'lastAnswers': lastAnswers,
        'sessionId': sessionId
      };
  factory AdventureProgress.fromJson(Map value) {
    final answers = value['lastAnswers'];
    if (value['version'] != 1 ||
        answers is! List ||
        answers.length != 5 ||
        answers.any((v) => v is! bool)) {
      return const AdventureProgress();
    }
    return AdventureProgress(
        completed: value['completed'] is int
            ? (value['completed'] as int).clamp(0, 1000000)
            : 0,
        best: value['best'] is int ? (value['best'] as int).clamp(0, 5) : 0,
        mastered: value['mastered'] == true,
        masteredAt: value['masteredAt'] is String &&
                DateTime.tryParse(value['masteredAt'] as String) != null
            ? value['masteredAt'] as String
            : null,
        lastAnswers: List<bool>.unmodifiable(answers.cast<bool>()),
        sessionId:
            value['sessionId'] is String ? value['sessionId'] as String : '');
  }
}
