import 'learning_progress.dart';

class LearningDay {
  const LearningDay(this.date, this.activity);
  final DateTime date;
  final DailyActivity activity;
  double? get accuracy => activity.questionsAnswered == 0
      ? null
      : activity.correctAnswers / activity.questionsAnswered;
}

/// A single calendar window shared by the graph, totals and recent history.
class WeeklyLearningSummary {
  WeeklyLearningSummary(DateTime today, Map<String, DailyActivity> activity)
      : days = List.unmodifiable(List.generate(7, (i) {
          final date = DateTime(today.year, today.month, today.day - 6 + i);
          return LearningDay(
              date, activity[localDateKey(date)] ?? const DailyActivity());
        }));
  final List<LearningDay> days;
  int get questionsAnswered =>
      days.fold(0, (n, d) => n + d.activity.questionsAnswered);
  int get correctAnswers =>
      days.fold(0, (n, d) => n + d.activity.correctAnswers);
  int get activitiesCompleted =>
      days.fold(0, (n, d) => n + d.activity.activitiesCompleted);
  double? get accuracy =>
      questionsAnswered == 0 ? null : correctAnswers / questionsAnswered;
  int get maximumQuestions => days.fold(
      0,
      (n, d) =>
          d.activity.questionsAnswered > n ? d.activity.questionsAnswered : n);
  bool get hasActivity => questionsAnswered > 0 || activitiesCompleted > 0;
}

class LearningAchievement {
  const LearningAchievement(this.title, this.description, this.unlocked);
  final String title, description;
  final bool unlocked;
}
