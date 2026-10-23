import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/scene_voice_controller.dart';
import '../data/home_village.dart';
import '../data/updated_scene.dart';
import '../providers/app_provider.dart';
import '../theme/kids_ui.dart';
import '../widgets/scene_controls.dart';
import '../widgets/scene_dialogue.dart';
import '../widgets/school_home_scene.dart';
import '../widgets/student_character_picker.dart';
import '../widgets/cloud_page_route.dart';
import '../widgets/learner_widgets.dart';
import 'home_screen.dart';

/// First launch uses the Home scene without a student until setup is complete.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.replay = false});
  final bool replay;
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with WidgetsBindingObserver {
  SceneVoiceController? _voice;
  Timer? _opening, _stepFade;
  int _step = -1;
  bool _setup = false, _changing = false, _profileChosen = false;
  bool _foreground = true;
  bool _cloudsPrepared = false, _leaving = false;
  bool _titleComplete = false, _titlePlaying = false;
  bool _resumeIntroduction = false;
  int _titleRequest = 0;
  Animation<double>? _routeAnimation;
  // Replay stops before first-time character setup instructions.
  late final _introduction = widget.replay
      ? homeIntroduction.sublist(0, homeIntroduction.length - 1)
      : homeIntroduction;

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
    _voice ??= SceneVoiceController(context.read<AppProvider>(),
        isCurrent: () => mounted && (ModalRoute.isCurrentOf(context) ?? true),
        replayOnResume: false);
    final animation = ModalRoute.of(context)?.animation;
    if (_routeAnimation != animation) {
      _routeAnimation?.removeStatusListener(_routeStatus);
      _routeAnimation = animation;
      animation?.addStatusListener(_routeStatus);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startOpening();
      if (!_cloudsPrepared) {
        _cloudsPrepared = true;
        unawaited(
            prepareCloudTransition(context, cloudTransitionImages(context)));
      }
    });
  }

  void _routeStatus(AnimationStatus _) => _startOpening();

  void _startOpening() {
    if (_setup ||
        _leaving ||
        _step != -1 ||
        _opening != null ||
        !_foreground ||
        !mounted ||
        !(ModalRoute.isCurrentOf(context) ?? true) ||
        (_routeAnimation != null && !_routeAnimation!.isCompleted)) {
      return;
    }
    if (!context.read<AppProvider>().voiceEnabled) _titleComplete = true;
    if (!_titleComplete) {
      if (!_titlePlaying) unawaited(_announceTitle());
      return;
    }
    _opening = Timer(const Duration(milliseconds: 1500), () {
      _opening = null;
      if (!mounted || !_foreground) return;
      setState(() => _step = 0);
      unawaited(_voice!.play(_introduction.first.phrase));
    });
  }

  Future<void> _announceTitle() async {
    final request = ++_titleRequest;
    _titlePlaying = true;
    await _voice!.play('home-title');
    if (!mounted || request != _titleRequest) return;
    _titlePlaying = false;
    if (!_foreground || !(ModalRoute.isCurrentOf(context) ?? true)) return;
    _titleComplete = true;
    // Preserve the short pause before Lala, after the chorus has finished.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startOpening());
  }

  void _next() {
    if (_changing ||
        _setup ||
        _leaving ||
        !_foreground ||
        !(ModalRoute.isCurrentOf(context) ?? true)) {
      return;
    }
    if (widget.replay && _step == _introduction.length - 1) {
      _finishReplay();
      return;
    }
    _opening?.cancel();
    _opening = null;
    _stepFade?.cancel();
    _titleRequest++;
    _titlePlaying = false;
    _titleComplete = true;
    _resumeIntroduction = false;
    _voice!.stop();
    setState(() {
      _changing = true;
      if (_step == _introduction.length - 1) {
        _setup = true;
      } else {
        _step++;
      }
    });
    _stepFade = Timer(
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() => _changing = false);
      unawaited(_voice!.play(_setup
          ? profileIntroduction.first.phrase
          : _introduction[_step].phrase));
    });
  }

  void _skip() {
    if (_setup || _leaving || !_foreground) return;
    if (widget.replay) {
      _finishReplay();
      return;
    }
    _opening?.cancel();
    _opening = null;
    _stepFade?.cancel();
    _titleRequest++;
    _voice!.stop();
    setState(() {
      _titlePlaying = false;
      _titleComplete = true;
      _resumeIntroduction = false;
      _changing = false;
      _setup = true;
    });
    unawaited(_voice!.play(profileIntroduction.first.phrase));
  }

  void _finishReplay() {
    if (_leaving) return;
    _opening?.cancel();
    _stepFade?.cancel();
    _titleRequest++;
    _titlePlaying = false;
    _resumeIntroduction = false;
    setState(() => _leaving = true);
    _voice!.stop();
    Navigator.of(context).pop();
  }

  void _choose(String _) {
    if (_profileChosen) return;
    _profileChosen = true;
    setState(() {});
    unawaited(_voice!.play(profileIntroduction.last.phrase));
  }

  void _saved() {
    if (_leaving) return;
    setState(() => _leaving = true);
    _voice!.stop();
    unawaited(LearnerNavigation.open(context, const HomeScreen(),
        replace: true, cloudTransition: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _resumeIntroduction = _resumeIntroduction ||
          (_titleComplete && _step >= 0 && (_voice?.playing ?? false));
      _titleRequest++;
      _titlePlaying = false;
      _opening?.cancel();
      _opening = null;
    } else {
      // Allow the voice controller to receive the resume event first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_foreground) return;
        if (_step < 0) {
          _startOpening();
        } else if (_resumeIntroduction && !_changing && !_leaving) {
          _resumeIntroduction = false;
          unawaited(_voice!.play(_setup
              ? profileIntroduction[_profileChosen ? 1 : 0].phrase
              : _introduction[_step].phrase));
        }
      });
    }
  }

  @override
  void dispose() {
    _opening?.cancel();
    _stepFade?.cancel();
    _routeAnimation?.removeStatusListener(_routeStatus);
    _voice?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final dialogue = _step < 0 ? null : _introduction[_step];
    return Theme(
        data: KidsUi.theme,
        child: PopScope(
            canPop: widget.replay,
            child: Scaffold(
                backgroundColor: const Color(0xFFF6CC8C),
                resizeToAvoidBottomInset: false,
                body: ListenableBuilder(
                    listenable: _voice!,
                    builder: (_, __) => Stack(fit: StackFit.expand, children: [
                          SchoolHomeScene(
                              character: p.studentCharacter,
                              name: '',
                              letter: p.recommendedAdventureLetter,
                              progressLabel: '',
                              level: p.level,
                              stars: p.stars,
                              xp: p.xp,
                              streak: p.streak,
                              gameAccess: true,
                              busy: true,
                              visit: const AlwaysStoppedAnimation(0),
                              showStudent: false,
                              introduction: true,
                              showGuideArrow:
                                  !_setup && (_step == 2 || _step == 7),
                              dialogueSpeaker: dialogue == null
                                  ? null
                                  : dialogue.games
                                      ? HomeCategory.games
                                      : HomeCategory.lessons,
                              speakingMascot:
                                  !_setup && _voice!.playing && dialogue != null
                                      ? (dialogue.games
                                          ? HomeCategory.games
                                          : HomeCategory.lessons)
                                      : null,
                              onSelect: (_) {},
                              onCharacter: () {},
                              onSettings: () {},
                              onContinue: () {},
                              dialogue: !_setup && dialogue != null
                                  ? AnimatedSwitcher(
                                      duration: MediaQuery.disableAnimationsOf(
                                              context)
                                          ? Duration.zero
                                          : const Duration(milliseconds: 180),
                                      child: SceneDialogue(
                                          key: ValueKey(dialogue.phrase),
                                          text: dialogue.text,
                                          introduction: true,
                                          art:
                                              'dialogue_box_${dialogue.games ? 1 : 2}.png',
                                          flip: dialogue.games))
                                  : null,
                              dialogueControls: !_setup
                                  ? _IntroductionControls(
                                      step: _step,
                                      stepCount: _introduction.length,
                                      replay: widget.replay,
                                      playing: _voice!.playing,
                                      voiceEnabled: p.voiceEnabled,
                                      onSkip: _foreground && !_leaving
                                          ? _skip
                                          : null,
                                      onReplay: dialogue == null ||
                                              _voice!.playing ||
                                              _changing ||
                                              !p.voiceEnabled
                                          ? null
                                          : () => unawaited(
                                              _voice!.play(dialogue.phrase)),
                                      onNext:
                                          !_foreground || _leaving || _changing
                                              ? null
                                              : _next)
                                  : null),
                          if (_setup) ...[
                            const ColoredBox(color: Color(0x550C1D45)),
                            SafeArea(
                                child: Center(
                                    child: StudentCharacterPicker(
                                        firstSetup: true,
                                        onSaved: _saved,
                                        onCharacterSelected: _choose,
                                        canSave: !_voice!.playing &&
                                            !_changing &&
                                            !_leaving,
                                        isReadyToSave: () =>
                                            !_voice!.playing &&
                                            !_changing &&
                                            _foreground &&
                                            !_leaving,
                                        canSelect:
                                            !_voice!.playing && !_changing,
                                        setupDialogue: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                  profileIntroduction[
                                                          _profileChosen
                                                              ? 1
                                                              : 0]
                                                      .text,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          Color(0xFF633012))),
                                              IconButton(
                                                  tooltip:
                                                      'Replay setup instruction',
                                                  onPressed: _voice!.playing ||
                                                          !p.voiceEnabled
                                                      ? null
                                                      : () => unawaited(_voice!
                                                          .play(profileIntroduction[
                                                                  _profileChosen
                                                                      ? 1
                                                                      : 0]
                                                              .phrase)),
                                                  icon: const Icon(
                                                      Icons.volume_up_rounded)),
                                            ])))),
                          ],
                        ])))));
  }
}

/// Intro-only controls; skipping still requires character and name setup.
class _IntroductionControls extends StatelessWidget {
  const _IntroductionControls(
      {required this.step,
      required this.stepCount,
      required this.replay,
      required this.playing,
      required this.voiceEnabled,
      required this.onSkip,
      required this.onReplay,
      required this.onNext});
  final int step, stepCount;
  final bool playing, voiceEnabled, replay;
  final VoidCallback? onSkip, onReplay, onNext;

  ButtonStyle _buttonStyle(Color background, Color foreground) =>
      ElevatedButton.styleFrom(
          backgroundColor: background,
          disabledBackgroundColor: background,
          foregroundColor: foreground,
          disabledForegroundColor: foreground,
          minimumSize: const Size(48, 64),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 6,
          shadowColor: const Color(0x88633012),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
              side: const BorderSide(color: Color(0xFFE9AC57), width: 2)));

  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
            child: SceneButton(
                key: const ValueKey('welcome-skip'),
                label: 'Skip',
                icon: Icons.skip_next_rounded,
                filled: true,
                fontSize: 24,
                style: _buttonStyle(
                    const Color(0xFFFFF0D8), const Color(0xFF7445C7)),
                onPressed: onSkip)),
        const SizedBox(width: 4),
        SizedBox(
            width: 54,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(
                  height: 36,
                  width: 40,
                  child: IconButton(
                      key: const ValueKey('welcome-replay'),
                      padding: EdgeInsets.zero,
                      tooltip: 'Replay introduction',
                      onPressed: onReplay,
                      icon: Icon(
                          playing
                              ? Icons.graphic_eq_rounded
                              : voiceEnabled
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                          color: const Color(0xFF713216)))),
              Semantics(
                  label: step < 0
                      ? 'Introduction'
                      : 'Introduction ${step + 1} of $stepCount',
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var index = 0; index < 3; index++)
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index == (step < 5 ? 0 : 1)
                                          ? const Color(0xFFFFD234)
                                          : const Color(0xFFCB9C72),
                                      border: Border.all(
                                          color: const Color(0xFF985426))))),
                      ])),
            ])),
        const SizedBox(width: 4),
        Expanded(
            child: SceneButton(
                key: const ValueKey('welcome-next'),
                label: step == stepCount - 1
                    ? (replay ? 'Done' : 'Get Started')
                    : 'Next',
                icon: Icons.arrow_forward_rounded,
                iconAfter: true,
                filled: true,
                fontSize: 24,
                style: _buttonStyle(
                    const Color(0xFFFFD441), const Color(0xFF633012)),
                onPressed: onNext)),
      ]);
}
