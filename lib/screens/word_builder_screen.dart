import '../data/game_session_order.dart';
import '../widgets/word_game_layout.dart';
import '../widgets/game_design.dart';
// lib/screens/word_builder_screen.dart
import 'package:flutter/material.dart';

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
    with GameSessionUi<WordBuilderScreen> {
  int _puzzleIndex = 0;
  bool? _feedback;

  // For multi-blank: track which blank is currently being filled (0-based)
  int _activeBlankIndex = 0;
  // Filled answers so far — index = blank slot index
  late List<String?> _filledAnswers;

  bool _busy = false;
  bool _allCorrect = false; // true when all blanks filled correctly

  late List<WordPuzzle> _activePuzzles = _newSession();
  List<WordPuzzle> _newSession() => GameSessionOrder.next(
      'word_builder-${widget.difficulty.name}',
      wordPuzzlesForDifficulty(widget.difficulty),
      (item) => item.word,
      count: GameSessionOrder.roundLength(widget.difficulty));
  WordPuzzle get _puzzle => _activePuzzles[_puzzleIndex];
  late List<String> _shuffledTiles;

  int get _blankCount => _puzzle.correctLetters.length;

  @override
  void initState() {
    super.initState();
    _initPuzzle();
  }

  void _initPuzzle() {
    _activeBlankIndex = 0;
    _filledAnswers = List<String?>.filled(_blankCount, null);
    _allCorrect = false;
    _feedback = null;
    _shuffledTiles = List<String>.from(_puzzle.tiles)..shuffle();
  }

  // ── tap a letter tile ──────────────────────────────────────────────────
  void _tapTile(String letter) async {
    if (_allCorrect || _busy || resultOpen) return;
    _busy = true;
    // Still blanks left to fill
    if (_activeBlankIndex >= _blankCount) return;

    final provider = context.read<AppProvider>();

    final isCorrect = letter == _puzzle.correctLetters[_activeBlankIndex];
    recordGameAnswer(correct: isCorrect);
    setState(() => _feedback = isCorrect);

    if (isCorrect) {
      setState(() {
        _filledAnswers[_activeBlankIndex] = letter;
        _activeBlankIndex++;
        if (_activeBlankIndex >= _blankCount) _allCorrect = true;
      });

      if (_allCorrect) {
        // All blanks correct — play correct.mp3 tone only
        provider.audio.playCorrect();
        awardGameXp((10 * widget.difficulty.xpMultiplier).round());
        awardGameStar();
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;
        if (_puzzleIndex < _activePuzzles.length - 1) {
          setState(() {
            _puzzleIndex++;
            _initPuzzle();
          });
        } else {
          _showWinDialog();
        }
      } else {
        // Correct blank filled — play correct.mp3, move to next blank
        provider.audio.playCorrect();
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } else {
      // Wrong letter — play wrong.mp3 only, no voice
      provider.audio.playWrong();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (mounted) setState(() => _busy = false);
  }

  void _restart() {
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
    final word = _puzzle.blanks
        .map((letter) => letter ?? (_filledAnswers[blank++] ?? '_'))
        .join(' ');
    return Text(word,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold));
  }

  @override
  int get totalGameItems => _activePuzzles.length;

  @override
  int get correctGameItems => _puzzleIndex + (_allCorrect ? 1 : 0);

  @override
  Widget build(BuildContext context) => GameScaffold(
      tutorial: GameTutorial.wordBuilder,
      canOpenTutorial: () => !_busy && !resultOpen,
      answerResult: _feedback,
      title: 'Word Builder',
      instructions: 'Fill the blanks, left to right.',
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
            phrase: _puzzle.word[0] + _puzzle.word.substring(1).toLowerCase()),
        const SizedBox(height: 8),
        WordChoiceGrid(
            children: _shuffledTiles
                .map((letter) => GameAnswerButton(
                      buttonKey: ValueKey('builder-choice-$letter'),
                      compact: true,
                      label: letter,
                      onPressed: _allCorrect || _busy || resultOpen
                          ? null
                          : () => _tapTile(letter),
                    ))
                .toList()),
        const SizedBox(height: 6),
        SizedBox(
            height: 36,
            child: Center(
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
