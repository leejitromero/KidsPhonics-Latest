import '../data/game_session_order.dart';
import '../widgets/game_word_picture.dart';
// lib/screens/picture_word_match_screen.dart
//
// Picture-to-Word Match — 4 pictures shown, tap the one that matches the word.
// Tests word recognition by connecting written text to images.
//
// Easy   : 3 choices, simple 3-letter words
// Medium : 4 choices
// Hard   : 5 choices + longer words

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../data/phonics_activity_data.dart';
import '../providers/app_provider.dart';
import '../models/difficulty.dart';

import '../widgets/learner_widgets.dart';
import '../theme/kids_ui.dart';

class PictureWordMatchScreen extends StatefulWidget {
  final Difficulty difficulty;
  const PictureWordMatchScreen({super.key, this.difficulty = Difficulty.easy});

  @override
  State<PictureWordMatchScreen> createState() => _PictureWordMatchScreenState();
}

class _PictureWordMatchScreenState extends State<PictureWordMatchScreen>
    with GameSessionUi<PictureWordMatchScreen> {
  int _index = 0;
  String? _picked;
  bool _answered = false;

  late List<int> _shuffledIdx;

  late List<PictureWordRound> _rounds = _newSession();
  List<PictureWordRound> _newSession() => GameSessionOrder.next(
      'picture_word_match-${widget.difficulty.name}',
      pictureRoundsFor(widget.difficulty),
      (item) => item.word);
  PictureWordRound get _round => _rounds[_index];

  @override
  void initState() {
    super.initState();
    _shuffleIdx();
  }

  void _shuffleIdx() {
    _shuffledIdx = List.generate(_round.options.length, (i) => i)..shuffle();
  }

  void _pick(String emoji) async {
    if (_answered || _picked != null || resultOpen) return;
    final isCorrect = emoji == _round.correctEmoji;
    setState(() => _picked = emoji);

    final provider = context.read<AppProvider>();
    recordGameAnswer(correct: isCorrect);
    if (isCorrect) {
      setState(() {
        _answered = true;
      });
      provider.audio.playCorrect();
      awardGameXp((8 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      // No competing voice — correct.mp3 plays cleanly
    } else {
      // Wrong — play wrong.mp3 tone, show red flash, then clear so child can retry
      provider.audio.playWrong();
      await Future.delayed(const Duration(milliseconds: 900));
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
        _shuffleIdx();
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

        _shuffleIdx();
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
  Widget build(BuildContext context) => GameScaffold(
        title: 'Picture Match',
        instructions: 'Read or hear the word. Tap its picture.',
        difficulty: widget.difficulty,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        current: _index + 1,
        total: _rounds.length,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Center(child: GameImageCard(emoji: '🖼️')),
          const SizedBox(height: KidsUi.padding),
          Text(_round.word,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          AudioButton(
              phrase: _round.word[0] + _round.word.substring(1).toLowerCase()),
          const SizedBox(height: KidsUi.section),
          GameChoiceGrid(
              children: _shuffledIdx
                  .map((option) => GameAnswerButton(
                      label: 'Picture ${option + 1}',
                      visual: GameWordPicture(word: _round.labels[option]),
                      selected: _picked == _round.options[option],
                      result: _picked == _round.options[option]
                          ? _round.options[option] == _round.correctEmoji
                          : null,
                      onPressed: _answered || _picked != null || resultOpen
                          ? null
                          : () => _pick(_round.options[option])))
                  .toList()),
          if (_picked != null)
            GameFeedback(correct: _picked == _round.correctEmoji),
          if (_answered)
            ElevatedButton(
                onPressed: resultOpen ? null : _next,
                child: const Text('Next')),
        ]),
      );
}
