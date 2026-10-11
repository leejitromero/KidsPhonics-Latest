import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/learning_progress.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'learning_progress_widgets.dart';
import 'parent_settings_design.dart';

class DashboardSection extends StatelessWidget {
  const DashboardSection({super.key, required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight)),
          const SizedBox(height: 10),
          child,
        ]),
      );
}

class RewardsSummary extends StatelessWidget {
  const RewardsSummary(
      {super.key, this.showAchievements = false, this.light = false});
  final bool showAchievements;
  final bool light;
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 20, runSpacing: 10, children: [
        _Reward(Icons.emoji_events_outlined, 'Level ${p.level}'),
        _Reward(Icons.bolt, '${p.xp} XP'),
        _Reward(Icons.star_outline, '${p.stars} Stars'),
      ]),
      const SizedBox(height: 10),
      Text(
          '${p.quickCheckAchievements.where((a) => a.unlocked).length} / ${p.quickCheckAchievements.length} Achievements'),
      Text(
          'Rewards celebrate your practice. Mastery comes from letter quick checks.',
          style: TextStyle(
              color: light ? parentMuted : Colors.white70, fontSize: 14)),
      if (showAchievements) ...[
        const SizedBox(height: 12),
        ...p.quickCheckAchievements.map((a) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(a.unlocked ? Icons.verified : Icons.lock_outline,
                    color: a.unlocked ? AppColors.gold : Colors.white60),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${a.title} · ${a.unlocked ? 'Unlocked' : 'Locked'}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(a.description,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white70)),
                    ])),
              ]),
            )),
      ],
    ]);
  }
}

class _Reward extends StatelessWidget {
  const _Reward(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppColors.gold),
        const SizedBox(width: 6),
        Flexible(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold))),
      ]);
}

class LearningStreak extends StatelessWidget {
  const LearningStreak({super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
        const Icon(Icons.local_fire_department, color: Colors.orangeAccent),
        const SizedBox(width: 8),
        Expanded(
            child: Text(
                '${context.watch<AppProvider>().streak}-Day Learning Streak',
                style: const TextStyle(fontSize: 18))),
      ]);
}

class RecentLearningActivity extends StatelessWidget {
  const RecentLearningActivity({super.key});
  @override
  Widget build(BuildContext context) {
    final summary = context.watch<AppProvider>().getWeeklySummary();
    if (!summary.hasActivity) return const SizedBox.shrink();
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Recent Activity'),
      subtitle: const Text('Daily totals · Last 7 days'),
      children: summary.days.reversed.map((day) {
        final offset =
            calendarDay(summary.days.last.date) - calendarDay(day.date);
        final label = offset == 0
            ? 'Today'
            : offset == 1
                ? 'Yesterday'
                : MaterialLocalizations.of(context).formatMediumDate(day.date);
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('$label\n'
                  '${day.activity.questionsAnswered} questions · ${day.activity.activitiesCompleted} activities\n'
                  'Overall Activity Accuracy: ${day.accuracy == null ? 'No activity yet' : accuracyLabel(day.accuracy)}'),
            ));
      }).toList(),
    );
  }
}

/// Display only: allowance and usage calculations remain in ScreenTimeService.
class ParentScreenTimeSummary extends StatelessWidget {
  const ParentScreenTimeSummary({super.key});
  @override
  Widget build(BuildContext context) {
    final time = context.watch<AppProvider>().screenTime;
    final limited = time.isLimitEnabled && !time.isBypassedToday;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFF0F9DF), Color(0xFFEAF7D5)]),
              borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            const ParentIconBadge(icon: Icons.timer_rounded, size: 32),
            const SizedBox(width: 8),
            Expanded(
                child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: limited
                              ? '${time.usedSecondsToday ~/ 60} / ${time.allowedSecondsToday ~/ 60}'
                              : '${time.usedSecondsToday ~/ 60}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w900)),
                      TextSpan(
                          text: limited
                              ? ' minutes allowed today'
                              : ' minutes used today'),
                    ]),
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: parentInk,
                        fontSize: 14,
                        height: 1.2))),
          ])),
      const SizedBox(height: 5),
      if (limited)
        LinearProgressIndicator(
            value: (time.usedSecondsToday / time.allowedSecondsToday)
                .clamp(0.0, 1.0),
            minHeight: 6,
            color: AppColors.teal),
      const SizedBox(height: 5),
      Text(!time.isLimitEnabled
          ? 'Daily limit is turned off.'
          : time.isBypassedToday
              ? 'Limit disabled for today'
              : '${(time.remainingSeconds / 60).ceil()} minutes remaining'),
      Text('Configured Daily Limit: ${time.dailyLimitMinutes} minutes'),
      Text('Extra Time Today: ${time.extraSecondsToday ~/ 60} minutes'),
      const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Divider(height: 1, color: Color(0xFFDCEADB))),
      const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_rounded, color: Color(0xFFAACF64), size: 18),
        SizedBox(width: 8),
        Expanded(
            child: Text('App usage is separate from learning performance.',
                style: TextStyle(fontSize: 12, color: parentMuted))),
      ]),
    ]);
  }
}
