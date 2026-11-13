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
  bool _retryBusy = false;

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
    cancelGameAdvance();
    if (_roundIndex < _rounds.length - 1) {
      setState(() {
        _roundIndex++;
        _picks = {};
        _roundDone = false;
        _retryBusy = false;
        _opts = _shuffledOpts;
      });
    } else {
      _showWinDialog();
    }
  }

  void _restart() {
    setState(() {
      _roundIndex = 0;
      _rounds = _newSession();

      _picks = {};
      _roundDone = false;
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

  void _pick(String letter) {
    if (_roundDone || _retryBusy || resultOpen) return;
    gameNarration.cancel();
    final correct = letter == _round.correctLetter;
    setState(() {
      _picks[letter] = correct;
      _roundDone = true;
    });
    recordGameAnswer(
        reviewTarget: ReviewTarget.sound(_round.correctLetter),
        correct: correct,
        itemId: 'sound-$_roundIndex',
        prompt: 'Match the sound',
        selected: letter,
        expected: _round.correctLetter);
    if (correct) awardGameXp((5 * widget.difficulty.xpMultiplier).round());
    scheduleGameAdvance(_nextRound);
  }

  @override
  String get gameTitle => 'Sound Match';
  @override
  Difficulty get roundDifficulty => widget.difficulty;
  @override
  Widget gameForDifficulty(Difficulty difficulty) =>
      SoundMatchScreen(difficulty: difficulty);
  @override
  int get totalGameItems => _rounds.length;

  @override
  Widget build(BuildContext context) => GameScaffold(
        narration: gameNarration,
        answerResult: gameAnswerFeedback,
        title: 'Sound Match',
        instructions: 'Hear the sound. Pick a letter.',
        instructionPanel: const GameInstructionGuide(gameTitle: 'Sound Match'),
        difficulty: widget.difficulty,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        current: _roundIndex + 1,
        total: _rounds.length,
        fitViewport: true,
        child: SoundMatchLayout(
          submitted: _roundDone,
          phrase: 'lesson-sound-${_round.correctLetter}',
          enabled: !_roundDone && !_retryBusy && !resultOpen,
          result: null,
          choices: [
            for (var index = 0; index < _opts.length; index++)
              SoundMatchChoiceMotion(
                  key: ValueKey('sound-choice-$_roundIndex-${_opts[index]}'),
                  result: null,
                  child: GameAnswerButton(
                      colorIndex: [0, 1, 2][index],
                      buttonKey: ValueKey('sound-match-letter-${_opts[index]}'),
                      label: letterChoiceLabel(_opts[index]),
                      selected: _picks[_opts[index]] != null,
                      result: null,
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
