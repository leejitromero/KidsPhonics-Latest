import '../widgets/activity_prompt.dart';
import '../data/game_session_order.dart';
import '../data/game_word_data.dart';
import '../widgets/game_word_picture.dart';
// lib/screens/sound_position_screen.dart
//
// Beginning / Middle / End Sound — shows a word + picture, asks where
// a given letter sound appears (Beginning, Middle, or End).
//
// Easy   : Beginning only (3 words)
// Medium : Beginning + End (5 words)
// Hard   : Beginning + Middle + End (7 words)

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../data/phonics_activity_data.dart';
import '../providers/app_provider.dart';
import '../models/difficulty.dart';

import '../widgets/learner_widgets.dart';
import '../theme/kids_ui.dart';

// ── Data ──────────────────────────────────────────────────────────────────

class SoundPositionScreen extends StatefulWidget {
  final Difficulty difficulty;
  const SoundPositionScreen({super.key, this.difficulty = Difficulty.easy});

  @override
  State<SoundPositionScreen> createState() => SoundPositionitionScreenState();
}

class SoundPositionitionScreenState extends State<SoundPositionScreen>
    with GameSessionUi<SoundPositionScreen> {
  int _index = 0;
  SoundPosition? _picked;
  bool _answered = false;

  late List<SoundPositionRound> _rounds = _newSession();
  List<SoundPositionRound> _newSession() => GameSessionOrder.next(
      'sound_position-${widget.difficulty.name}',
      positionRoundsFor(widget.difficulty),
      (item) => '${item.word}:${item.targetLetter}:${item.correctPos.name}',
      count: GameSessionOrder.roundLength(widget.difficulty));
  SoundPositionRound get _round => _rounds[_index];

  @override
  void initState() {
    super.initState();
  }

  void _pick(SoundPosition pos) {
    if (_answered || _picked != null || resultOpen) return;
    final correct = pos == _round.correctPos;
    gameNarration.cancel();
    setState(() {
      _picked = pos;
      _answered = true;
    });
    recordGameAnswer(
        reviewTarget: ReviewTarget.position(
            _round.word.toUpperCase(), _round.targetLetter),
        correct: correct,
        itemId: 'position-$_index',
        prompt: 'Sound position in ${_round.word}',
        selected: pos.label,
        expected: _round.correctPos.label,
        word: _round.word);
    if (correct) awardGameXp((8 * widget.difficulty.xpMultiplier).round());
    scheduleGameAdvance(_next);
  }

  void _next() {
    cancelGameAdvance();
    if (!_answered || resultOpen) return;
    if (_index < _rounds.length - 1) {
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
        _rounds = _newSession();
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
  String get gameTitle => 'Sound Position';
  @override
  Difficulty get roundDifficulty => widget.difficulty;
  @override
  Widget gameForDifficulty(Difficulty difficulty) =>
      SoundPositionScreen(difficulty: difficulty);
  @override
  int get totalGameItems => _rounds.length;

  @override
  Widget build(BuildContext context) => GameScaffold(
        narration: gameNarration,
        showHeader: true,
        answerResult: gameAnswerFeedback,
        title: 'Sound Position',
        instructions: 'Where is the sound?',
        difficulty: widget.difficulty,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        current: _index + 1,
        total: _rounds.length,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ActivityPrompt(
            picture: gameWordFor(_round.word) == null
                ? GameImageCard(emoji: _round.emoji)
                : GameWordPicture(word: _round.word, size: 170),
            title: 'Where is ${_round.soundDisplay} in ${_round.word}?',
            caption: 'Beginning, middle, or end?',
          ),
          const SizedBox(height: KidsUi.gap),
          AudioButton(
              phrase: _round.word[0] + _round.word.substring(1).toLowerCase()),
          const SizedBox(height: KidsUi.section),
          GameChoiceGrid(
              children: _round.options
                  .map((option) => GameAnswerButton(
                      label: option.label,
                      selected: _picked == option,
                      result: null,
                      onPressed: _answered || _picked != null || resultOpen
                          ? null
                          : () => _pick(option)))
                  .toList()),
          if (_picked != null) const Text('Answer saved!'),
        ]),
      );
}
