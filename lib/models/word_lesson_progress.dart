import '../data/blending_lesson_data.dart';
import '../data/cvc_lesson_data.dart';

enum WordLesson {
  cvc,
  blending;

  List<String> get words => switch (this) {
        cvc => cvcLessonWords.map((word) => word.word).toList(),
        blending => blendingLessonWords.map((word) => word.word).toList(),
      };
}

/// Guided practice completion is separate from assessed letter mastery.
class WordLessonProgress {
  const WordLessonProgress({this.started = false, this.completed = const {}});
  final bool started;
  final Set<String> completed;

  Map<String, dynamic> toJson() => {
        'started': started,
        'completed': completed.toList()..sort(),
      };

  factory WordLessonProgress.fromJson(Object? value, WordLesson lesson) {
    if (value is! Map) return const WordLessonProgress();
    final items = value['completed'];
    final completed = items is List
        ? items.whereType<String>().where(lesson.words.contains).toSet()
        : <String>{};
    return WordLessonProgress(
        started: value['started'] == true || completed.isNotEmpty,
        completed: Set.unmodifiable(completed));
  }
}
