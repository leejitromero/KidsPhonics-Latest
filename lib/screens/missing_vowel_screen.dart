import '../data/game_session_order.dart';
import '../widgets/word_game_layout.dart';
// lib/screens/missing_vowel_screen.dart
//
// Missing Vowel — shows a word with the vowel blanked out (C_T, D_G, S_N).
// Child taps the correct vowel to complete the word.
//
// Easy   : 3 short CVC words, 3 vowel choices (A, E, I)
// Medium : 5 words, 4 vowel choices (A, E, I, O)
// Hard   : 7 words, all 5 vowels (A, E, I, O, U)

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
    with GameSessionUi<MissingVowelScreen> {
  int _index = 0;
  String? _picked;
  bool _answered = false;

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
  }

  void _pick(String vowel) async {
    if (_answered || _picked != null || resultOpen) return;
    final isCorrect = vowel == _puzzle.vowel;
    setState(() {
      _picked = vowel;
    });

    final provider = context.read<AppProvider>();
    recordGameAnswer(correct: isCorrect);
    if (isCorrect) {
      setState(() {
        _answered = true;
      });
      // Play correct.mp3 tone first
      provider.audio.playCorrect();
      awardGameXp((8 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      await Future.delayed(const Duration(milliseconds: 700));
    } else {
      // Play wrong.mp3 tone first
      provider.audio.playWrong();
      await Future.delayed(const Duration(milliseconds: 700));
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _picked = null);
    }
  }

  void _next() {
    if (!_answered || resultOpen) return;
    if (_index < _puzzles.length - 1) {
      setState(() {
        _index++;
        _picked = null;
        _answered = false;
      });
    } else {
      _showResults();
    }
  }

  void _restart() => setState(() {
        _index = 0;
        _puzzles = _newSession();
        _picked = null;
        _answered = false;
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
        fitViewport: true,
        answerResult: _picked == null ? null : _picked == _puzzle.vowel,
        title: 'Missing Vowel',
        instructions: 'Hear the word. Choose the missing vowel.',
        difficulty: widget.difficulty,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        current: _index + 1,
        total: _puzzles.length,
        child: WordGameLayout(word: _puzzle.word, children: [
          const SizedBox(height: 4),
          Text(_puzzle.display,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          AudioButton(
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
                onPressed: resultOpen ? null : _next,
                child: const Text('Next')),
        ]),
      );
}
