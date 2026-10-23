import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/app_build_info.dart';
import '../theme/kids_ui.dart';
import '../widgets/button_sound.dart';
import '../widgets/home_guideline_dialog.dart';
import '../widgets/home_progress_banner.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/main_navigation_scope.dart';
import '../widgets/main_navigation_shell.dart';
import '../widgets/school_room_body.dart';
import '../widgets/settings_reference_design.dart';
import '../widgets/settings_sound_design.dart';
import '../widgets/settings_display_design.dart';
import '../widgets/settings_help_design.dart';
import '../widgets/settings_about_design.dart';
import '../widgets/student_character_picker.dart';
import 'welcome_screen.dart';

/// Everyday app preferences; protected controls stay in the Parents section.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _scroll = ScrollController();
  bool _opening = false;
  Future<AppBuildInfo>? _buildInfo;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open(Future<void> Function() action) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _editCharacter() => _open(() => showDialog<void>(
      context: context, builder: (_) => const StudentCharacterPicker()));

  Future<void> _replayIntroduction() => _open(() => LearnerNavigation.open(
      context, const WelcomeScreen(replay: true),
      fadeTransition: true, endParentSession: true));

  Future<void> _deviceSettings() async {
    var opened = false;
    try {
      opened = await openAppSettings();
    } catch (_) {/* Device settings may be unavailable in a desktop preview. */}
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Open device settings and allow microphone access for KidsPhonics.')));
    }
  }

  Future<void> _showHelp() => _open(() => showDialog<void>(
      context: context,
      builder: (ctx) => SettingsHelpDialog(
          key: const ValueKey('settings-help-dialog'),
          onLessons: () => showDialog<void>(
              context: ctx,
              builder: (_) => const HomeGuidelineDialog(
                  games: false, settingsReference: true)),
          onGames: () => showDialog<void>(
              context: ctx,
              builder: (_) => const HomeGuidelineDialog(
                  games: true, settingsReference: true)),
          onDeviceSettings: _deviceSettings)));

  Future<void> _showAbout() => _open(() {
        final info = _buildInfo ??= AppBuildInfo.load();
        return showDialog<void>(
            context: context,
            builder: (ctx) => SettingsAboutDialog(
                key: const ValueKey('settings-about-dialog'),
                info: info,
                character: context.read<AppProvider>().studentCharacter,
                onLicenses: () => showLicensePage(
                    context: ctx, applicationName: 'KidsPhonics')));
      });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Theme(
        data: KidsUi.theme.copyWith(
            listTileTheme: const ListTileThemeData(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                horizontalTitleGap: 12,
                minLeadingWidth: 48,
                titleTextStyle: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    color: settingsInk),
                subtitleTextStyle: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B4D89))),
            expansionTileTheme: const ExpansionTileThemeData(
                tilePadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                childrenPadding: EdgeInsets.only(bottom: 8),
                textColor: settingsInk,
                collapsedTextColor: settingsInk,
                iconColor: settingsPurple,
                collapsedIconColor: settingsPurple,
                shape: Border(),
                collapsedShape: Border())),
        child: Scaffold(
            body: SchoolRoomBody(
                room: SchoolRoom.parents,
                navigationDestination: KidsDestination.settings,
                child: !p.isReady
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        key: const PageStorageKey('settings-scroll'),
                        controller: _scroll,
                        padding: const EdgeInsets.only(bottom: 12),
                        children: [
                            SettingsReferenceHeader(
                                onBack: withButtonSound(() => navigateKidsTab(
                                    context, KidsDestination.home))),
                            if (p.hasUnsavedChanges)
                              SettingsReferenceCard(
                                  child: Column(children: [
                                const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                        'Some changes are waiting to save. Keep the app open and retry.')),
                                TextButton(
                                    key: const ValueKey('settings-retry-save'),
                                    onPressed: withButtonSound(p.retrySaving),
                                    child: const Text('Retry saving')),
                              ])),
                            SettingsSoundPanel(
                                child: ExpansionTile(
                                    expansionAnimationStyle: AnimationStyle(
                                        duration:
                                            MediaQuery.disableAnimationsOf(
                                                    context)
                                                ? Duration.zero
                                                : const Duration(
                                                    milliseconds: 200)),
                                    key: const PageStorageKey('settings-sound'),
                                    leading: const SettingsSoundIcon(
                                        Icons.volume_up_rounded),
                                    title: const Text('Sound & Music'),
                                    subtitle: const Text('Listen your way'),
                                    children: [
                                  SwitchListTile(
                                      key: const ValueKey('settings-voice'),
                                      secondary: const SettingsSoundIcon(
                                          Icons.face_rounded),
                                      title: const Text('Voice Assistance'),
                                      subtitle: const Text(
                                          'Spoken instructions and guide voices'),
                                      value: p.voiceEnabled,
                                      onChanged: withSelectionSound(
                                          (_) => p.toggleVoice())),
                                  const SettingsSoundDivider(),
                                  SwitchListTile(
                                      key: const ValueKey('settings-sfx'),
                                      secondary: const SettingsSoundIcon(
                                          Icons.music_note_rounded),
                                      title: const Text('Sound Effects'),
                                      subtitle: const Text(
                                          'Button taps and activity sounds'),
                                      value: p.sfxEnabled,
                                      onChanged: withSelectionSound(
                                          (_) => p.toggleSfx())),
                                  const SettingsSoundDivider(),
                                  SwitchListTile(
                                      key: const ValueKey('settings-music'),
                                      secondary: const SettingsSoundIcon(
                                          Icons.library_music_rounded),
                                      title: const Text('Background Music'),
                                      subtitle: const Text(
                                          'Pauses while learning audio plays'),
                                      value: p.musicEnabled,
                                      onChanged: withSelectionSound(
                                          (_) => p.toggleMusic())),
                                  SettingsVolumePanel(
                                      label:
                                          'Music volume: ${(p.musicVolume * 100).round()}%',
                                      slider: Slider(
                                          key: const ValueKey(
                                              'settings-music-volume'),
                                          value: p.musicVolume,
                                          max: .4,
                                          divisions: 20,
                                          label:
                                              '${(p.musicVolume * 100).round()}%',
                                          semanticFormatterCallback: (value) =>
                                              '${(value * 100).round()} percent',
                                          onChanged: p.musicEnabled
                                              ? p.setMusicVolume
                                              : null)),
                                  const SettingsMusicNote(),
                                ])),
                            SettingsReferenceCard(
                                child: ListTile(
                                    key: const ValueKey('settings-character'),
                                    leading: SettingsReferenceIcon(
                                        child: Image.asset(
                                            HomeBannerArt.portrait(
                                                p.studentCharacter),
                                            fit: BoxFit.contain,
                                            cacheWidth: 256,
                                            excludeFromSemantics: true)),
                                    title: const Text('My Character'),
                                    subtitle: Text(p.studentName.isEmpty
                                        ? 'Choose your character and name'
                                        : '${p.studentName} · ${p.studentCharacter == 'girl' ? 'Girl' : 'Boy'}'),
                                    trailing: const SettingsReferenceArrow(
                                        edit: true),
                                    onTap: withButtonSound(
                                        _opening ? null : _editCharacter))),
                            SettingsDisplayPanel(
                                child: ExpansionTile(
                                    expansionAnimationStyle: AnimationStyle(
                                        duration:
                                            MediaQuery.disableAnimationsOf(
                                                    context)
                                                ? Duration.zero
                                                : const Duration(
                                                    milliseconds: 200)),
                                    key: const PageStorageKey(
                                        'settings-display'),
                                    leading: const SettingsSoundIcon(
                                        Icons.text_fields_rounded),
                                    title: const Text('Display & Animations'),
                                    subtitle: const Text(
                                        'Text size and comfortable movement'),
                                    children: [
                                  Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Row(children: [
                                              ExcludeSemantics(
                                                  child: Icon(Icons.eco_rounded,
                                                      color: Color(0xFF73B735),
                                                      size: 17)),
                                              SizedBox(width: 6),
                                              Expanded(
                                                  child: Text('Text size',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color:
                                                              settingsSoundInk))),
                                            ]),
                                            const SizedBox(height: 8),
                                            SettingsTextSizeOptions(
                                                value: p.textSizeMultiplier,
                                                onSelected: (double value) {
                                                  unawaited(
                                                      p.setTextSizeMultiplier(
                                                          value));
                                                }),
                                            const SizedBox(height: 8),
                                            const SettingsDisplayPreview(),
                                          ])),
                                  const Divider(
                                      height: 12,
                                      indent: 12,
                                      endIndent: 12,
                                      color: Color(0xFFD8EBFC)),
                                  SwitchListTile(
                                      key: const ValueKey(
                                          'settings-reduced-animations'),
                                      title: const Row(children: [
                                        ExcludeSemantics(
                                            child: Icon(Icons.eco_rounded,
                                                color: Color(0xFF73B735),
                                                size: 17)),
                                        SizedBox(width: 6),
                                        Expanded(
                                            child: Text('Reduced Animations')),
                                      ]),
                                      subtitle: const Text(
                                          'Less movement for backgrounds and characters'),
                                      value: p.reducedAnimations,
                                      onChanged: withSelectionSound(
                                          p.setReducedAnimations)),
                                  const SettingsAnimationNote(),
                                ])),
                            _SettingsAction(
                                key: const ValueKey('settings-introduction'),
                                icon: Icons.auto_awesome_rounded,
                                title: 'Replay Introduction',
                                subtitle: 'Meet Lala and Lulu again',
                                onTap: _opening ? null : _replayIntroduction),
                            _SettingsAction(
                                key: const ValueKey('settings-help'),
                                icon: Icons.help_outline_rounded,
                                title: 'Help & Tutorials',
                                subtitle: 'Lessons, games, and microphone help',
                                onTap: _opening ? null : _showHelp),
                            _SettingsAction(
                                key: const ValueKey('settings-about'),
                                icon: Icons.info_outline_rounded,
                                title: 'About KidsPhonics',
                                subtitle:
                                    'App version, saved data, and credits',
                                onTap: _opening ? null : _showAbout),
                            _SettingsAction(
                                key: const ValueKey('settings-parent-controls'),
                                icon: Icons.lock_rounded,
                                title: 'Parent Controls',
                                subtitle:
                                    'Time limits, game access, PIN, and progress reset',
                                onTap: _opening
                                    ? null
                                    : () => navigateKidsTab(
                                        context, KidsDestination.parents)),
                          ]))));
  }
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SettingsReferenceCard(
      child: ListTile(
          leading: SettingsReferenceIcon(icon: icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const SettingsReferenceArrow(),
          onTap: withButtonSound(onTap)));
}
