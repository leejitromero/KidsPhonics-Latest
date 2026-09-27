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

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});
  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  AppProvider? _provider;
  bool _resetDialogOpen = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<AppProvider>();
  }

  @override
  void dispose() {
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
      Expanded(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(padding: const EdgeInsets.all(14), children: [
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
              border: Border.all(color: const Color(0xFFE6F9AB), width: 2),
            ),
            child: const Column(children: [
              Text('Growing together',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFF294A23),
                      fontSize: 26,
                      fontWeight: FontWeight.w900)),
              SizedBox(height: 12),
              MascotPortrait(mascot: LearningMascot.jitjit, size: 144),
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
                      color: Color(0xFF294A23), fontSize: 17, height: 1.4)),
            ]),
          ),
          const DashboardSection(
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
          const DashboardSection(
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
          const DashboardSection(
              title: 'Weekly Activity',
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LearningStreak(),
                    SizedBox(height: 12),
                    WeeklyActivityChart(),
                    RecentLearningActivity(),
                  ])),
          const DashboardSection(title: 'Rewards', child: RewardsSummary()),
          const DashboardSection(
              title: "Today's Screen Time", child: ParentScreenTimeSummary()),
          DashboardSection(
              title: 'Parent Controls',
              child: Column(children: [
                SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Games'),
                    subtitle:
                        Text(provider.gameAccess ? 'Enabled' : 'Disabled'),
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
                    subtitle:
                        const Text('Pauses for voices and speech practice'),
                    value: provider.musicEnabled,
                    onChanged: (_) => provider.toggleMusic()),
                Text('Music volume: ${(provider.musicVolume * 100).round()}%'),
                Slider(
                    value: provider.musicVolume,
                    max: .4,
                    divisions: 20,
                    label: '${(provider.musicVolume * 100).round()}%',
                    semanticFormatterCallback: (value) =>
                        '${(value * 100).round()} percent',
                    onChanged:
                        provider.musicEnabled ? provider.setMusicVolume : null),
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
          DashboardSection(
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
        ]),
      ))),
    ])));
  }
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
