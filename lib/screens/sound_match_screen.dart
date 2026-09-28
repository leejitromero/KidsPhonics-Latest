import '../data/game_session_order.dart';
import '../widgets/game_word_picture.dart';
// lib/screens/sound_match_screen.dart
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

import '../data/letter_data.dart';
import '../models/difficulty.dart';
import '../widgets/learner_widgets.dart';
import '../theme/kids_ui.dart';

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

  late List<SoundRound> _rounds = _newSession();
  List<SoundRound> _newSession() => GameSessionOrder.next(
      'sound_match-${widget.difficulty.name}',
      soundRoundsForDifficulty(widget.difficulty),
      (item) => item.word,
      count: GameSessionOrder.roundLength(widget.difficulty));
  SoundRound get _round => _rounds[_roundIndex];
  List<String> get _shuffledOpts {
    final opts = List<String>.from(_round.options);
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
    if (_roundDone || _picks.values.contains(false) || resultOpen) return;
    // Block re-tap only if already marked correct (green) — wrong picks are retryable
    if (_picks[letter] == true) return;

    final isCorrect = letter == _round.correctLetter;
    setState(() {
      _picks[letter] = isCorrect;
      if (isCorrect) {
        _roundDone = true;
      }
    });
    final provider = context.read<AppProvider>();
    recordGameAnswer(correct: isCorrect);
    if (isCorrect) {
      provider.audio.playCorrect();
      awardGameXp((5 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      // No voice — correct.mp3 tone only, then move to next round
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) _nextRound();
    } else {
      // Wrong — play tone, show red flash briefly, then clear so child can retry
      provider.audio.playWrong();
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _picks.remove(letter));
    }
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
        answerResult: _picks.isEmpty ? null : _roundDone,
        title: 'Sound Match',
        instructions:
            'Listen to the word. Choose the matching letter or letters.',
        difficulty: widget.difficulty,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        current: _roundIndex + 1,
        total: _rounds.length,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: GameWordPicture(word: _round.word)),
          const SizedBox(height: KidsUi.padding),
          Text(_round.question,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          AudioButton(phrase: _round.voiceHint),
          const SizedBox(height: KidsUi.section),
          GameChoiceGrid(
              children: _opts
                  .map((option) => GameAnswerButton(
                      label: letterChoiceLabel(option),
                      selected: _picks[option] != null,
                      result: _picks[option],
                      onPressed: _roundDone ||
                              _picks.values.contains(false) ||
                              resultOpen
                          ? null
                          : () => _pick(option)))
                  .toList()),
          if (_picks.isNotEmpty) GameFeedback(correct: _roundDone),
        ]),
      );
}
