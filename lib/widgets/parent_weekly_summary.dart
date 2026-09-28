import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/learning_progress.dart';
import '../providers/app_provider.dart';
import 'learning_progress_widgets.dart';

class ParentWeeklySummary extends StatelessWidget {
  const ParentWeeklySummary({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final week = p.getWeeklySummary();
    final start = calendarDay(week.days.first.date);
    final end = calendarDay(week.days.last.date);
    final mastered = p.allLetterProgress
        .where((letter) {
          final date = DateTime.tryParse(letter.masteredAt ?? '');
          if (!letter.mastered || date == null) return false;
          final day = calendarDay(date.toLocal());
          return day >= start && day <= end;
        })
        .map((letter) => letter.letter)
        .toList();
    final activeDays = week.days
        .where((day) =>
            day.activity.questionsAnswered > 0 ||
            day.activity.activitiesCompleted > 0)
        .length;
    final dates = MaterialLocalizations.of(context);
    final next = p.recommendedNextPractice;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
          '${dates.formatMediumDate(week.days.first.date)} – ${dates.formatMediumDate(week.days.last.date)}',
          style: const TextStyle(color: Colors.white70, fontSize: 14)),
      const SizedBox(height: 14),
      Text(
          activeDays == 0 && mastered.isEmpty
              ? 'A fresh week of little discoveries awaits.'
              : '$activeDays of 7 days with learning activity',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 10, children: [
        _stat(
            Icons.auto_awesome_rounded, '${mastered.length}', 'Newly mastered'),
        _stat(Icons.quiz_rounded, '${week.questionsAnswered}',
            'Questions answered'),
        _stat(Icons.check_circle_outline, '${week.activitiesCompleted}',
            'Activities completed'),
        _stat(
            Icons.insights_rounded,
            week.accuracy == null ? 'Not yet' : accuracyLabel(week.accuracy),
            'Answer accuracy'),
      ]),
      const SizedBox(height: 14),
      Text(
          mastered.isEmpty
              ? 'No new letters mastered in this period. Every practice helps.'
              : 'New letters mastered: ${mastered.join(', ')}',
          style: const TextStyle(
              color: Color(0xFFDDF3B8),
              fontSize: 16,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFF34594B),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Try together next',
              style: TextStyle(
                  color: Color(0xFFFFDF9D),
                  fontWeight: FontWeight.w800,
                  fontSize: 17)),
          const SizedBox(height: 6),
          Text(
              next == null
                  ? 'All 26 letters are mastered! Revisit a favorite lesson.'
                  : next.status == LearningStatus.practiced
                      ? 'Practice letter ${next.letter} with a short Quick Check.'
                      : next.status == LearningStatus.viewed
                          ? 'Try a Quick Check for letter ${next.letter}.'
                          : 'Explore letter ${next.letter} in Letter Sounds.',
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ]),
      ),
      const SizedBox(height: 10),
      const Text(
          'Activity totals cover the last 7 days. The next step uses overall letter progress.',
          style: TextStyle(color: Colors.white70, fontSize: 13)),
    ]);
  }

  Widget _stat(IconData icon, String value, String label) => Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFF1C3D34),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: const Color(0xFFDDF3B8)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.white70)),
        ]),
      );
}
