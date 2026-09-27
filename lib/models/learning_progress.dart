enum LearningStatus { notStarted, viewed, practiced, mastered }

class LetterProgress {
  final String letter;
  final int viewCount, attempts, correctAnswers, completedAssessments;
  final int bestAssessmentScore;
  final bool mastered;
  final String? masteredAt;

  const LetterProgress(
      {required this.letter,
      this.viewCount = 0,
      this.attempts = 0,
      this.correctAnswers = 0,
      this.completedAssessments = 0,
      this.bestAssessmentScore = 0,
      this.mastered = false,
      this.masteredAt});

  double? get accuracy =>
      attempts <= 0 ? null : (correctAnswers / attempts).clamp(0.0, 1.0);
  LearningStatus get status => mastered
      ? LearningStatus.mastered
      : attempts > 0
          ? LearningStatus.practiced
          : viewCount > 0
              ? LearningStatus.viewed
              : LearningStatus.notStarted;

  LetterProgress copyWith(
          {int? viewCount,
          int? attempts,
          int? correctAnswers,
          int? completedAssessments,
          int? bestAssessmentScore,
          bool? mastered,
          String? masteredAt}) =>
      LetterProgress(
          letter: letter,
          viewCount: viewCount ?? this.viewCount,
          attempts: attempts ?? this.attempts,
          correctAnswers: correctAnswers ?? this.correctAnswers,
          completedAssessments:
              completedAssessments ?? this.completedAssessments,
          bestAssessmentScore: bestAssessmentScore ?? this.bestAssessmentScore,
          mastered: mastered ?? this.mastered,
          masteredAt: masteredAt ?? this.masteredAt);

  Map<String, dynamic> toJson() => {
        'letter': letter,
        'viewCount': viewCount,
        'attempts': attempts,
        'correctAnswers': correctAnswers,
        'completedAssessments': completedAssessments,
        'bestAssessmentScore': bestAssessmentScore,
        'mastered': mastered,
        'masteredAt': masteredAt
      };
  factory LetterProgress.fromJson(Map<String, dynamic> json) {
    final attempts = safeCount(json['attempts']);
    final date = json['masteredAt'];
    return LetterProgress(
        letter: json['letter'] is String ? json['letter'] as String : '',
        viewCount: safeCount(json['viewCount']),
        attempts: attempts,
        correctAnswers: safeCount(json['correctAnswers']).clamp(0, attempts),
        completedAssessments: safeCount(json['completedAssessments']),
        bestAssessmentScore: safeCount(json['bestAssessmentScore']).clamp(0, 5),
        mastered: json['mastered'] == true,
        masteredAt:
            date is String && DateTime.tryParse(date) != null ? date : null);
  }
}

class DailyActivity {
  final int questionsAnswered, correctAnswers, activitiesCompleted;
  const DailyActivity(
      {this.questionsAnswered = 0,
      this.correctAnswers = 0,
      this.activitiesCompleted = 0});
  Map<String, dynamic> toJson() => {
        'questionsAnswered': questionsAnswered,
        'correctAnswers': correctAnswers,
        'activitiesCompleted': activitiesCompleted
      };
  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    final attempts = safeCount(json['questionsAnswered']);
    return DailyActivity(
        questionsAnswered: attempts,
        correctAnswers: safeCount(json['correctAnswers']).clamp(0, attempts),
        activitiesCompleted: safeCount(json['activitiesCompleted']));
  }
}

/// Ignore wrong types and bound damaged stored counters before using them in UI.
int safeCount(Object? value) => value is int ? value.clamp(0, 0x7fffffff) : 0;

String? validLocalDate(Object? value) {
  if (value is! String) return null;
  final parsed = DateTime.tryParse(value);
  return parsed != null && localDateKey(parsed) == value ? value : null;
}

String localDateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

// UTC calendar ordinals avoid daylight-saving differences between local midnights.
int calendarDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    86400000;
