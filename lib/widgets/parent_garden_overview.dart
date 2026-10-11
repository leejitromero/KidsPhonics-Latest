import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/learning_progress.dart';
import '../providers/app_provider.dart';
import 'button_sound.dart';
import 'learning_progress_widgets.dart';
import '../screens/progress_screen.dart';
import 'learner_widgets.dart';
import 'quick_check_recommendation.dart';

const _forestInk = Color(0xFF123D32);

/// The supplied Parent design, populated exclusively from saved learning data.
class ParentGardenOverview extends StatelessWidget {
  const ParentGardenOverview({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final week = p.getWeeklySummary();
    final start = calendarDay(week.days.first.date);
    final end = calendarDay(week.days.last.date);
    final newlyMastered = p.quickCheckLetters.where((letter) {
      final date = DateTime.tryParse(letter.masteredAt ?? '');
      if (!letter.mastered || date == null) return false;
      final day = calendarDay(date.toLocal());
      return day >= start && day <= end;
    }).length;
    final activeDays = week.days
        .where((day) =>
            day.activity.questionsAnswered > 0 ||
            day.activity.activitiesCompleted > 0 ||
            day.activity.speechAttempts > 0)
        .length;
    final dates = MaterialLocalizations.of(context);
    return DefaultTextStyle.merge(
        style: const TextStyle(color: _forestInk, fontFamily: 'Nunito'),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          GardenCard(
              title: 'This Week at a Glance',
              icon: Icons.calendar_month_rounded,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                        '${dates.formatMediumDate(week.days.first.date)} – ${dates.formatMediumDate(week.days.last.date)}',
                        style: const TextStyle(
                            color: Color(0xFF62736C), fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('$activeDays of 7 days with learning activity',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 8),
                    _Stats(items: [
                      (
                        Icons.auto_awesome_rounded,
                        '$newlyMastered',
                        'Newly mastered',
                        const Color(0xFF8148D8)
                      ),
                      (
                        Icons.quiz_rounded,
                        '${week.questionsAnswered}',
                        'Questions answered',
                        const Color(0xFF0072CC)
                      ),
                      (
                        Icons.check_circle_rounded,
                        '${week.activitiesCompleted}',
                        'Activities completed',
                        const Color(0xFF159852)
                      ),
                      (
                        Icons.star_rounded,
                        week.accuracy == null
                            ? 'Not yet'
                            : accuracyLabel(week.accuracy),
                        'Answer accuracy',
                        const Color(0xFFD26B00)
                      ),
                    ]),
                  ])),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: QuickCheckRecommendation()),
          TextButton.icon(
              key: const ValueKey('parent-open-progress'),
              onPressed: withButtonSound(() => LearnerNavigation.open(
                  context, const ProgressScreen(),
                  cloudTransition: true, endParentSession: true)),
              icon: const Icon(Icons.insights_rounded),
              label: const Text('View detailed progress')),
        ]));
  }
}

class GardenCard extends StatelessWidget {
  const GardenCard({super.key, this.title, this.icon, required this.child});
  final String? title;
  final IconData? icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFF6FFDF), Color(0xFFFDFCF0)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE1F7A8), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33304F21), offset: Offset(0, 4), blurRadius: 8)
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (title != null) ...[
          Row(children: [
            Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: const Color(0xFFCEEBB5),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: _forestInk, size: 20)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(title!,
                    style: const TextStyle(
                        color: _forestInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)))
          ]),
          const SizedBox(height: 8),
        ],
        child,
      ]));
}

class _Stats extends StatelessWidget {
  const _Stats({required this.items});
  final List<(IconData, String, String, Color)> items;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final columns = box.maxWidth >= 440 * scale ? 4 : 2;
        final width = (box.maxWidth - (columns - 1) * 6) / columns;
        return Wrap(spacing: 6, runSpacing: 6, children: [
          for (final (icon, value, label, color) in items)
            Container(
                width: width,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                    color: Color.lerp(Colors.white, color, .13),
                    borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Icon(icon, size: 20, color: color),
                  Text(value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: color,
                          fontSize: 21,
                          fontWeight: FontWeight.w900)),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: _forestInk,
                          fontSize: 12,
                          fontWeight: FontWeight.w700))
                ])),
        ]);
      });
}
