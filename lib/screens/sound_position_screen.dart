import '../widgets/button_sound.dart';
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
      (item) => item.word,
      count: GameSessionOrder.roundLength(widget.difficulty));
  SoundPositionRound get _round => _rounds[_index];

  @override
  void initState() {
    super.initState();
  }

  void _pick(SoundPosition pos) async {
    if (_answered || _picked != null || resultOpen) return;
    final isCorrect = pos == _round.correctPos;
    setState(() => _picked = pos);

    final provider = context.read<AppProvider>();
    recordGameAnswer(correct: isCorrect);
    if (isCorrect) {
      setState(() {
        _answered = true;
      });
      // Play correct.mp3 tone first — no voice feedback competing with it
      provider.audio.playCorrect();
      awardGameXp((8 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      // Keep a short pause for visual feedback.
      await Future.delayed(const Duration(milliseconds: 700));
    } else {
      // Wrong — play wrong.mp3 tone first, then voice
      provider.audio.playWrong();
      await Future.delayed(const Duration(milliseconds: 700));
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _picked = null);
    }
  }

  void _next() {
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
  int get totalGameItems => _rounds.length;

  @override
  Widget build(BuildContext context) => GameScaffold(
        showHeader: true,
        answerResult: _picked == null ? null : _picked == _round.correctPos,
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
                      result: _picked == option
                          ? option == _round.correctPos
                          : null,
                      onPressed: _answered || _picked != null || resultOpen
                          ? null
                          : () => _pick(option)))
                  .toList()),
          if (_picked != null)
            GameFeedback(correct: _picked == _round.correctPos),
          if (_answered)
            ElevatedButton(
                onPressed: withButtonSound(resultOpen ? null : _next),
                child: const Text('Next')),
        ]),
      );
}
