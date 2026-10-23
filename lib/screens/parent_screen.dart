import '../widgets/main_navigation_shell.dart';
import '../widgets/button_sound.dart';
import '../widgets/school_room_body.dart';
// lib/screens/parent_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../widgets/parent_garden_activity.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/parent_pin_form.dart';
import '../widgets/parent_settings_design.dart';
import '../widgets/parent_garden_overview.dart';
import '../widgets/main_navigation_scope.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen(
      {super.key, this.initialTab = 0, this.settingsOnly = false});
  final int initialTab;
  final bool settingsOnly;
  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  AppProvider? _provider;
  bool _resetDialogOpen = false;
  late int _tab = widget.initialTab;
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
                    backgroundColor: const Color(0xFFFFFEF5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: Text('Reset all learning progress?',
                        style: GoogleFonts.fredoka(
                            color: AppColors.wrong, fontSize: 20)),
                    content: Text(
                        'This will remove mastery, activity, XP, stars, and streak data. This cannot be undone.',
                        style: GoogleFonts.nunito(
                            color: parentMuted, fontSize: 14)),
                    actions: [
                      TextButton(
                          onPressed: withButtonSound(resetting
                              ? null
                              : () => Navigator.pop(dialogContext)),
                          child: const Text('Cancel')),
                      ElevatedButton(
                          onPressed: withButtonSound(resetting
                              ? null
                              : () async {
                                  if (resetting) return;
                                  if (!provider.parentAuth.isAuthenticated) {
                                    Navigator.pop(dialogContext);
                                    return;
                                  }
                                  update(() => resetting = true);
                                  final saved = await provider.resetProgress();
                                  if (!dialogContext.mounted) return;
                                  Navigator.pop(dialogContext);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(saved
                                              ? 'Progress reset!'
                                              : 'Reset is waiting to save. Keep the app open and tap Retry.'),
                                          backgroundColor: saved
                                              ? AppColors.wrong
                                              : const Color(0xFF735200),
                                          duration: Duration(
                                              seconds: saved ? 2 : 6)));
                                }),
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
      return Theme(
          data: parentPanelTheme,
          child: Scaffold(
              body: _ParentGarden(
                  settingsOnly: widget.settingsOnly,
                  child: SafeArea(
                      child: ParentPinForm(
                          auth: provider.parentAuth,
                          onBack: () {
                            final navigation =
                                MainNavigationScope.maybeOf(context);
                            if (navigation != null) {
                              navigation.select(KidsDestination.home);
                            } else {
                              Navigator.maybePop(context);
                            }
                          })))));
    }
    final time = provider.screenTime;
    return Theme(
        data: parentPanelTheme,
        child: Scaffold(
            body: _ParentGarden(
                settingsOnly: widget.settingsOnly,
                child: Column(children: [
                  if (provider.hasUnsavedChanges || time.hasUnsavedChanges)
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Material(
                            color: const Color(0xFFFFF1C9),
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                                title: const Text(
                                    'Some changes are waiting to save.'),
                                subtitle: const Text(
                                    'Keep the app open and retry saving.'),
                                trailing: TextButton(
                                    onPressed: () => provider.retrySaving(),
                                    child: const Text('Retry'))))),
                  if (!widget.settingsOnly)
                    SafeArea(
                      top: false,
                      bottom: false,
                      child: Center(
                          child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                          child: Row(children: [
                            for (final (index, label, icon) in [
                              (0, 'Overview', Icons.space_dashboard_rounded),
                              (1, 'Activity', Icons.insights_rounded),
                              (2, 'Settings', Icons.tune_rounded),
                            ])
                              Expanded(
                                  child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                child: ParentTabButton(
                                  key: ValueKey('parent-tab-$index'),
                                  label: label,
                                  icon: icon,
                                  selected: _tab == index,
                                  onPressed: withButtonSound(() {
                                    setState(() => _tab = index);
                                    if (_scroll.hasClients) _scroll.jumpTo(0);
                                  })!,
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
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
                        children: [
                          if (_tab == 0) const ParentGardenOverview(),
                          if (_tab == 1) const ParentGardenActivity(),
                          if (_tab == 2) ...[
                            const _ParentSection(
                                icon: Icons.timer_rounded,
                                description: 'Time spent learning.',
                                title: "Today's Screen Time",
                                child: ParentScreenTimeSummary()),
                            _ParentSection(
                                icon: Icons.sports_esports_rounded,
                                title: 'Learning & Play',
                                description: 'Games and daily limits.',
                                child: Column(children: [
                                  ParentSettingToggle(
                                      title: 'Games',
                                      icon: Icons.sports_esports_rounded,
                                      color: const Color(0xFFE5DCFF),
                                      ink: const Color(0xFF8958CF),
                                      subtitle: provider.gameAccess
                                          ? 'Enabled'
                                          : 'Disabled',
                                      value: provider.gameAccess,
                                      onChanged: withSelectionSound(
                                          (_) => provider.toggleGameAccess())),
                                  ParentSettingToggle(
                                      title: 'Daily Time Limit',
                                      icon: Icons.schedule_rounded,
                                      color: const Color(0xFFFFDFE5),
                                      ink: const Color(0xFFD92958),
                                      value: time.isLimitEnabled,
                                      onChanged: withSelectionSound(
                                          time.setLimitEnabled)),
                                  DropdownButtonFormField<int>(
                                      isExpanded: true,
                                      onTap: withButtonSound(() {}),
                                      initialValue: time.dailyLimitMinutes,
                                      decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 12),
                                          labelText: 'Daily Limit',
                                          filled: true,
                                          fillColor: const Color(0xCCFFFFFF),
                                          prefixIcon: const Padding(
                                              padding: EdgeInsets.all(8),
                                              child: ParentIconBadge(
                                                  icon: Icons.schedule_rounded,
                                                  color: Color(0xFFD5F0FF),
                                                  ink: Color(0xFF087DB6))),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              borderSide: BorderSide.none)),
                                      items: [15, 30, 45, 60, 90]
                                          .map((m) => DropdownMenuItem(
                                              value: m,
                                              child: Text('$m minutes')))
                                          .toList(),
                                      onChanged: withSelectionSound((m) {
                                        if (m != null) time.setDailyLimit(m);
                                      })),
                                ])),
                            GardenCard(
                                child: ParentActionRow(
                                    icon: Icons.tune_rounded,
                                    title: 'App Settings',
                                    onTap: withButtonSound(() =>
                                        navigateKidsTab(context,
                                            KidsDestination.settings)))),
                            _ParentSection(
                                icon: Icons.lock_rounded,
                                title: 'Parent Access',
                                description: 'Protect parent settings.',
                                child: Column(children: [
                                  ParentActionRow(
                                      icon: Icons.lock_rounded,
                                      highlight: true,
                                      title: 'Change Parent PIN',
                                      onTap: withButtonSound(() => showDialog<
                                              void>(
                                          context: context,
                                          builder: (ctx) => Dialog(
                                              child: ParentPinForm(
                                                  auth: provider.parentAuth,
                                                  changePin: true,
                                                  onBack: () =>
                                                      Navigator.pop(ctx),
                                                  onSuccess: () =>
                                                      Navigator.pop(ctx)))))),
                                ])),
                            _ParentSection(
                                icon: Icons.delete_outline_rounded,
                                accent: const Color(0xFFFFB8AD),
                                description: 'Reset learning progress.',
                                title: 'Data / Reset',
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                          'Reset learning progress only. Parent settings and screen-time usage are kept.'),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFFFE7E8),
                                              foregroundColor:
                                                  const Color(0xFFE9264C),
                                              side: const BorderSide(
                                                  color: Color(0xFFFF5270),
                                                  width: 1.5),
                                              minimumSize: const Size(
                                                  double.infinity, 48),
                                              textStyle: const TextStyle(
                                                  fontFamily: 'Nunito',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900),
                                              shape: const StadiumBorder()),
                                          onPressed: withButtonSound(
                                              () => _confirmReset(provider)),
                                          icon: const Icon(Icons.delete_outline,
                                              color: AppColors.wrong),
                                          label: const Text('Reset Progress',
                                              style: TextStyle(
                                                  color: AppColors.wrong))),
                                    ])),
                          ],
                        ]),
                  ))),
                ]))));
  }
}

class _ParentSection extends ParentSectionCard {
  const _ParentSection(
      {required super.title,
      required super.description,
      required super.icon,
      required super.child,
      super.accent});
}

class _ParentGarden extends StatelessWidget {
  const _ParentGarden({required this.child, this.settingsOnly = false});
  final Widget child;
  final bool settingsOnly;
  @override
  Widget build(BuildContext context) => SchoolRoomBody(
      room: SchoolRoom.parents,
      navigationDestination:
          settingsOnly ? KidsDestination.settings : KidsDestination.parents,
      child: child);
}
