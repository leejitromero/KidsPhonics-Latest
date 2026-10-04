import '../data/game_session_order.dart';
import '../widgets/word_game_layout.dart';
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
  AppProvider? _feedbackProvider;

  @override
  void dispose() {
    _feedbackProvider?.phonicsAudio.stop();
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
    // Each question accepts only one answer.
    if (_picks[letter] == true) return;

    final isCorrect = letter == _round.correctLetter;
    setState(() {
      _picks[letter] = isCorrect;
      _roundDone = true;
    });
    final provider = context.read<AppProvider>();
    recordGameAnswer(correct: isCorrect);
    if (isCorrect) {
      final word = _round.word;
      await provider.audio.playCorrect();
      if (!mounted) return;
      awardGameXp((5 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      _feedbackProvider = provider;
      await provider.speak(word);
      _feedbackProvider = null;
      if (mounted) _nextRound();
    } else {
      // Brief feedback, then advance without offering a retry.
      provider.audio.playWrong();
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _nextRound();
    }
  }

  @override
  int get totalGameItems => _rounds.length;

  @override
  Widget build(BuildContext context) => GameScaffold(
        answerResult: _picks.isEmpty ? null : _picks.values.first,
        title: 'Sound Match',
        instructions: 'Hear the sound. Pick a letter.',
        difficulty: widget.difficulty,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        current: _roundIndex + 1,
        total: _rounds.length,
        fitViewport: true,
        child: WordGameLayout(word: _round.word, children: [
          const SizedBox(height: 4),
          const Text('Which letter makes this sound?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          AudioButton(
              phrase: 'lesson-sound-${_round.correctLetter}',
              label: 'Hear Sound',
              enabled: !_roundDone && !resultOpen),
          const SizedBox(height: 8),
          WordChoiceGrid(
              children: _opts
                  .map((option) => GameAnswerButton(
                      compact: true,
                      label: letterChoiceLabel(option),
                      selected: _picks[option] != null,
                      result: _picks[option],
                      onPressed: _roundDone ||
                              _picks.values.contains(false) ||
                              resultOpen
                          ? null
                          : () => _pick(option)))
                  .toList()),
          SizedBox(
              height: 44,
              child: Center(
                  child: Text(
                      _picks.isEmpty
                          ? ''
                          : _picks.values.first == true
                              ? 'Correct!'
                              : 'Next question…',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)))),
        ]),
      );
}
