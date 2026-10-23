import '../widgets/button_sound.dart';
import '../widgets/game_design.dart';
import '../data/game_session_order.dart';
import '../widgets/word_game_layout.dart';
import '../widgets/game_instruction_guide.dart';
import '../widgets/game_mascot_coach.dart';
import '../widgets/activity_round_header.dart';
import '../data/missing_vowel_sounds.dart';
import 'dart:async';
// lib/screens/missing_vowel_screen.dart
//
// Missing Vowel — shows a word with the vowel blanked out (C_T, D_G, S_N).
// Child taps the correct vowel to complete the word.
//
// Every difficulty offers A, E, I, O, U; word pools and rewards stay tiered.

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../data/phonics_activity_data.dart';
import '../providers/app_provider.dart';
import '../models/difficulty.dart';

import '../widgets/learner_widgets.dart';

class MissingVowelScreen extends StatefulWidget {
  final Difficulty difficulty;
  const MissingVowelScreen({super.key, this.difficulty = Difficulty.easy});

  @override
  State<MissingVowelScreen> createState() => _MissingVowelScreenState();
}

class _MissingVowelScreenState extends State<MissingVowelScreen>
    with GameSessionUi<MissingVowelScreen>, WidgetsBindingObserver {
  int _index = 0;
  String? _picked;
  bool _answered = false;
  bool _introFinished = false, _pendingSound = true, _reading = false;
  bool _soundScheduled = false;
  int _soundStep = 0, _soundRun = 0;
  Set<int> _glowing = {};
  Timer? _glowTimer;
  Completer<void>? _glowDone;

  late List<VowelPuzzle> _puzzles = _newSession();
  List<VowelPuzzle> _newSession() => GameSessionOrder.next(
      'missing_vowel-${widget.difficulty.name}',
      vowelPuzzlesFor(widget.difficulty),
      (item) => item.word,
      count: GameSessionOrder.roundLength(widget.difficulty));
  List<String> get _vowels => vowelChoicesFor(widget.difficulty, _puzzle.vowel);
  VowelPuzzle get _puzzle => _puzzles[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<AppProvider>();
    if (!canAdvanceGameFeedback || !provider.voiceEnabled) {
      _stopSounds(keepPending: true);
    }
    _scheduleSounds();
  }

  void _finishGlow() {
    _glowTimer?.cancel();
    final done = _glowDone;
    _glowDone = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  Future<void> _holdGlow() {
    _finishGlow();
    final done = Completer<void>();
    _glowDone = done;
    _glowTimer = Timer(const Duration(milliseconds: 350), _finishGlow);
    return done.future;
  }

  void _stopSounds({bool keepPending = false}) {
    _soundRun++;
    _finishGlow();
    gameNarration.cancel();
    _reading = false;
    _glowing = {};
    if (!keepPending) _pendingSound = false;
  }

  void _scheduleSounds() {
    if (_soundScheduled) return;
    _soundScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _soundScheduled = false;
      if (mounted) unawaited(_playSounds());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _introDone() {
    if (!mounted) return;
    _introFinished = true;
    _scheduleSounds();
  }

  Future<void> _playSounds() async {
    if (!_introFinished ||
        !_pendingSound ||
        _reading ||
        !canAdvanceGameFeedback ||
        !context.read<AppProvider>().voiceEnabled) {
      return;
    }
    final run = ++_soundRun;
    final steps = missingVowelSoundSteps(_puzzle.word);
    bool current() => mounted && run == _soundRun;
    setState(() => _reading = true);
    gameNarration.updateEnvironment(enabled: true, active: true);
    try {
      await context.read<AppProvider>().audio.stop();
      if (!current()) return;
      while (_soundStep < steps.length) {
        if (!canAdvanceGameFeedback || !gameNarration.enabled) return;
        final step = steps[_soundStep];
        setState(() => _glowing = step.positions.toSet());
        final hold = _holdGlow();
        final playback = gameNarration.word(step.phrase);
        final audioGeneration = gameNarration.generation;
        await playback;
        await hold;
        if (!current() ||
            !canAdvanceGameFeedback ||
            audioGeneration != gameNarration.generation) {
          return;
        }
        _soundStep++;
      }
      if (current()) _pendingSound = false;
    } finally {
      if (current()) {
        setState(() {
          _reading = false;
          _glowing = {};
        });
      }
    }
  }

  void _repeatSounds() {
    if (_reading || !canAdvanceGameFeedback) return;
    _stopSounds();
    _soundStep = 0;
    _pendingSound = true;
    unawaited(_playSounds());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      setState(() => _stopSounds(keepPending: true));
    } else {
      _scheduleSounds();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSounds();
    super.dispose();
  }

  void _pick(String vowel) async {
    if (_answered || _picked != null || resultOpen) return;
    _stopSounds();
    final isCorrect = vowel == _puzzle.vowel;
    setState(() {
      _picked = vowel;
    });

    recordGameAnswer(correct: isCorrect);
    if (isCorrect) {
      setState(() {
        _answered = true;
      });
      playGameCorrect();
      awardGameXp((8 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      await Future.delayed(const Duration(milliseconds: 700));
    } else {
      playGameWrong();
      await Future.delayed(const Duration(milliseconds: 700));
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _picked = null);
    }
  }

  void _next() {
    if (!_answered || resultOpen) return;
    if (_index < _puzzles.length - 1) {
      _stopSounds();
      setState(() {
        _index++;
        _picked = null;
        _answered = false;
        _soundStep = 0;
        _pendingSound = true;
      });
      _scheduleSounds();
    } else {
      _showResults();
    }
  }

  void _restart() => setState(() {
        _stopSounds();
        _index = 0;
        _puzzles = _newSession();
        _picked = null;
        _answered = false;
        _soundStep = 0;
        _pendingSound = true;
        _scheduleSounds();
      });

  void _showResults() {
    if (resultOpen) return;
    resultOpen = true;
    final provider = context.read<AppProvider>();
    provider.recordActivityCompleted();
    awardGameXp((15 * widget.difficulty.xpMultiplier).round());
    provider.audio.playWin();

    showGameResult(_restart, backLabel: 'Back to Games');
  }

  @override
  int get totalGameItems => _puzzles.length;

  @override
  Widget build(BuildContext context) => GameScaffold(
        narration: gameNarration,
        fitViewport: true,
        answerResult: _picked == null ? null : _picked == _puzzle.vowel,
        title: 'Missing Vowel',
        roundHeader: ActivityRoundHeader(
            difficulty: widget.difficulty,
            current: _index + 1,
            total: _puzzles.length,
            label: 'Question',
            fitLabels: true),
        instructions: 'Pick the missing vowel.',
        instructionPanel: GameMascotCoach(
            title: 'Missing Vowel',
            instructions: 'Pick the missing vowel.',
            controller: gameNarration,
            child: GameInstructionGuide(
                gameTitle: 'Missing Vowel', onFinished: _introDone)),
        difficulty: widget.difficulty,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        current: _index + 1,
        total: _puzzles.length,
        child: WordGameLayout(word: _puzzle.word, children: [
          const SizedBox(height: 4),
          ForestPanel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Semantics(
                  label: _puzzle.display,
                  child: ExcludeSemantics(
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            for (var i = 0; i < _puzzle.word.length; i++)
                              AnimatedContainer(
                                  key: ValueKey('vowel-sound-$i'),
                                  duration:
                                      MediaQuery.disableAnimationsOf(context)
                                          ? Duration.zero
                                          : const Duration(milliseconds: 140),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: _glowing.contains(i)
                                          ? const Color(0xFFFFE36B)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _glowing.contains(i)
                                          ? const [
                                              BoxShadow(
                                                  color: Color(0xBBFFD23F),
                                                  blurRadius: 10)
                                            ]
                                          : const []),
                                  child: Text(_puzzle.display.split(' ')[i],
                                      style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900)))
                          ]))))),
          const SizedBox(height: 8),
          AudioButton(
              label: 'Listen Again',
              controlBuilder: (context, onPlay, playing, label) =>
                  ForestAudioButton(
                      label: 'Listen Again',
                      icon: Icons.replay_rounded,
                      onPressed: onPlay == null || _reading || !_introFinished
                          ? null
                          : _repeatSounds),
              phrase:
                  _puzzle.word[0] + _puzzle.word.substring(1).toLowerCase()),
          const SizedBox(height: 8),
          WordChoiceGrid(
              children: _vowels
                  .map((option) => GameAnswerButton(
                      compact: true,
                      label: option,
                      selected: _picked == option,
                      result:
                          _picked == option ? option == _puzzle.vowel : null,
                      onPressed: _answered || _picked != null || resultOpen
                          ? null
                          : () => _pick(option)))
                  .toList()),
          if (_picked != null) GameFeedback(correct: _picked == _puzzle.vowel),
          if (_answered)
            ElevatedButton(
                onPressed: withButtonSound(resultOpen ? null : _next),
                child: const Text('Next')),
        ]),
      );
}
