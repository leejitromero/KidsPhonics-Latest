import 'dart:async';
import '../data/game_session_order.dart';
import '../widgets/sound_match_design.dart';
import '../widgets/game_instruction_guide.dart';
// lib/screens/sound_match_screen.dart
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

import '../data/letter_data.dart';
import '../models/difficulty.dart';
import '../widgets/learner_widgets.dart';

class SoundMatchScreen extends StatefulWidget {
  final Difficulty difficulty;
  const SoundMatchScreen({super.key, this.difficulty = Difficulty.medium});
  @override
  State<SoundMatchScreen> createState() => _SoundMatchScreenState();
}

class _SoundMatchScreenState extends State<SoundMatchScreen>
    with GameSessionUi<SoundMatchScreen> {
  int _roundIndex = 0;

  Map<String, bool?> _picks = {}; // letter -> correct?
  bool _roundDone = false;
  bool _roundScored = false;
  bool _retryBusy = false;
  Timer? _feedbackTimer;

  void _finishFeedback() {
    if (!mounted || resultOpen) return;
    if (!canAdvanceGameFeedback) {
      _feedbackTimer =
          Timer(const Duration(milliseconds: 250), _finishFeedback);
      return;
    }
    if (_roundDone) {
      _nextRound();
    } else {
      setState(() => _retryBusy = false);
    }
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  late List<SoundRound> _rounds = _newSession();
  List<SoundRound> _newSession() => GameSessionOrder.next(
      'sound_match-${widget.difficulty.name}',
      soundRoundsForDifficulty(widget.difficulty),
      (item) => item.word,
      count: GameSessionOrder.roundLength(widget.difficulty));
  SoundRound get _round => _rounds[_roundIndex];
  List<String> get _shuffledOpts {
    final distractors = _round.options
        .where((letter) => letter != _round.correctLetter)
        .toList()
      ..shuffle();
    final opts = [_round.correctLetter, ...distractors.take(2)];
    opts.shuffle();
    return opts;
  }

  late List<String> _opts;

  @override
  void initState() {
    super.initState();
    _opts = _shuffledOpts;
  }

  void _nextRound() {
    if (_roundIndex < _rounds.length - 1) {
      setState(() {
        _roundIndex++;
        _picks = {};
        _roundDone = false;
        _roundScored = false;
        _retryBusy = false;
        _opts = _shuffledOpts;
      });
    } else {
      _showWinDialog();
    }
  }

  void _restart() {
    _feedbackTimer?.cancel();
    setState(() {
      _roundIndex = 0;
      _rounds = _newSession();

      _picks = {};
      _roundDone = false;
      _roundScored = false;
      _retryBusy = false;
      _opts = _shuffledOpts;
    });
  }

  void _showWinDialog() {
    if (resultOpen) return;
    resultOpen = true;
    final provider = context.read<AppProvider>();
    provider.recordActivityCompleted();
    awardGameXp((10 * widget.difficulty.xpMultiplier).round());
    provider.audio.playWin();

    showGameResult(_restart, backLabel: 'Back to Games');
  }

  void _pick(String letter) async {
    if (_roundDone || _retryBusy || resultOpen || _picks[letter] != null) {
      return;
    }

    final isCorrect = letter == _round.correctLetter;
    final firstAttempt = !_roundScored;
    setState(() {
      _picks[letter] = isCorrect;
      _roundDone = isCorrect;
      _roundScored = true;
      _retryBusy = !isCorrect;
    });
    // Guided corrections do not change the first-answer score or duplicate
    // rewards. The learner still completes the current sound before advancing.
    if (firstAttempt) {
      recordGameAnswer(correct: isCorrect);
    }
    if (isCorrect) {
      await playGameCorrect();
      if (!mounted) return;
      if (firstAttempt) {
        awardGameXp((5 * widget.difficulty.xpMultiplier).round());
        awardGameStar();
      }
      _feedbackTimer =
          Timer(const Duration(milliseconds: 1000), _finishFeedback);
    } else {
      playGameWrong();
      _feedbackTimer =
          Timer(const Duration(milliseconds: 600), _finishFeedback);
    }
  }

  @override
  int get totalGameItems => _rounds.length;

  @override
  Widget build(BuildContext context) => GameScaffold(
        narration: gameNarration,
        answerResult: _picks.isEmpty ? null : _picks.values.last,
        title: 'Sound Match',
        instructions: 'Hear the sound. Pick a letter.',
        instructionPanel: const GameInstructionGuide(gameTitle: 'Sound Match'),
        difficulty: widget.difficulty,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        current: _roundIndex + 1,
        total: _rounds.length,
        fitViewport: true,
        child: SoundMatchLayout(
          phrase: 'lesson-sound-${_round.correctLetter}',
          enabled: !_roundDone && !_retryBusy && !resultOpen,
          result: _picks.isEmpty ? null : _picks.values.last,
          choices: [
            for (var index = 0; index < _opts.length; index++)
              SoundMatchChoiceMotion(
                  key: ValueKey('sound-choice-$_roundIndex-${_opts[index]}'),
                  result: _picks[_opts[index]],
                  child: GameAnswerButton(
                      colorIndex: [0, 1, 2][index],
                      buttonKey: ValueKey('sound-match-letter-${_opts[index]}'),
                      label: letterChoiceLabel(_opts[index]),
                      selected: _picks[_opts[index]] != null,
                      result: _picks[_opts[index]],
                      onPressed: _roundDone ||
                              _retryBusy ||
                              resultOpen ||
                              _picks[_opts[index]] != null
                          ? null
                          : () => _pick(_opts[index])))
          ],
        ),
      );
}
