// lib/screens/parent_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../widgets/learning_progress_widgets.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/parent_pin_form.dart';
import '../widgets/mascot_guide.dart';
import '../widgets/parent_weekly_summary.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});
  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  AppProvider? _provider;
  bool _resetDialogOpen = false;
  int _tab = 0;
  final _scroll = ScrollController();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<AppProvider>();
  }

  @override
  void dispose() {
    _scroll.dispose();
    final provider = _provider;
    if (provider != null && provider.isReady) {
      // Route removal can happen during a build; defer notifications.
      Future.microtask(provider.parentAuth.endSession);
    }
    super.dispose();
  }

  Future<void> _confirmReset(AppProvider provider) async {
    if (_resetDialogOpen) return;
    provider.parentAuth.requireSession();
    _resetDialogOpen = true;
    var resetting = false;
    try {
      await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => StatefulBuilder(
              builder: (ctx, update) => AlertDialog(
                    backgroundColor: AppColors.darkBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: Text('Reset all learning progress?',
                        style: GoogleFonts.fredoka(
                            color: AppColors.wrong, fontSize: 20)),
                    content: Text(
                        'This will remove mastery, activity, XP, stars, and streak data. This cannot be undone.',
                        style: GoogleFonts.nunito(
                            color: Colors.white70, fontSize: 13)),
                    actions: [
                      TextButton(
                          onPressed: resetting
                              ? null
                              : () => Navigator.pop(dialogContext),
                          child: const Text('Cancel')),
                      ElevatedButton(
                          onPressed: resetting
                              ? null
                              : () async {
                                  if (resetting) return;
                                  if (!provider.parentAuth.isAuthenticated) {
                                    Navigator.pop(dialogContext);
                                    return;
                                  }
                                  update(() => resetting = true);
                                  await provider.resetProgress();
                                  if (!dialogContext.mounted) return;
                                  Navigator.pop(dialogContext);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Progress reset!'),
                                          backgroundColor: AppColors.wrong,
                                          duration: Duration(seconds: 2)));
                                },
                          child: Text(
                              resetting ? 'Resetting…' : 'Reset Progress')),
                    ],
                  )));
    } finally {
      _resetDialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (!provider.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!provider.parentAuth.isAuthenticated) {
      return Scaffold(
          body: _ParentGarden(
              child: SafeArea(
                  child: ParentPinForm(
                      auth: provider.parentAuth,
                      onBack: () => Navigator.pop(context)))));
    }
    final time = provider.screenTime;
    return Scaffold(
        body: _ParentGarden(
            child: Column(children: [
      KidsHeader(
          title: 'Parent Panel',
          gradient: const LinearGradient(
              colors: [Color(0xFF426722), Color(0xFF244F39)]),
          textColor: const Color(0xFFF4FFD9),
          onBack: () => Navigator.pop(context)),
      SafeArea(
        top: false,
        bottom: false,
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(children: [
              for (final (index, label, icon) in [
                (0, 'Overview', Icons.space_dashboard_rounded),
                (1, 'Activity', Icons.insights_rounded),
                (2, 'Settings', Icons.tune_rounded),
              ])
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Semantics(
                    selected: _tab == index,
                    child: TextButton(
                      key: ValueKey('parent-tab-$index'),
                      onPressed: () {
                        setState(() => _tab = index);
                        if (_scroll.hasClients) _scroll.jumpTo(0);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: _tab == index
                            ? const Color(0xFF203D32)
                            : Colors.white,
                        backgroundColor: _tab == index
                            ? const Color(0xFFDDF3B8)
                            : const Color(0xFF305346),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Column(children: [
                        Icon(icon),
                        const SizedBox(height: 6),
                        Text(label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                )),
            ]),
          ),
        )),
      ),
      Expanded(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
            children: [
              if (_tab == 0) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF6FFD5), Color(0xFFD9EFA2)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border:
                        Border.all(color: const Color(0xFFE6F9AB), width: 2),
                  ),
                  child: const Column(children: [
                    Text('Growing together',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFF294A23),
                            fontSize: 26,
                            fontWeight: FontWeight.w900)),
                    SizedBox(height: 12),
                    MascotPortrait(mascot: LearningMascot.jitjit, size: 72),
                    SizedBox(height: 8),
                    Text('Jitjit welcomes you!',
                        style: TextStyle(
                            color: Color(0xFF294A23),
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text(
                        'Support little steps, celebrate growth, and make time for learning.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFF294A23),
                            fontSize: 17,
                            height: 1.4)),
                  ]),
                ),
                const _ParentSection(
                    icon: Icons.school_rounded,
                    description:
                        'A clear picture of your child’s letter learning.',
                    title: 'This Week at a Glance',
                    child: ParentWeeklySummary()),
                const _ParentSection(
                    icon: Icons.school_rounded,
                    description: 'Progress across all learning sessions.',
                    title: 'Child Learning Summary',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LearningProgressSummary(),
                          SizedBox(height: 12),
                          ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: Text('Letter Status A–Z'),
                              children: [LetterProgressGrid()]),
                        ])),
                const _ParentSection(
                    icon: Icons.auto_awesome_rounded,
                    description: 'Small steps to try together next.',
                    title: 'Needs Practice',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NeedsPractice(),
                          SizedBox(height: 12),
                          Text('Recommended Next',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold)),
                          RecommendedPractice(),
                        ])),
              ],
              if (_tab == 1) ...[
                const _ParentSection(
                    icon: Icons.bar_chart_rounded,
                    description:
                        'See the learning moments from the last seven days.',
                    title: 'Weekly Activity',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LearningStreak(),
                          SizedBox(height: 12),
                          WeeklyActivityChart(),
                          RecentLearningActivity(),
                        ])),
                const _ParentSection(
                    icon: Icons.emoji_events_rounded,
                    description:
                        'Celebrate effort, milestones, and regular practice.',
                    title: 'Rewards',
                    child: RewardsSummary()),
              ],
              if (_tab == 2) ...[
                const _ParentSection(
                    icon: Icons.timer_rounded,
                    description: 'Keep learning time comfortable and balanced.',
                    title: "Today's Screen Time",
                    child: ParentScreenTimeSummary()),
                _ParentSection(
                    icon: Icons.sports_esports_rounded,
                    title: 'Learning & Play',
                    description:
                        'Choose game access and a daily learning limit.',
                    child: Column(children: [
                      SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Games'),
                          subtitle: Text(
                              provider.gameAccess ? 'Enabled' : 'Disabled'),
                          value: provider.gameAccess,
                          onChanged: (_) => provider.toggleGameAccess()),
                      SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Daily Time Limit'),
                          value: time.isLimitEnabled,
                          onChanged: time.setLimitEnabled),
                      DropdownButtonFormField<int>(
                          initialValue: time.dailyLimitMinutes,
                          decoration: const InputDecoration(
                              labelText: 'Configured Daily Limit'),
                          items: [15, 30, 45, 60, 90]
                              .map((m) => DropdownMenuItem(
                                  value: m, child: Text('$m minutes')))
                              .toList(),
                          onChanged: (m) {
                            if (m != null) time.setDailyLimit(m);
                          }),
                    ])),
                _ParentSection(
                    icon: Icons.volume_up_rounded,
                    title: 'Sound & Voice',
                    description:
                        'Adjust voices, effects, and gentle background music.',
                    child: Column(children: [
                      SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Voice Assistance'),
                          value: provider.voiceEnabled,
                          onChanged: (_) => provider.toggleVoice()),
                      SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Sound Effects'),
                          value: provider.sfxEnabled,
                          onChanged: (_) => provider.toggleSfx()),
                      SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.music_note_rounded),
                          title: const Text('Background Music'),
                          subtitle: const Text(
                              'Pauses for voices and speech practice'),
                          value: provider.musicEnabled,
                          onChanged: (_) => provider.toggleMusic()),
                      Text(
                          'Music volume: ${(provider.musicVolume * 100).round()}%'),
                      Slider(
                          value: provider.musicVolume,
                          max: .4,
                          divisions: 20,
                          label: '${(provider.musicVolume * 100).round()}%',
                          semanticFormatterCallback: (value) =>
                              '${(value * 100).round()} percent',
                          onChanged: provider.musicEnabled
                              ? provider.setMusicVolume
                              : null),
                      TextButton.icon(
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Background Theme'),
                          onPressed: () => showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                    title: const Text('Background Theme'),
                                    content: const SingleChildScrollView(
                                        child: SelectableText(
                                            'A gentle background theme, played at reduced volume.\n\n'
                                            'Music pauses while words, letters, and sound effects play.')),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Close'))
                                    ],
                                  ))),
                    ])),
                _ParentSection(
                    icon: Icons.lock_rounded,
                    title: 'Parent Access',
                    description: 'Manage the PIN that protects these settings.',
                    child: Column(children: [
                      TextButton.icon(
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Change Parent PIN'),
                          onPressed: () => showDialog<void>(
                              context: context,
                              builder: (ctx) => Dialog(
                                  child: ParentPinForm(
                                      auth: provider.parentAuth,
                                      changePin: true,
                                      onBack: () => Navigator.pop(ctx),
                                      onSuccess: () => Navigator.pop(ctx))))),
                    ])),
                _ParentSection(
                    icon: Icons.restart_alt_rounded,
                    accent: const Color(0xFFFFB8AD),
                    description: 'Start over only when you are ready.',
                    title: 'Data / Reset',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                              'Reset learning progress only. Parent settings and screen-time usage are kept.'),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                              onPressed: () => _confirmReset(provider),
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.wrong),
                              label: const Text('Reset Progress',
                                  style: TextStyle(color: AppColors.wrong))),
                        ])),
              ],
            ]),
      ))),
    ])));
  }
}

class _ParentSection extends StatelessWidget {
  const _ParentSection(
      {required this.title,
      required this.description,
      required this.icon,
      required this.child,
      this.accent = const Color(0xFFDDF3B8)});
  final String title, description;
  final IconData icon;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF254A40),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: .22)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 6))
          ],
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: accent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: accent)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: accent))),
          ]),
          const SizedBox(height: 10),
          Text(description,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: Color(0xFFD5E5DE),
                  fontSize: 15,
                  height: 1.4)),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Colors.white12)),
          child,
        ]),
      );
}

class _ParentGarden extends StatelessWidget {
  const _ParentGarden({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF183E33), Color(0xFF293D24), Color(0xFF182C32)],
          ),
        ),
        child: child,
      );
}
