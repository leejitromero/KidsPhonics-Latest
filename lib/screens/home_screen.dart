import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/scene_voice_controller.dart';
import '../data/home_village.dart';
import '../data/home_narration.dart';
import '../data/letter_data.dart';
import '../data/updated_scene.dart';
import '../providers/app_provider.dart';
import '../theme/kids_ui.dart';
import '../widgets/day_cycle_background.dart';
import '../widgets/home_character_visit.dart';
import '../widgets/cloud_page_route.dart';
import '../widgets/kids_navigation_bar.dart';
import '../widgets/main_navigation_scope.dart';
import '../widgets/main_navigation_shell.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/scene_dialogue.dart';
import '../widgets/school_home_scene.dart';
import '../widgets/student_character_picker.dart';
import '../widgets/student_wave.dart';
import 'games_screen.dart';
import 'lessons_screen.dart';
import 'parent_screen.dart';
import 'progress_screen.dart';
import 'letter_mastery_check_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.announceTitle = false});
  // Only loading requests the opening cue; returning from a room does not.
  final bool announceTitle;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _visit = AnimationController(
      vsync: this, duration: HomeCharacterVisitTiming.duration);
  SceneVoiceController? _voice;
  AppProvider? _provider;
  HomeCategory? _selected;
  bool _navigating = false, _foreground = true;
  int _visitRequest = 0;
  String? _preparedCharacter;
  Timer? _idleTimer;
  final _navigation = GlobalKey<MainNavigationShellState>();
  bool _tabActive = true;
  Animation<double>? _routeAnimation;
  Animation<double>? _secondaryAnimation;
  bool _idlePromptPlayed = false, _idlePromptSpeaking = false;
  int _girlPromptIndex = 0;
  int _boyPromptIndex = 0;
  String _idlePromptText = '';
  bool _wasCurrent = false;
  bool _titleComplete = false, _titleSpeaking = false;
  int _titleRequest = 0;
  bool get _openingTitle => widget.announceTitle && !_titleComplete;
  bool get _busy => _selected != null || _navigating || _openingTitle;
  bool get _current =>
      mounted &&
      _foreground &&
      _tabActive &&
      (ModalRoute.isCurrentOf(context) ?? true);

  void _tabChanged(KidsDestination destination) {
    setState(() => _tabActive = destination == KidsDestination.home);
    if (!_tabActive) {
      _cancelIdlePrompt(stopVoice: true);
      _voice?.stop();
      _cancelVisit();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIdleRoute());
  }

  Future<void> _selectTab(KidsDestination destination) async {
    if (_busy || !_provider!.isReady) return;
    _cancelIdlePrompt(stopVoice: true);
    await _navigation.currentState?.select(destination);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  int get _decodeWidth => (MediaQuery.sizeOf(context).width *
          MediaQuery.devicePixelRatioOf(context))
      .ceil()
      .clamp(1, 512);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = _provider = context.watch<AppProvider>();
    _voice ??= SceneVoiceController(p,
        isCurrent: () => _current, replayOnResume: false);
    final animation = ModalRoute.of(context)?.animation;
    if (_routeAnimation != animation) {
      _routeAnimation?.removeStatusListener(_routeStatus);
      _routeAnimation = animation;
      animation?.addStatusListener(_routeStatus);
    }
    final secondary = ModalRoute.of(context)?.secondaryAnimation;
    if (_secondaryAnimation != secondary) {
      _secondaryAnimation?.removeStatusListener(_routeStatus);
      _secondaryAnimation = secondary;
      secondary?.addStatusListener(_routeStatus);
    }
    if (_preparedCharacter != p.studentCharacter) {
      _preparedCharacter = p.studentCharacter;
      unawaited(precacheImage(
          ResizeImage(AssetImage(StudentWave.assetFor(p.studentCharacter)),
              width: 2172),
          context,
          onError: (_, __) {}));
      for (final asset in [
        '$sceneAssets/${p.studentCharacter}_1.png',
        ...studentWalkingFrames(p.studentCharacter, left: true),
        ...studentWalkingFrames(p.studentCharacter, left: false),
      ]) {
        unawaited(precacheImage(
            ResizeImage(AssetImage(asset), width: _decodeWidth), context,
            onError: (_, __) {}));
      }
    }
    if (!_foreground ||
        (!(ModalRoute.isCurrentOf(context) ?? true) && !_navigating) ||
        p.timeLimitReached ||
        (_selected == HomeCategory.games && !p.gameAccess)) {
      _cancelVisit();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIdleRoute());
  }

  void _routeStatus(AnimationStatus _) => _syncIdleRoute();

  void _syncIdleRoute() {
    if (!mounted) return;
    if (!_current) {
      _wasCurrent = false;
      _cancelIdlePrompt(stopVoice: true);
      return;
    }
    if (!_wasCurrent) _idlePromptPlayed = false;
    _wasCurrent = true;
    if (_openingTitle) {
      if (!_titleSpeaking &&
          _provider!.isReady &&
          (_routeAnimation == null || _routeAnimation!.isCompleted) &&
          (_secondaryAnimation == null || _secondaryAnimation!.isDismissed)) {
        unawaited(_announceTitle());
      }
      return;
    }
    _scheduleIdlePrompt();
  }

  Future<void> _announceTitle() async {
    final request = ++_titleRequest;
    _titleSpeaking = true;
    await _voice!.play('home-title');
    if (!mounted || request != _titleRequest) return;
    _titleSpeaking = false;
    if (!_current) return;
    setState(() => _titleComplete = true);
    // The idle greeting has its own countdown after the chorus completes.
    _syncIdleRoute();
  }

  bool get _canPrompt =>
      _current &&
      !_busy &&
      _provider!.isReady &&
      _provider!.voiceEnabled &&
      !_provider!.timeLimitReached &&
      !_idlePromptPlayed &&
      !_voice!.playing &&
      (_routeAnimation == null || _routeAnimation!.isCompleted) &&
      (_secondaryAnimation == null || _secondaryAnimation!.isDismissed);

  void _scheduleIdlePrompt({Duration delay = const Duration(seconds: 5)}) {
    if (!mounted) return;
    if (!_canPrompt) {
      _idleTimer?.cancel();
      _idleTimer = null;
      return;
    }
    _idleTimer ??= Timer(delay, () {
      _idleTimer = null;
      unawaited(_playIdlePrompt());
    });
  }

  Future<void> _playIdlePrompt() async {
    if (!_canPrompt) return;
    // Another owned sound may still be finishing; never interrupt it.
    if (_provider!.phonicsAudio.currentPhrase != null) {
      _scheduleIdlePrompt(delay: const Duration(seconds: 1));
      return;
    }
    final girl = _provider!.studentCharacter == 'girl';
    final prompt = girl
        ? girlAutomaticPrompts[_girlPromptIndex]
        : boyAutomaticPrompts[_boyPromptIndex];
    setState(() {
      _idlePromptPlayed = true;
      _idlePromptSpeaking = true;
      _idlePromptText = prompt.text;
      if (girl) {
        _girlPromptIndex = (_girlPromptIndex + 1) % girlAutomaticPrompts.length;
      } else {
        _boyPromptIndex = (_boyPromptIndex + 1) % boyAutomaticPrompts.length;
      }
    });
    await _voice!.play(prompt.phrase);
    if (mounted && _idlePromptSpeaking) {
      setState(() => _idlePromptSpeaking = false);
    }
  }

  void _cancelIdlePrompt({bool stopVoice = false}) {
    _idleTimer?.cancel();
    _idleTimer = null;
    if (stopVoice && _idlePromptSpeaking) {
      _idlePromptSpeaking = false;
      _voice?.stop();
    }
  }

  void _interact(PointerDownEvent _) {
    _cancelIdlePrompt(stopVoice: true);
    _scheduleIdlePrompt();
  }

  void _cancelVisit() {
    if (_selected == null) return;
    _visitRequest++;
    _voice?.stop();
    _visit.stop(canceled: true);
    setState(() => _selected = null);
    _visit.value = 0;
  }

  bool _canEnter(HomeCategory category) =>
      _current &&
      !_provider!.timeLimitReached &&
      (category != HomeCategory.games || _provider!.gameAccess);

  Future<void> _selectCategory(
      BuildContext navigationContext, HomeCategory category) async {
    final p = _provider!;
    if (_busy || !p.isReady || !_canEnter(category)) return;
    if (!category.hasHouse) {
      await _selectTab(category == HomeCategory.progress
          ? KidsDestination.progress
          : KidsDestination.parents);
      return;
    }
    _cancelIdlePrompt(stopVoice: true);
    final request = ++_visitRequest;
    setState(() => _selected = category);
    if (category.hasHouse) {
      if (!MediaQuery.disableAnimationsOf(context)) {
        unawaited(
            prepareCloudTransition(context, cloudTransitionImages(context)));
      }
      // Destination skies warm in the cache while the student speaks and walks.
      for (final asset in DayCycleBackground.framesFor(
          category == HomeCategory.lessons ? 'lesson' : 'games')) {
        unawaited(precacheImage(
            ResizeImage(AssetImage(asset),
                width: (MediaQuery.sizeOf(context).width *
                        MediaQuery.devicePixelRatioOf(context))
                    .ceil()
                    .clamp(1, 942)),
            context,
            onError: (_, __) {}));
      }
      await _voice!.play(
          'home-${p.studentCharacter}-${category == HomeCategory.lessons ? 'learn' : 'play'}');
    }
    if (!mounted || request != _visitRequest || !_canEnter(category)) return;
    if (category.hasHouse && !MediaQuery.disableAnimationsOf(context)) {
      try {
        await _visit.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted || request != _visitRequest || !_canEnter(category)) return;
    if (!navigationContext.mounted) return;
    setState(() => _navigating = true);
    await LearnerNavigation.open(navigationContext, _destination(category),
        fadeTransition: !category.hasHouse,
        cloudTransition: category.hasHouse,
        curtainDuration: HomeCharacterVisitTiming.curtain);
    if (!mounted) return;
    _cancelVisit();
    setState(() => _navigating = false);
    _syncIdleRoute();
  }

  Widget _destination(HomeCategory category) => switch (category) {
        HomeCategory.lessons => const LessonsScreen(),
        HomeCategory.games => const GamesScreen(),
        HomeCategory.progress => const ProgressScreen(),
        HomeCategory.parents => const ParentScreen(),
      };

  Future<void> _continueLearning(BuildContext navigationContext) async {
    if (_busy ||
        !_provider!.isReady ||
        !_current ||
        _provider!.timeLimitReached) {
      return;
    }
    _cancelIdlePrompt(stopVoice: true);
    setState(() => _navigating = true);
    await LearnerNavigation.open(
        navigationContext,
        LetterMasteryCheckScreen(
            letter:
                letterContent(_provider!.recommendedAdventureLetter ?? 'A')),
        cloudTransition: true);
    if (mounted) {
      setState(() => _navigating = false);
      _syncIdleRoute();
    }
  }

  Future<void> _editCharacter() async {
    if (_busy || !_provider!.isReady || !_current) return;
    _cancelIdlePrompt(stopVoice: true);
    setState(() => _navigating = true);
    await showDialog<void>(
        context: context, builder: (_) => const StudentCharacterPicker());
    if (mounted) {
      setState(() => _navigating = false);
      _syncIdleRoute();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _titleRequest++;
      _titleSpeaking = false;
      _cancelIdlePrompt(stopVoice: true);
      _wasCurrent = false;
      _cancelVisit();
    } else {
      // Let the voice controller receive the resume event before playing.
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncIdleRoute());
    }
  }

  @override
  void dispose() {
    _titleRequest++;
    _visitRequest++;
    _idleTimer?.cancel();
    _routeAnimation?.removeStatusListener(_routeStatus);
    _secondaryAnimation?.removeStatusListener(_routeStatus);
    _voice?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _visit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return MainNavigationShell(
        key: _navigation,
        onChanged: _tabChanged,
        navigationBuilder: (navigationContext) => KidsNavigationBar(
            current: MainNavigationScope.maybeOf(navigationContext)!.current,
            enabled: (!_tabActive || !_busy) && p.isReady,
            onSelected: _selectTab),
        homeBuilder: (navigationContext) => Theme(
            data: KidsUi.theme,
            child: Scaffold(
                backgroundColor: const Color(0xFFF6CC8C),
                resizeToAvoidBottomInset: false,
                body: Listener(
                    onPointerDown: _interact,
                    behavior: HitTestBehavior.translucent,
                    child: ListenableBuilder(
                        listenable: _voice!,
                        builder: (_, __) => SchoolHomeScene(
                            character: p.studentCharacter,
                            name: p.studentName,
                            letter: p.recommendedAdventureLetter,
                            progressLabel: '',
                            level: p.level,
                            stars: p.stars,
                            xp: p.xp,
                            streak: p.streak,
                            gameAccess: p.gameAccess,
                            busy: _busy || !p.isReady,
                            visit: _visit,
                            selected: _selected,
                            reserveNavigation: true,
                            studentSpeech: _voice!.playing &&
                                    (_idlePromptSpeaking ||
                                        (_selected?.hasHouse ?? false))
                                ? SceneDialogue(
                                    text: _idlePromptSpeaking
                                        ? _idlePromptText
                                        : _selected == HomeCategory.lessons
                                            ? 'Let’s learn!'
                                            : 'Let’s play!',
                                    art:
                                        'dialogue_box_${p.studentCharacter == 'girl' ? 4 : 1}.png')
                                : null,
                            onSelect: (category) => unawaited(
                                _selectCategory(navigationContext, category)),
                            onCharacter: () => unawaited(_editCharacter()),
                            onSettings: () => unawaited(_editCharacter()),
                            onContinue: () => unawaited(
                                _continueLearning(navigationContext))))))));
  }
}
