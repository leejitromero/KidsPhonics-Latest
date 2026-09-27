import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/learning_progress.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

extension LearningStatusDisplay on LearningStatus {
  String get label => switch (this) {
        LearningStatus.notStarted => 'Not Started',
        LearningStatus.viewed => 'Viewed',
        LearningStatus.practiced => 'Practiced',
        LearningStatus.mastered => 'Mastered',
      };
  Color get color => switch (this) {
        LearningStatus.notStarted => Colors.grey,
        LearningStatus.viewed => Colors.lightBlueAccent,
        LearningStatus.practiced => Colors.orangeAccent,
        LearningStatus.mastered => AppColors.teal,
      };
  IconData get icon => switch (this) {
        LearningStatus.notStarted => Icons.circle_outlined,
        LearningStatus.viewed => Icons.visibility_outlined,
        LearningStatus.practiced => Icons.edit_outlined,
        LearningStatus.mastered => Icons.check_circle,
      };
}

String accuracyLabel(double? accuracy) => accuracy == null || !accuracy.isFinite
    ? 'No attempts yet'
    : '${(accuracy.clamp(0.0, 1.0) * 100).round()}%';

class LearningProgressSummary extends StatelessWidget {
  const LearningProgressSummary({super.key, this.detailed = true});
  final bool detailed;
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Letters Mastered: ${p.masteredLetterCount} / 26',
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      LinearProgressIndicator(
          value: p.masteryPercentage / 100,
          minHeight: 10,
          color: AppColors.teal,
          backgroundColor: Colors.white12),
      const SizedBox(height: 8),
      Text('Phonics Mastery: ${p.masteryPercentage.round()}%',
          style: const TextStyle(fontSize: 16)),
      if (p.masteredLetterCount == 0)
        const Text('Start practicing letters to see progress here.'),
      Text('Vowel Progress: ${p.masteredVowelCount} / 5 mastered',
          style: const TextStyle(fontSize: 16)),
      if (detailed) ...[
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 8, children: [
          Text('Practiced: ${p.practicedLetterCount}'),
          Text('Viewed: ${p.viewedLetterCount}'),
          Text('Not Started: ${p.notStartedLetterCount}'),
        ]),
        const SizedBox(height: 8),
        Text(
            'Letter Practice Accuracy: ${accuracyLabel(p.letterPracticeAccuracy)}'),
        Text(
            'Overall Activity Accuracy: ${accuracyLabel(p.overallActivityAccuracy)}'),
        const SizedBox(height: 6),
        const Text(
            'Each letter is counted in one current status. Accuracy above uses all recorded answers in its category.',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    ]);
  }
}

void showLetterDetail(BuildContext context, LetterProgress p) {
  final parsed = p.masteredAt == null ? null : DateTime.tryParse(p.masteredAt!);
  final date = parsed != null && p.masteredAt!.startsWith(localDateKey(parsed))
      ? parsed.toLocal()
      : null;
  showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
            title: Text('Letter ${p.letter}'),
            content: SingleChildScrollView(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${p.status.label}'),
                Text('Attempts: ${p.attempts}'),
                Text('Correct: ${p.correctAnswers}'),
                Text('Letter Practice Accuracy: ${accuracyLabel(p.accuracy)}'),
                Text(
                    'Best Quick Check: ${p.completedAssessments == 0 ? 'Not taken yet' : '${p.bestAssessmentScore} / 5'}'),
                if (p.mastered && date != null)
                  Text(
                      'Mastered: ${MaterialLocalizations.of(ctx).formatFullDate(date)}'),
              ],
            )),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'))
            ],
          ));
}

class LetterProgressGrid extends StatelessWidget {
  const LetterProgressGrid({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final scale = MediaQuery.textScalerOf(context).scale(20) / 20;
    return Column(children: [
      Wrap(
          spacing: 12,
          runSpacing: 8,
          children: LearningStatus.values
              .map((s) => Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(s.icon, color: s.color, size: 20),
                    const SizedBox(width: 4),
                    Text(s.label,
                        style: TextStyle(color: s.color, fontSize: 14)),
                  ]))
              .toList()),
      const SizedBox(height: 12),
      LayoutBuilder(
          builder: (_, box) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        (box.maxWidth / (60 * scale)).floor().clamp(3, 6),
                    mainAxisExtent: 68 * scale,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6),
                itemCount: 26,
                itemBuilder: (context, index) {
                  final p = provider
                      .getLetterProgress(String.fromCharCode(65 + index));
                  final s = p.status;
                  return Semantics(
                      label: '${p.letter}: ${s.label}',
                      button: true,
                      child: Tooltip(
                          message: '${p.letter}: ${s.label}',
                          child: InkWell(
                            key: ValueKey('letter-status-${p.letter}'),
                            onTap: () => showLetterDetail(context, p),
                            child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: s.color.withValues(alpha: 0.12),
                                    border: Border.all(color: s.color)),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(p.letter,
                                          style: TextStyle(
                                              color: s.color, fontSize: 24)),
                                      Icon(s.icon, color: s.color, size: 20),
                                    ])),
                          )));
                },
              )),
    ]);
  }
}

class WeeklyActivityChart extends StatelessWidget {
  const WeeklyActivityChart({super.key});
  @override
  Widget build(BuildContext context) {
    final summary = context.watch<AppProvider>().getWeeklySummary();
    final maximum = summary.maximumQuestions;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Questions Answered · Last 7 days',
          style: TextStyle(fontSize: 16)),
      if (!summary.hasActivity)
        const Text('No learning activity recorded this week.'),
      if (maximum > 0) ...[
        const SizedBox(height: 8),
        SizedBox(
            height: 90 + 65 * scale,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: summary.days
                  .map((day) => Expanded(
                          child: Semantics(
                        label:
                            '${localDateKey(day.date)}: ${day.activity.questionsAnswered} questions',
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                      '${day.activity.questionsAnswered}')),
                              Container(
                                  height: 80 *
                                      day.activity.questionsAnswered /
                                      maximum,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  color: AppColors.teal),
                              FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                      const [
                                        'Mon',
                                        'Tue',
                                        'Wed',
                                        'Thu',
                                        'Fri',
                                        'Sat',
                                        'Sun'
                                      ][day.date.weekday - 1],
                                      style: const TextStyle(fontSize: 14))),
                              FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                      '${day.date.month}/${day.date.day}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70))),
                            ]),
                      )))
                  .toList(),
            )),
      ],
      const SizedBox(height: 12),
      const Text('This Week · Last 7 days',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      Text('Questions Answered: ${summary.questionsAnswered}'),
      Text('Correct Answers: ${summary.correctAnswers}'),
      Text('Activities Completed: ${summary.activitiesCompleted}'),
      Text(
          'Overall Activity Accuracy: ${summary.accuracy == null ? 'No activity yet' : accuracyLabel(summary.accuracy)}'),
    ]);
  }
}

class NeedsPractice extends StatelessWidget {
  const NeedsPractice({super.key});
  Widget _row(LetterProgress p) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
          '${p.letter} · ${p.correctAnswers} correct / ${p.attempts} attempts\n'
          'Letter Practice Accuracy: ${accuracyLabel(p.accuracy)}',
          style: const TextStyle(fontSize: 15)));
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final letters = p.lettersNeedingPractice;
    if (letters.isEmpty) {
      return Text(p.letterPracticeAccuracy == null
          ? 'Practice a few letters first to see recommendations.'
          : 'Great work! No practiced letters currently need extra practice.');
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Top 5 letters needing practice'),
      ...letters.take(5).map(_row),
      if (letters.length > 5)
        TextButton(
            onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                      title: const Text('Needs Practice'),
                      content: SizedBox(
                          width: 360,
                          child: SingleChildScrollView(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: letters.map(_row).toList()))),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'))
                      ],
                    )),
            child: Text('View All (${letters.length})')),
    ]);
  }
}

class RecommendedPractice extends StatelessWidget {
  const RecommendedPractice({super.key});
  @override
  Widget build(BuildContext context) {
    final letter = context.watch<AppProvider>().recommendedNextPractice;
    if (letter == null) {
      return const Text(
          'You mastered all 26 letters! Keep exploring your lessons.');
    }
    final reason = switch (letter.status) {
      LearningStatus.practiced =>
        '${letter.letter} needs a little more practice.',
      LearningStatus.viewed =>
        'You have viewed ${letter.letter}. Try a quick check next.',
      _ => 'Explore ${letter.letter} in your letter lessons.',
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Practice Letter ${letter.letter}',
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.gold)),
      Text(reason, style: const TextStyle(fontSize: 16)),
    ]);
  }
}
