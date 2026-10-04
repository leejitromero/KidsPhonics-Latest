import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/learning_progress.dart';
import '../data/letter_data.dart';
import '../providers/app_provider.dart';
import '../screens/letter_sounds_screen.dart';
import '../screens/letter_mastery_check_screen.dart';
import 'button_sound.dart';
import 'learner_widgets.dart';
import 'learning_progress_widgets.dart';
import 'mascot_guide.dart';

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
    final newlyMastered = p.allLetterProgress.where((letter) {
      final date = DateTime.tryParse(letter.masteredAt ?? '');
      if (!letter.mastered || date == null) return false;
      final day = calendarDay(date.toLocal());
      return day >= start && day <= end;
    }).length;
    final activeDays = week.days
        .where((day) =>
            day.activity.questionsAnswered > 0 ||
            day.activity.activitiesCompleted > 0)
        .length;
    final dates = MaterialLocalizations.of(context);
    final next = p.recommendedNextPractice;
    return DefaultTextStyle.merge(
        style: const TextStyle(color: _forestInk, fontFamily: 'Nunito'),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          GardenCard(
              child: LayoutBuilder(
                  builder: (_, box) => Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const Text('Growing together',
                                  style: TextStyle(
                                      fontSize: 30,
                                      height: 1.05,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(height: 10),
                              const Text(
                                  'Every letter, every activity, a brighter tomorrow.',
                                  style: TextStyle(fontSize: 17, height: 1.35)),
                              const SizedBox(height: 12),
                              Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF3C7C42),
                                      borderRadius: BorderRadius.circular(16)),
                                  child: const Text(
                                      'Jitjit is cheering you on!',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800))),
                            ])),
                        const SizedBox(width: 8),
                        MascotPortrait(
                            mascot: LearningMascot.jitjit,
                            size: box.maxWidth < 340 ? 90 : 150),
                      ]))),
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
                    const SizedBox(height: 8),
                    Text('$activeDays of 7 days with learning activity',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
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
          GardenCard(
              title: 'Child Learning Summary',
              icon: Icons.school_rounded,
              child: Column(children: [
                _progress(
                    'Letters Mastered',
                    '${p.masteredLetterCount} / 26',
                    p.masteredLetterCount / 26,
                    Icons.abc_rounded,
                    const Color(0xFFEF4681)),
                _progress(
                    'Phonics Mastery',
                    '${p.masteryPercentage.round()}%',
                    p.masteryPercentage / 100,
                    Icons.volume_up_rounded,
                    const Color(0xFF9660D9)),
                _progress(
                    'Vowel Progress',
                    '${p.masteredVowelCount} / 5',
                    p.masteredVowelCount / 5,
                    Icons.record_voice_over_rounded,
                    const Color(0xFF1A9B77)),
              ])),
          GardenCard(
              title: 'Letter Status A–Z',
              icon: Icons.bar_chart_rounded,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Each letter is counted in one current status.',
                        style:
                            TextStyle(color: Color(0xFF62736C), fontSize: 14)),
                    const SizedBox(height: 10),
                    _Stats(items: [
                      (
                        Icons.check_circle_rounded,
                        '${p.masteredLetterCount}',
                        'Mastered',
                        const Color(0xFF159852)
                      ),
                      (
                        Icons.visibility_rounded,
                        '${p.viewedLetterCount}',
                        'Viewed',
                        const Color(0xFF0072CC)
                      ),
                      (
                        Icons.schedule_rounded,
                        '${p.practicedLetterCount}',
                        'Practiced',
                        const Color(0xFFD26B00)
                      ),
                      (
                        Icons.more_horiz_rounded,
                        '${p.notStartedLetterCount}',
                        'Not Started',
                        const Color(0xFF66736A)
                      ),
                    ]),
                    ExpansionTile(
                        title: const Text('View all letters',
                            style: TextStyle(color: _forestInk)),
                        onExpansionChanged: withSelectionSound((_) {}),
                        iconColor: _forestInk,
                        collapsedIconColor: _forestInk,
                        children: [
                          Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF254A40),
                                  borderRadius: BorderRadius.circular(18)),
                              child: const LetterProgressGrid())
                        ]),
                  ])),
          GardenCard(
              title: 'Needs Practice',
              icon: Icons.lightbulb_rounded,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                        next == null
                            ? 'All 26 letters mastered!'
                            : 'Practice Letter ${next.letter}',
                        style: const TextStyle(
                            color: Color(0xFF82501B),
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(next == null
                        ? 'Revisit a favorite lesson together.'
                        : next.status == LearningStatus.viewed
                            ? 'You have viewed ${next.letter}. Try a quick check next.'
                            : 'Build confidence with a little letter practice.'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                        onPressed: withButtonSound(() => LearnerNavigation.open(
                            context,
                            next == null
                                ? const LetterSoundsScreen()
                                : LetterMasteryCheckScreen(
                                    letter: letterContent(next.letter)))),
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3C8744),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48)),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Go to Practice')),
                  ])),
        ]));
  }

  Widget _progress(String label, String value, double progress, IconData icon,
          Color color) =>
      Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 8,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 15)),
                        Text(value)
                      ]),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      color: color,
                      backgroundColor: const Color(0xFFE0E2D7),
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(8)),
                ])),
          ]));
}

class GardenCard extends StatelessWidget {
  const GardenCard({super.key, this.title, this.icon, required this.child});
  final String? title;
  final IconData? icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFF6FFDF), Color(0xFFFDFCF0)]),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE1F7A8), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33304F21), offset: Offset(0, 4), blurRadius: 8)
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (title != null) ...[
          Row(children: [
            Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: const Color(0xFFCEEBB5),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: _forestInk, size: 25)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(title!,
                    style: const TextStyle(
                        color: _forestInk,
                        fontSize: 21,
                        fontWeight: FontWeight.w900)))
          ]),
          const SizedBox(height: 12),
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
        final columns = box.maxWidth >= 520 * scale ? 4 : 2;
        final width = (box.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (icon, value, label, color) in items)
            Container(
                width: width,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                    color: Color.lerp(Colors.white, color, .13),
                    borderRadius: BorderRadius.circular(18)),
                child: Column(children: [
                  Icon(icon, size: 28, color: color),
                  Text(value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: color,
                          fontSize: 27,
                          fontWeight: FontWeight.w900)),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: _forestInk,
                          fontSize: 13,
                          fontWeight: FontWeight.w700))
                ])),
        ]);
      });
}
