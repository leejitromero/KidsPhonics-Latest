import 'dart:async';
import '../widgets/game_feedback_art.dart';

import '../data/game_session_order.dart';
import '../widgets/word_game_layout.dart';
import '../widgets/game_design.dart';
import '../widgets/game_instruction_guide.dart';
import '../widgets/game_mascot_coach.dart';
// lib/screens/word_builder_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:provider/provider.dart';

import '../data/phonics_activity_data.dart';
import '../providers/app_provider.dart';

import '../models/difficulty.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/game_tutorial.dart';

class WordBuilderScreen extends StatefulWidget {
  final Difficulty difficulty;
  const WordBuilderScreen({super.key, this.difficulty = Difficulty.medium});
  @override
  State<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends State<WordBuilderScreen>
    with SingleTickerProviderStateMixin, GameSessionUi<WordBuilderScreen> {
  int _puzzleIndex = 0;
  bool? _feedback;

  // For multi-blank: track which blank is currently being filled (0-based)
  int _activeBlankIndex = 0;
  // Filled answers so far — index = blank slot index
  late List<String?> _filledAnswers;

  bool _busy = false;
  bool _allCorrect = false; // true when all blanks filled correctly
  final _choiceKeys = <String, GlobalKey>{};
  final _slotKeys = <int, GlobalKey>{};
  late final AnimationController _flight;
  OverlayEntry? _flightEntry;
  Timer? _feedbackTimer;

  late List<WordPuzzle> _activePuzzles = _newSession();
  List<WordPuzzle> _newSession() => GameSessionOrder.next(
      'word_builder-${widget.difficulty.name}',
      wordPuzzlesForDifficulty(widget.difficulty),
      (item) => item.word,
      count: GameSessionOrder.roundLength(widget.difficulty));
  WordPuzzle get _puzzle => _activePuzzles[_puzzleIndex];
  late List<String> _shuffledTiles;

  int get _blankCount => _puzzle.correctLetters.length;
  String get _instruction =>
      'Fill in ${_blankCount == 1 ? 'the blank' : 'the blanks'} to make ${_puzzle.word}!';

  @override
  void initState() {
    super.initState();
    _flight = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _initPuzzle();
  }

  void _initPuzzle() {
    _busy = false;
    _activeBlankIndex = 0;
    _filledAnswers = List<String?>.filled(_blankCount, null);
    _allCorrect = false;
    _feedback = null;
    _shuffledTiles = List<String>.from(_puzzle.tiles)..shuffle();
  }

  // ── tap a letter tile ──────────────────────────────────────────────────
  void _tapTile(String letter) async {
    if (_allCorrect ||
        _busy ||
        resultOpen ||
        _activeBlankIndex >= _blankCount) {
      return;
    }
    final blankIndex = _activeBlankIndex;
    final isCorrect = letter == _puzzle.correctLetters[_activeBlankIndex];
    recordGameAnswer(correct: isCorrect);
    setState(() {
      _busy = true;
      _feedback = isCorrect;
    });
    gameNarration.cancel();
    final sound = gameNarration.letterName(letter);
    final request = gameNarration.generation;

    if (isCorrect) {
      await _flyLetter(letter, blankIndex);
      if (!mounted) return;
      setState(() {
        _filledAnswers[_activeBlankIndex] = letter;
        _activeBlankIndex++;
        if (_activeBlankIndex >= _blankCount) _allCorrect = true;
      });
    }
    await sound;
    if (!mounted || resultOpen) return;
    if (isCorrect) {
      if (_allCorrect) {
        if (request == gameNarration.generation) playGameCorrect();
        awardGameXp((10 * widget.difficulty.xpMultiplier).round());
        awardGameStar();
        _feedbackTimer =
            Timer(const Duration(milliseconds: 1000), _finishPuzzleFeedback);
        return;
      } else {
        if (request == gameNarration.generation) playGameCorrect();
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } else {
      if (request == gameNarration.generation) playGameWrong();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (mounted) setState(() => _busy = false);
  }

  void _finishPuzzleFeedback() {
    if (!mounted || resultOpen) return;
    if (!canAdvanceGameFeedback) {
      _feedbackTimer =
          Timer(const Duration(milliseconds: 250), _finishPuzzleFeedback);
      return;
    }
    if (_puzzleIndex < _activePuzzles.length - 1) {
      setState(() {
        _puzzleIndex++;
        _initPuzzle();
      });
    } else {
      setState(() => _busy = false);
      _showWinDialog();
    }
  }

  Future<void> _flyLetter(String letter, int blank) async {
    if (MediaQuery.disableAnimationsOf(context)) return;
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final source =
        _choiceKeys[letter]!.currentContext!.findRenderObject() as RenderBox;
    final target =
        _slotKeys[blank]!.currentContext!.findRenderObject() as RenderBox;
    final start = MatrixUtils.transformRect(
        source.getTransformTo(overlayBox), Offset.zero & source.size);
    final end = MatrixUtils.transformRect(
        target.getTransformTo(overlayBox), Offset.zero & target.size);
    _flightEntry = OverlayEntry(
        builder: (_) => AnimatedBuilder(
              animation: _flight,
              builder: (_, __) {
                final t = Curves.easeInOutCubic.transform(_flight.value);
                final rect = Rect.lerp(start, end, t)!
                    .shift(Offset(0, -math.sin(t * math.pi) * 24));
                return Positioned.fromRect(
                    rect: rect,
                    child: IgnorePointer(
                        child: ExcludeSemantics(
                      child: Material(
                          key: const ValueKey('flying-builder-letter'),
                          color: Color.lerp(const Color(0xFFFFF5DC),
                              const Color(0xFFDCF7E6), t),
                          elevation: 6,
                          borderRadius: BorderRadius.circular(10),
                          child: Center(
                              child: FittedBox(
                                  child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Text(letter,
                                          style: const TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF29165D))))))),
                    )));
              },
            ));
    overlay.insert(_flightEntry!);
    try {
      await _flight.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    } finally {
      _flightEntry?.remove();
      _flightEntry?.dispose();
      _flightEntry = null;
    }
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _flightEntry?.remove();
    _flightEntry?.dispose();
    _flightEntry = null;
    _flight.dispose();
    super.dispose();
  }

  void _restart() {
    _feedbackTimer?.cancel();
    setState(() {
      _puzzleIndex = 0;
      _activePuzzles = _newSession();
      _initPuzzle();
    });
  }

  void _showWinDialog() {
    if (resultOpen) return;
    resultOpen = true;
    final provider = context.read<AppProvider>();
    provider.recordActivityCompleted();
    awardGameXp((15 * widget.difficulty.xpMultiplier).round());
    provider.audio.playWin();
    showGameResult(_restart);
  }

  // ── Build the word display row ─────────────────────────────────────────
  Widget _buildWordRow() {
    var blank = 0;
    final scale = MediaQuery.textScalerOf(context).scale(26) / 26;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final letter in _puzzle.blanks)
        if (letter != null)
          SizedBox(
              width: 36 * scale,
              height: 40 * scale,
              child: Center(
                  child: Text(letter,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold))))
        else
          _blankSlot(blank++, scale),
    ]);
  }

  Widget _blankSlot(int blank, double scale) {
    final filled = _filledAnswers[blank];
    return Semantics(
      key: ValueKey('builder-blank-$blank'),
      label: 'Blank ${blank + 1}, ${filled ?? 'empty'}',
      excludeSemantics: true,
      child: Container(
        key: _slotKeys.putIfAbsent(blank, () => GlobalKey()),
        width: 36 * scale,
        height: 40 * scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: filled == null
                ? const Color(0xFFEDE5FF)
                : const Color(0xFFDCF7E6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: filled == null
                    ? const Color(0xFFBCAAD5)
                    : const Color(0xFF167769))),
        child: Text(filled ?? '_',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  int get totalGameItems => _activePuzzles.length;

  @override
  int get correctGameItems => _puzzleIndex + (_allCorrect ? 1 : 0);

  @override
  Widget build(BuildContext context) => GameScaffold(
      narration: gameNarration,
      tutorial: GameTutorial.wordBuilder,
      canOpenTutorial: () => !_busy && !resultOpen,
      answerResult: _feedback,
      title: 'Word Builder',
      instructions: _instruction,
      instructionPanel: GameMascotCoach(
          title: 'Word Builder',
          instructions: _instruction,
          controller: gameNarration,
          child: const GameInstructionGuide(gameTitle: 'Word Builder')),
      difficulty: widget.difficulty,
      current: _puzzleIndex + 1,
      total: _activePuzzles.length,
      hasProgress: scoredAttempts > 0 && !resultOpen,
      fitViewport: true,
      child: WordGameLayout(word: _puzzle.word, children: [
        ForestPanel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: FittedBox(fit: BoxFit.scaleDown, child: _buildWordRow())),
        const SizedBox(height: 8),
        AudioButton(
            phrase: _puzzle.word[0] + _puzzle.word.substring(1).toLowerCase(),
            enabled: !_busy && !_allCorrect && !resultOpen),
        const SizedBox(height: 8),
        WordChoiceGrid(
            children: _shuffledTiles
                .map((letter) => SizedBox(
                    key: _choiceKeys.putIfAbsent(letter, () => GlobalKey()),
                    child: GameAnswerButton(
                      buttonKey: ValueKey('builder-choice-$letter'),
                      compact: true,
                      label: letter,
                      onPressed: _allCorrect || _busy || resultOpen
                          ? null
                          : () => _tapTile(letter),
                    )))
                .toList()),
        const SizedBox(height: 6),
        SizedBox(
            height: 36,
            child: _feedback == true
                ? const GameCorrectFrame(height: 36)
                : Center(
                    child: Semantics(
                    liveRegion: true,
                    child: Text(
                        _feedback == null
                            ? ''
                            : _feedback!
                                ? 'Correct!'
                                : 'Nice try! Keep practicing.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _feedback == true
                                ? const Color(0xFF167769)
                                : const Color(0xFFB63D50))),
                  ))),
      ]));
}
