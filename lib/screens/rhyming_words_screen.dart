import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rhyming_jar_controller.dart';
import '../data/game_session_order.dart';
import '../data/rhyming_jar_data.dart';
import '../models/difficulty.dart';
import '../providers/app_provider.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/game_instruction_guide.dart';
import '../widgets/rhyming_words_design.dart';

class RhymingWordsScreen extends StatefulWidget {
  const RhymingWordsScreen({super.key, this.difficulty = Difficulty.medium});
  final Difficulty difficulty;
  @override
  State<RhymingWordsScreen> createState() => _RhymingWordsScreenState();
}

class _RhymingWordsScreenState extends State<RhymingWordsScreen>
    with
        GameSessionUi<RhymingWordsScreen>,
        TickerProviderStateMixin,
        WidgetsBindingObserver {
  static const cloudAsset = 'assets/images/rhyming_jar/cloud.png';
  static const jarAsset = 'assets/images/rhyming_jar/jar.png';
  late final _motion = AnimationController(vsync: this);
  late final _float =
      AnimationController(vsync: this, duration: const Duration(seconds: 5));
  late List<RhymingFamily> _rounds = _newSession();
  late final _jar = RhymingJarController(_rounds.first);
  late List<String> _choices = rhymingChoices(_jar.family, widget.difficulty);
  int _index = 0, _speechRequest = 0;
  bool _foreground = true, _manualPause = false, _muted = false;
  bool _active = false, _voice = true, _started = false;
  bool _speechBusy = false;
  Offset _flightStart = Offset.zero;
  String? _highlight;
  List<RhymingFamily> _newSession() => GameSessionOrder.next(
      'rhyming-jar-${widget.difficulty.name}', rhymingFamilies, (f) => f.target,
      count: GameSessionOrder.roundLength(widget.difficulty));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _motion.addStatusListener((status) {
      if (status != AnimationStatus.completed || !_active) return;
      if (_jar.phase == JarPhase.centering) {
        _jar.setPhase(JarPhase.reveal);
        unawaited(_speakPhase());
      } else {
        _jar.finishFeedback();
        if (_jar.phase == JarPhase.centering) {
          _animate(const Duration(milliseconds: 950));
        }
      }
    });
    _jar.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _changed() {
    if (_jar.phase == JarPhase.choosing &&
        _active &&
        !MediaQuery.disableAnimationsOf(context)) {
      if (!_float.isAnimating) _float.repeat();
    } else {
      _float.stop();
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.watch<AppProvider>();
    ModalRoute.isCurrentOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
  }

  void _sync() {
    if (!mounted) return;
    final p = context.read<AppProvider>();
    final active = _foreground &&
        !_manualPause &&
        !resultOpen &&
        (ModalRoute.isCurrentOf(context) ?? true) &&
        p.gameAccess &&
        !p.timeLimitReached;
    final voice = p.voiceEnabled && !_muted;
    if (active == _active && voice == _voice && _started) return;
    _active = active;
    _voice = voice;
    _jar.paused = !active;
    _speechRequest++;
    _speechBusy = false;
    _highlight = null;
    unawaited(p.phonicsAudio.stop());
    if (!active) {
      _motion.stop();
      _float.stop();
      unawaited(p.audio.stop());
    } else {
      _started = true;
      if (_jar.phase == JarPhase.choosing &&
          !MediaQuery.disableAnimationsOf(context)) {
        _float.repeat();
      }
      if ([JarPhase.collecting, JarPhase.wrong, JarPhase.centering]
          .contains(_jar.phase)) {
        _motion.forward();
      } else {
        unawaited(_speakPhase());
      }
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  Future<void> _speakPhase() async {
    if (!_active || _speechBusy) return;
    final phase = _jar.phase;
    final key = switch (phase) {
      JarPhase.intro => 'rhyme-intro',
      JarPhase.target => rhymeWordKey(_jar.family.target),
      JarPhase.reveal => _jar.family.praiseKey,
      _ => null,
    };
    if (key == null) return;
    final request = ++_speechRequest;
    _speechBusy = true;
    setState(() {});
    if (_voice) {
      await context.read<AppProvider>().phonicsAudio.playInstruction(key);
    }
    if (!mounted || !_active || request != _speechRequest) return;
    _speechBusy = false;
    _jar.setPhase(switch (phase) {
      JarPhase.intro => JarPhase.target,
      JarPhase.target => JarPhase.choosing,
      _ => JarPhase.ready,
    });
    if (phase == JarPhase.intro) unawaited(_speakPhase());
  }

  void _animate(Duration duration) {
    _motion.duration = MediaQuery.disableAnimationsOf(context)
        ? const Duration(milliseconds: 100)
        : duration;
    _motion.forward(from: 0);
  }

  void _pick(String word, Offset center) {
    final correct = _jar.pick(word);
    if (correct == null) return;
    _flightStart = center;
    _highlight = null;
    recordGameAnswer(correct: correct);
    if (correct) {
      if (!_muted) unawaited(playGameCorrect());
      awardGameXp((8 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      _animate(const Duration(milliseconds: 800));
    } else {
      if (!_muted) unawaited(playGameWrong());
      _animate(const Duration(milliseconds: 500));
    }
  }

  Future<void> _replayWord(String word) async {
    if (!_active || _speechBusy || !_voice) return;
    final request = ++_speechRequest;
    _speechBusy = true;
    _highlight = word;
    setState(() {});
    await context
        .read<AppProvider>()
        .phonicsAudio
        .playInstruction(rhymeWordKey(word));
    if (!mounted || request != _speechRequest) return;
    setState(() {
      _speechBusy = false;
      _highlight = null;
    });
  }

  void _next() {
    if (_jar.phase != JarPhase.ready || _speechBusy || !_active) return;
    if (_index == _rounds.length - 1) {
      _showResults();
    } else {
      _index++;
      _jar.reset(_rounds[_index]);
      _choices = rhymingChoices(_jar.family, widget.difficulty);
      _motion.reset();
      _highlight = null;
      unawaited(_speakPhase());
    }
  }

  void _restart() {
    _speechRequest++;
    _rounds = _newSession();
    _index = 0;
    _speechBusy = false;
    _jar.reset(_rounds.first);
    _jar.setPhase(JarPhase.intro);
    _choices = rhymingChoices(_jar.family, widget.difficulty);
    _motion.reset();
    _sync();
  }

  void _showResults() {
    if (resultOpen) return;
    resultOpen = true;
    _sync();
    final p = context.read<AppProvider>();
    p.recordActivityCompleted();
    p.markRhymingWordsDone();
    awardGameXp((20 * widget.difficulty.xpMultiplier).round());
    if (!_muted) unawaited(p.audio.playWin());
    unawaited(showGameResult(_restart, backLabel: 'Back to Games'));
  }

  @override
  int get totalGameItems => _rounds.length * 3;
  @override
  void dispose() {
    _speechRequest++;
    WidgetsBinding.instance.removeObserver(this);
    _jar.removeListener(_changed);
    _jar.dispose();
    _motion.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
        title: 'Rhyming Words',
        instructions: 'Find three words that rhyme!',
        difficulty: widget.difficulty,
        current: _index + 1,
        total: _rounds.length,
        progressLabel: 'Jar',
        roundHeader: RhymingRoundHeader(
            difficulty: widget.difficulty,
            current: _index + 1,
            total: _rounds.length),
        fitViewport: true,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        canOpenTutorial: () => !_speechBusy && _jar.phase == JarPhase.choosing,
        onLeave: () {
          _manualPause = true;
          _sync();
        },
        instructionPanel: LayoutBuilder(builder: (_, bounds) {
          final controls = Row(mainAxisSize: MainAxisSize.min, children: [
            RhymingControlButton(
                label: _manualPause ? 'Resume' : 'Pause',
                purple: true,
                onPressed: () {
                  _manualPause = !_manualPause;
                  _sync();
                },
                icon: _manualPause
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded),
            const SizedBox(width: 8),
            RhymingControlButton(
                label: _muted ? 'Unmute' : 'Mute',
                onPressed: () {
                  setState(() => _muted = !_muted);
                  _sync();
                },
                icon: _muted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded),
          ]);
          const guide =
              GameInstructionGuide(gameTitle: 'Rhyming Words', autoPlay: false);
          // A full-width guide keeps the supplied recording's complete script
          // legible on narrow phones; the controls have their own 48px targets.
          return bounds.maxWidth < 340
              ? Column(children: [
                  guide,
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerRight, child: controls)
                ])
              : Row(children: [
                  const Expanded(child: guide),
                  const SizedBox(width: 8),
                  controls
                ]);
        }),
        child: LayoutBuilder(builder: (context, constraints) {
          final size = constraints.biggest;
          final centered = [JarPhase.centering, JarPhase.reveal, JarPhase.ready]
              .contains(_jar.phase);
          final revealed =
              [JarPhase.reveal, JarPhase.ready].contains(_jar.phase);
          final jarHeight = math.min(
              math.max(size.height * .30, RhymingTargetPanels.height),
              math.min(190.0, size.width * .46 / .96));
          final startRect = Rect.fromLTWH(0, 0, jarHeight * .96, jarHeight);
          final endHeight = math.min(size.height * .48, 290.0);
          final endRect = Rect.fromLTWH((size.width - endHeight * .96) / 2,
              size.height * .06, endHeight * .96, endHeight);
          final top = math.max(jarHeight, RhymingTargetPanels.height + 6) + 10;
          var columns = widget.difficulty == Difficulty.hard ? 3 : 2;
          if ((size.height - top) / (_choices.length / columns).ceil() < 60) {
            columns = 3;
          }
          final rows = (_choices.length / columns).ceil();
          final slotWidth = size.width / columns;
          final slotHeight = (size.height - top - 4) / rows;
          double choiceLeft(int index) {
            final row = index ~/ columns;
            final count = math.min(columns, _choices.length - row * columns);
            return (index % columns + (columns - count) / 2) * slotWidth;
          }

          return AnimatedBuilder(
              animation: Listenable.merge([_motion, _float]),
              builder: (context, _) {
                final t = Curves.easeInOutCubic.transform(_motion.value);
                final rect = _jar.phase == JarPhase.centering
                    ? Rect.lerp(startRect, endRect, t)!
                    : centered
                        ? endRect
                        : startRect;
                return Stack(clipBehavior: Clip.hardEdge, children: [
                  Positioned.fromRect(rect: rect, child: _jarPicture()),
                  if (!centered)
                    Positioned(
                        left: startRect.right + 8,
                        right: 0,
                        top: 8,
                        child: Align(
                            alignment: Alignment.topRight,
                            child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 280),
                                child: RhymingTargetPanels(
                                    word: _jar.family.target,
                                    collected: _jar.collected.length,
                                    onHear: _jar.canPick &&
                                            !_speechBusy &&
                                            _voice
                                        ? () => _replayWord(_jar.family.target)
                                        : null)))),
                  if (!centered)
                    for (var i = 0; i < _choices.length; i++)
                      if (!_jar.collected.contains(_choices[i]) &&
                          !(_jar.phase == JarPhase.collecting &&
                              _jar.picked == _choices[i]))
                        Positioned(
                            left: choiceLeft(i) + 3,
                            top: top + (i ~/ columns) * slotHeight + 3,
                            width: slotWidth - 6,
                            height: slotHeight - 6,
                            child: Transform.translate(
                                offset: Offset(
                                    _jar.phase == JarPhase.wrong &&
                                            _jar.picked == _choices[i]
                                        ? math.sin(_motion.value * math.pi * 6) *
                                            7
                                        : 0,
                                    _jar.canPick
                                        ? math.sin(_float.value * math.pi * 2 + i) *
                                            3
                                        : 0),
                                child: _cloud(
                                    _choices[i],
                                    () => _pick(_choices[i],
                                        Offset(choiceLeft(i) + slotWidth / 2, top + (i ~/ columns + .5) * slotHeight))))),
                  if (_jar.phase == JarPhase.collecting)
                    Positioned(
                        left:
                            Offset.lerp(_flightStart, startRect.center, t)!.dx -
                                17,
                        top:
                            Offset.lerp(_flightStart, startRect.center, t)!.dy -
                                17 -
                                math.sin(t * math.pi) * 35,
                        child: Transform.scale(
                            scale: 1 + math.sin(t * math.pi) * .4,
                            child: const Icon(Icons.auto_awesome,
                                color: Color(0xFFFFCE32), size: 34))),
                  if (revealed)
                    Positioned(
                        top: endRect.bottom + 6,
                        left: 4,
                        right: 4,
                        child: Column(children: [
                          Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final word in _jar.family.words)
                                  TweenAnimationBuilder<double>(
                                      key: ValueKey('rhyme-reveal-$word'),
                                      tween: Tween(begin: 0, end: 1),
                                      duration: MediaQuery.disableAnimationsOf(context)
                                          ? Duration.zero
                                          : const Duration(milliseconds: 500),
                                      builder: (context, value, child) => Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                              offset:
                                                  Offset(0, -35 * (1 - value)),
                                              child: Transform.scale(
                                                  scale: .6 + .4 * value,
                                                  child: child))),
                                      child: ActionChip(
                                          label: Text(word,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w900)),
                                          backgroundColor: word == _highlight
                                              ? Colors.amber
                                              : Colors.white,
                                          onPressed: _jar.phase == JarPhase.ready &&
                                                  !_speechBusy &&
                                                  _active
                                              ? () => _replayWord(word)
                                              : null))
                              ]),
                          const SizedBox(height: 8),
                          if (_jar.phase == JarPhase.ready)
                            FilledButton(
                                onPressed:
                                    _active && !_speechBusy ? _next : null,
                                child: Text(_index == _rounds.length - 1
                                    ? 'Finish'
                                    : 'Next Jar')),
                        ])),
                  if (!_active && !resultOpen)
                    Positioned.fill(child: RhymingPauseOverlay(onResume: () {
                      _manualPause = false;
                      _sync();
                    })),
                ]);
              });
        }),
      );
  Widget _cloud(String word, VoidCallback onTap) => Semantics(
      button: true,
      label: word,
      child: GestureDetector(
          onTap: _jar.canPick && !_speechBusy ? onTap : null,
          child: Stack(alignment: Alignment.center, children: [
            Image.asset(cloudAsset,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                excludeFromSemantics: true),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(word,
                        key: ValueKey('rhyme-choice-$word'),
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: _jar.phase == JarPhase.wrong &&
                                    _jar.picked == word
                                ? const Color(0xFFC34662)
                                : const Color(0xFF102254))))),
          ])));
  Widget _jarPicture() => LayoutBuilder(
      builder: (context, box) => Stack(children: [
            Positioned.fill(
                child: Image.asset(jarAsset,
                    fit: BoxFit.fill, excludeFromSemantics: true)),
            Positioned(
                left: box.maxWidth * .806,
                right: box.maxWidth * .135,
                top: box.maxHeight * .327,
                bottom: box.maxHeight * .249,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ColoredBox(
                        color: const Color(0xFFFFF4DA),
                        child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                                heightFactor: _jar.fill,
                                widthFactor: 1,
                                child: const ColoredBox(
                                    color: Color(0xFFFFCF24))))))),
            Positioned(
                left: box.maxWidth * .14,
                right: box.maxWidth * .34,
                bottom: box.maxHeight * .23,
                height: box.maxHeight * .45,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 350),
                            height: box.maxHeight * .45 * _jar.fill,
                            decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                  Color(0x66FFF39B),
                                  Color(0xDDFFCA28)
                                ])),
                            child: Center(
                                child: _jar.collected.isEmpty
                                    ? null
                                    : const Icon(Icons.auto_awesome,
                                        color: Colors.white, size: 24)))))),
          ]));
}
