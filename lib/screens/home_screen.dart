import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/kids_ui.dart';
import '../widgets/adventure_background.dart';
import '../widgets/home_flight_menu.dart';
import '../widgets/learner_widgets.dart';
import 'games_screen.dart';
import 'lessons_screen.dart';
import 'parent_screen.dart';
import 'progress_screen.dart';
import 'letter_mastery_check_screen.dart';
import '../data/letter_data.dart';

import '../widgets/home_recommendation_panel.dart';
import '../widgets/quick_check_recommendation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _entrance = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3600));
  bool _foreground = true;
  bool _introQueued = false;
  int _voiceRequest = 0;
  AppProvider? _provider;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.watch<AppProvider>();
    _syncEntrance();
    final current = ModalRoute.isCurrentOf(context) ?? true;
    // A muted opening must not become a delayed intro when voice is enabled.
    if (current && !_provider!.voiceEnabled) _introQueued = true;
    if (!_foreground ||
        !_provider!.voiceEnabled ||
        _provider!.timeLimitReached) {
      _stopHomeVoice();
    } else if (!current) {
      if (_provider!.phonicsAudio.currentPhrase == 'home-intro') {
        _stopHomeVoice();
      }
    } else if (!_introQueued) {
      _introQueued = true;
      final request = _voiceRequest;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && request == _voiceRequest) unawaited(_playVoice('intro'));
      });
    }
  }

  void _stopHomeVoice() {
    _voiceRequest++;
    final audio = _provider?.phonicsAudio;
    if (audio?.currentPhrase?.startsWith('home-') ?? false) {
      unawaited(audio!.stop());
    }
  }

  Future<void> _playVoice(String name) async {
    final p = _provider!;
    final request = ++_voiceRequest;
    await p.ready;
    bool active() =>
        mounted &&
        _foreground &&
        request == _voiceRequest &&
        p.voiceEnabled &&
        !p.timeLimitReached;
    if (!active()) return;
    await p.audio.stop();
    if (!active()) return;
    await p.phonicsAudio.playInstruction('home-$name');
  }

  void _skipIntro() {
    _introQueued = true;
    _stopHomeVoice();
    _entrance.value = 1;
  }

  void _syncEntrance() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_foreground && TickerMode.valuesOf(context).enabled) {
      if (_entrance.value < 1 && !_entrance.isAnimating) _entrance.forward();
    } else {
      _entrance.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _stopHomeVoice();
    _syncEntrance();
  }

  void _open(Widget screen, {String? voice}) {
    _skipIntro();
    if (voice != null) unawaited(_playVoice(voice));
    LearnerNavigation.open(context, screen, cloudTransition: true);
  }

  @override
  void dispose() {
    _stopHomeVoice();
    WidgetsBinding.instance.removeObserver(this);
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final next = p.recommendedAdventureLetter;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Theme(
        data: KidsUi.theme,
        child: Scaffold(
            body: AdventureBackground(
                child: SafeArea(
                    child: Stack(children: [
          LayoutBuilder(
              builder: (_, box) => SingleChildScrollView(
                  child: Center(
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: 520, minHeight: box.maxHeight),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                HomeFlightMenu(
                                    entrance: _entrance,
                                    minHeight: box.maxHeight - 180 * scale,
                                    onLessons: () => _open(
                                        const LessonsScreen(),
                                        voice: 'lessons'),
                                    onGames: p.gameAccess
                                        ? () => _open(const GamesScreen(),
                                            voice: 'games')
                                        : null,
                                    onProgress: () => _open(
                                        const ProgressScreen(),
                                        voice: 'progress'),
                                    onParents: () => _open(const ParentScreen(),
                                        voice: 'parents')),
                                Padding(
                                    key: const ValueKey('home-footer'),
                                    padding: const EdgeInsets.fromLTRB(
                                        14, 6, 14, 14),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          HomeEntrance(
                                              animation: _entrance,
                                              begin: .56,
                                              end: .82,
                                              child: QuickCheckRecommendation(
                                                  onStart: () => _open(
                                                      LetterMasteryCheckScreen(
                                                          letter: letterContent(
                                                              next ?? 'A'))))),
                                          const SizedBox(height: 8),
                                          LayoutBuilder(builder: (_, badgeBox) {
                                            final badges = [
                                              (
                                                Icons.emoji_events_rounded,
                                                'Level ${p.level}',
                                                const Color(0xFF99500E)
                                              ),
                                              (
                                                Icons.bolt_rounded,
                                                '${p.xp} XP',
                                                const Color(0xFF682DAE)
                                              ),
                                              (
                                                Icons.star_rounded,
                                                '${p.stars} Stars',
                                                const Color(0xFF1468AF)
                                              ),
                                              (
                                                Icons
                                                    .local_fire_department_rounded,
                                                '${p.streak} Day Streak',
                                                const Color(0xFFC33D30)
                                              ),
                                            ];
                                            return Wrap(
                                                alignment: WrapAlignment.center,
                                                spacing: 6,
                                                runSpacing: 6,
                                                children: [
                                                  for (var i = 0;
                                                      i < badges.length;
                                                      i++)
                                                    SizedBox(
                                                        height: scale > 1.3
                                                            ? null
                                                            : 40,
                                                        width: scale > 1.3
                                                            ? badgeBox.maxWidth
                                                            : (badgeBox.maxWidth -
                                                                    18) /
                                                                4,
                                                        child: HomeEntrance(
                                                            animation:
                                                                _entrance,
                                                            begin:
                                                                .72 + i * .04,
                                                            end: .88 + i * .04,
                                                            child: HomeStatusBadge(
                                                                compact: true,
                                                                icon: badges[i]
                                                                    .$1,
                                                                label: badges[i]
                                                                    .$2,
                                                                color: badges[i]
                                                                    .$3)))
                                                ]);
                                          }),
                                        ])),
                              ]))))),
          Positioned(
              top: 4,
              right: 8,
              child: AnimatedBuilder(
                  animation: _entrance,
                  builder: (_, child) => _entrance.value < 1
                      ? TextButton(
                          key: const ValueKey('home-skip-intro'),
                          style: TextButton.styleFrom(
                              backgroundColor: const Color(0xDDFFFFFF),
                              foregroundColor: const Color(0xFF58269D),
                              minimumSize: const Size(64, 48)),
                          onPressed: _skipIntro,
                          child: const Text('Skip intro'))
                      : const SizedBox.shrink())),
        ])))));
  }
}
