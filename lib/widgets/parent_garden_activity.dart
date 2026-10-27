import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/learning_progress.dart';
import '../models/weekly_learning_summary.dart';
import '../providers/app_provider.dart';
import 'button_sound.dart';
import 'learning_progress_widgets.dart';
import 'parent_report_frames.dart';
import 'parent_rewards_frame.dart';

const _cream = Color(0xFFF2FFD0);
const _muted = Color(0xFFCEE5D7);
const _gold = Color(0xFFFFD84C);

/// The Activity garden uses one calendar window for bars, totals and details.
class ParentGardenActivity extends StatefulWidget {
  const ParentGardenActivity({super.key});
  @override
  State<ParentGardenActivity> createState() => _ParentGardenActivityState();
}

class _ParentGardenActivityState extends State<ParentGardenActivity> {
  final _daily = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final week = p.getWeeklySummary();
    return DefaultTextStyle.merge(
        style: const TextStyle(
            fontFamily: 'Nunito', color: Colors.white, fontSize: 14),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ParentReportFrame(
              kind: ParentReportKind.weekly,
              title: 'Weekly Activity',
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('The last 7 days.',
                        style: TextStyle(
                            color: ParentReportFrame.muted, fontSize: 12)),
                    const SizedBox(height: 8),
                    _Inset(
                        child: Row(children: [
                      const _Badge(
                          icon: Icons.local_fire_department_rounded,
                          color: Color(0xFFFF9850),
                          size: 32),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('${p.streak}-Day Learning Streak',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 3),
                            Text(
                                p.streak == 0
                                    ? 'A little practice can start a new streak.'
                                    : 'Keep it up! Consistency builds great habits.',
                                style: const TextStyle(
                                    color: ParentReportFrame.muted,
                                    fontSize: 11)),
                          ])),
                      const SizedBox(width: 6),
                      const Icon(Icons.auto_awesome_rounded,
                          color: _gold, size: 20),
                    ])),
                    const SizedBox(height: 8),
                    const Text('Questions Answered · Last 7 days',
                        style: TextStyle(
                            color: ParentReportFrame.muted, fontSize: 12)),
                    if (!week.hasActivity)
                      const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                              'No learning activity recorded this week.',
                              style: TextStyle(color: ParentReportFrame.ink))),
                    _WeekBars(week: week),
                    const SizedBox(height: 6),
                    _Inset(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                          const Row(children: [
                            Icon(Icons.article_rounded,
                                color: ParentReportFrame.ink, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                                child: Text('This Week · Last 7 days',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900)))
                          ]),
                          const SizedBox(height: 6),
                          _StatTiles(items: [
                            (
                              Icons.quiz_rounded,
                              '${week.questionsAnswered}',
                              'Questions Answered',
                              const Color(0xFF7261BD)
                            ),
                            (
                              Icons.check_circle_rounded,
                              '${week.correctAnswers}',
                              'Correct Answers',
                              const Color(0xFF239B62)
                            ),
                            (
                              Icons.extension_rounded,
                              '${week.activitiesCompleted}',
                              'Activities Completed',
                              const Color(0xFFA16E32)
                            ),
                            (
                              Icons.track_changes_rounded,
                              week.accuracy == null
                                  ? 'Not yet'
                                  : accuracyLabel(week.accuracy),
                              'Overall Accuracy',
                              const Color(0xFF247B9D)
                            ),
                          ]),
                        ])),
                    const SizedBox(height: 8),
                    _Inset(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('Speech Practice',
                              style: TextStyle(
                                  color: ParentReportFrame.ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900)),
                          Text(
                              '${week.speechAttempts} attempts · ${week.speechRecognized} words recognized · ${week.speechActivitiesCompleted} activities completed',
                              style: const TextStyle(
                                  color: ParentReportFrame.ink, fontSize: 12)),
                          const Text(
                              'Recognized-word matching is separate from phonics answer accuracy and does not score pronunciation.',
                              style: TextStyle(
                                  color: ParentReportFrame.muted,
                                  fontSize: 12)),
                        ])),
                    const SizedBox(height: 8),
                    _Inset(
                        child: ListTile(
                            dense: true,
                            minTileHeight: 48,
                            contentPadding: EdgeInsets.zero,
                            leading: const _Badge(
                                icon: Icons.schedule_rounded,
                                color: Color(0xFF9A75E6),
                                size: 30),
                            title: const Text('Recent Activity',
                                style: TextStyle(
                                    color: ParentReportFrame.ink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900)),
                            subtitle: const Text('Daily totals · Last 7 days',
                                style: TextStyle(
                                    color: ParentReportFrame.muted,
                                    fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right_rounded,
                                color: ParentReportFrame.ink),
                            onTap: withButtonSound(() {
                              final target = _daily.currentContext;
                              if (target != null) {
                                Scrollable.ensureVisible(target,
                                    alignment: 0,
                                    duration: MediaQuery.disableAnimationsOf(
                                            context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 300));
                              }
                            }))),
                  ])),
          ParentReportFrame(
              key: _daily,
              kind: ParentReportKind.daily,
              title: 'Daily Breakdown',
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final day in week.days.reversed) _DayRow(day: day),
                  ])),
          _RewardsCard(provider: p),
        ]));
  }
}

class _Inset extends StatelessWidget {
  const _Inset({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
          color: const Color(0xFFDFF0D1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x447FC995))),
      child: child);
}

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.icon,
      this.color = const Color(0xFF299552),
      this.size = 36});
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * .32),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(color, Colors.white, .2)!, color])),
          child: Icon(icon, color: _cream, size: size * .62)));
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.week});
  final WeeklyLearningSummary week;
  @override
  Widget build(BuildContext context) {
    final maximum = week.maximumQuestions;
    return Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final day in week.days)
            Expanded(
                child: Semantics(
                    label:
                        '${localDateKey(day.date)}: ${day.activity.questionsAnswered} questions',
                    excludeSemantics: true,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('${day.activity.questionsAnswered}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: maximum > 0 &&
                                              day.activity.questionsAnswered ==
                                                  maximum
                                          ? const Color(0xFF916000)
                                          : ParentReportFrame.ink))),
                          const SizedBox(height: 3),
                          Container(
                              key: ValueKey(
                                  'parent-week-bar-${localDateKey(day.date)}'),
                              height: maximum == 0 ||
                                      day.activity.questionsAnswered == 0
                                  ? 4
                                  : 52 *
                                      day.activity.questionsAnswered /
                                      maximum,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5)),
                                  gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: maximum > 0 &&
                                              day.activity.questionsAnswered ==
                                                  maximum
                                          ? [
                                              const Color(0xFFFFE769),
                                              const Color(0xFFFFB938)
                                            ]
                                          : [
                                              const Color(0xFF9AFF88),
                                              const Color(0xFF26BD7D)
                                            ]))),
                          const Divider(height: 1, color: Color(0xFF90AF90)),
                          const SizedBox(height: 4),
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
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800))),
                          FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('${day.date.month}/${day.date.day}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: ParentReportFrame.muted))),
                        ]))),
        ]));
  }
}

class _StatTiles extends StatelessWidget {
  const _StatTiles({required this.items});
  final List<(IconData, String, String, Color)> items;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns = box.maxWidth >= 290 * scale
            ? items.length
            : box.maxWidth >= 150 * scale
                ? 2
                : 1;
        final width = (box.maxWidth - (columns - 1) * 6 - .01) / columns;
        return Wrap(spacing: 6, runSpacing: 6, children: [
          for (final (icon, value, label, color) in items)
            Semantics(
                label: '$label: $value',
                excludeSemantics: true,
                child: Container(
                    width: width,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: .75),
                        border: Border.all(color: color),
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(children: [
                      Icon(icon, color: Colors.white, size: 18),
                      Text(value,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900)),
                      Text(label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, height: 1.25)),
                    ]))),
        ]);
      });
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});
  final LearningDay day;
  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context).formatMediumDate(day.date);
    final data = day.activity;
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
    final accuracy = day.accuracy == null
        ? data.activitiesCompleted > 0 ||
                data.speechAttempts > 0 ||
                data.speechActivitiesCompleted > 0
            ? 'No answers yet'
            : 'No activity yet'
        : accuracyLabel(day.accuracy);
    final dateLabel = Text(date,
        style: const TextStyle(
            color: ParentReportFrame.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800));
    final meter = _DailyAccuracy(value: day.accuracy, label: accuracy);
    final counts = Text(
        '${data.questionsAnswered} questions · ${data.activitiesCompleted} ${data.activitiesCompleted == 1 ? 'activity' : 'activities'}'
        '${data.speechAttempts == 0 ? '' : ' · ${data.speechAttempts} speech attempts'}',
        style: const TextStyle(color: ParentReportFrame.muted, fontSize: 11));
    return Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFE2F0D3),
            borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          key: ValueKey('parent-day-${localDateKey(day.date)}'),
          minTileHeight: 48,
          visualDensity: const VisualDensity(vertical: -1),
          dense: true,
          iconColor: ParentReportFrame.ink,
          collapsedIconColor: ParentReportFrame.muted,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          shape: const Border(),
          collapsedShape: const Border(),
          title: largeText
              ? dateLabel
              : Row(children: [
                  Expanded(flex: 5, child: dateLabel),
                  const SizedBox(width: 8),
                  Expanded(flex: 6, child: meter),
                ]),
          subtitle: largeText
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [counts, const SizedBox(height: 4), meter])
              : counts,
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    'Questions Answered: ${data.questionsAnswered}\nCorrect Answers: ${data.correctAnswers}\n'
                    'Activities Completed: ${data.activitiesCompleted}\nOverall Activity Accuracy: $accuracy',
                    style: const TextStyle(
                        color: ParentReportFrame.ink, fontSize: 14)))
          ],
        ));
  }
}

class _DailyAccuracy extends StatelessWidget {
  const _DailyAccuracy({required this.value, required this.label});
  final double? value;
  final String label;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            flex: 3,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                    minHeight: 6,
                    value: value ?? 0,
                    color: const Color(0xFF239B62),
                    backgroundColor: const Color(0xFFBBD0AE)))),
        const SizedBox(width: 6),
        Flexible(
            flex: 4,
            child: Text(label,
                style: const TextStyle(
                    color: ParentReportFrame.muted, fontSize: 11))),
      ]);
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({required this.provider});
  final AppProvider provider;

  void _showAchievements(BuildContext context) {
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF124C39),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => SafeArea(
            child: SizedBox(
                height: MediaQuery.sizeOf(ctx).height * .7,
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        const Expanded(
                            child: Text('Milestones and badges',
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    color: _cream,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900))),
                        IconButton(
                            tooltip: 'Close achievements',
                            onPressed:
                                withButtonSound(() => Navigator.pop(ctx)),
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white)),
                      ])),
                  Expanded(
                      child: ListView(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          children: [
                        for (final achievement
                            in provider.quickCheckAchievements)
                          ListTile(
                            dense: true,
                            leading: Icon(
                                achievement.unlocked
                                    ? Icons.verified_rounded
                                    : Icons.lock_outline_rounded,
                                color: achievement.unlocked ? _gold : _muted),
                            title: Text(
                                '${achievement.title} · ${achievement.unlocked ? 'Unlocked' : 'Locked'}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                            subtitle: Text(achievement.description,
                                style: const TextStyle(color: _muted)),
                          ),
                      ])),
                ]))));
  }

  @override
  Widget build(BuildContext context) {
    final total = provider.quickCheckAchievements.length;
    return ParentRewardsFrame(
      level: provider.level,
      xp: provider.xp,
      stars: provider.stars,
      earned: provider.quickCheckAchievements.where((a) => a.unlocked).length,
      total: total,
      onViewAll: withButtonSound(() => _showAchievements(context)),
    );
  }
}
