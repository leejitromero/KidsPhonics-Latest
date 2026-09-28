import '../data/game_session_order.dart';
import '../widgets/mascot_guide.dart';
import '../widgets/lesson_picture.dart';
import '../data/lesson_example_data.dart';
// lib/screens/rhyming_words_screen.dart
//
// Rhyming Words lesson with Easy / Medium / Hard difficulty.
//
// Easy  : 3 choices, very simple CVC rhymes (cat/bat, dog/log…)
// Medium: 4 choices, slightly longer words
// Hard  : 5 choices, trickier rhymes with more distractors

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../data/phonics_activity_data.dart';
import '../providers/app_provider.dart';
import '../models/difficulty.dart';

import '../widgets/learner_widgets.dart';
import '../theme/kids_ui.dart';

class RhymingWordsScreen extends StatefulWidget {
  final Difficulty difficulty;
  const RhymingWordsScreen({super.key, this.difficulty = Difficulty.medium});

  @override
  State<RhymingWordsScreen> createState() => _RhymingWordsScreenState();
}

class _RhymingWordsScreenState extends State<RhymingWordsScreen>
    with GameSessionUi<RhymingWordsScreen> {
  int _roundIndex = 0;
  String? _picked;
  bool _answered = false;

  late List<RhymeOption> _shuffled;

  late List<RhymeRound> _rounds = _newSession();
  List<RhymeRound> _newSession() => GameSessionOrder.next(
      'rhyming_words-${widget.difficulty.name}',
      rhymeRoundsForDifficulty(widget.difficulty),
      (item) => item.word,
      count: GameSessionOrder.roundLength(widget.difficulty));
  RhymeRound get _round => _rounds[_roundIndex];

  @override
  void initState() {
    super.initState();
    _shuffleOptions();
  }

  void _shuffleOptions() {
    _shuffled = List<RhymeOption>.from(_round.options)..shuffle();
  }

  void _restart() {
    setState(() {
      _roundIndex = 0;
      _rounds = _newSession();
      _picked = null;
      _answered = false;

      _shuffleOptions();
    });
  }

  void _pick(String word) async {
    if (_answered) return;
    final isCorrect = word == _round.correctRhyme;
    setState(() {
      _picked = word;
      _answered = true;
    });

    final provider = context.read<AppProvider>();
    recordGameAnswer(correct: isCorrect);
    if (isCorrect) {
      provider.audio.playCorrect();
      awardGameXp((8 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
    } else {
      provider.audio.playWrong();
    }
  }

  void _next() {
    if (!_answered || resultOpen) return;
    if (_roundIndex < _rounds.length - 1) {
      setState(() {
        _roundIndex++;
        _picked = null;
        _answered = false;
        _shuffleOptions();
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    if (resultOpen) return;
    resultOpen = true;
    final provider = context.read<AppProvider>();
    provider.recordActivityCompleted();
    awardGameXp((20 * widget.difficulty.xpMultiplier).round());
    provider.audio.playWin();
    provider.markRhymingWordsDone();
    showGameResult(_restart, backLabel: 'Back to Lessons');
  }

  @override
  Widget build(BuildContext context) => GameScaffold(
        answerResult: _picked == null ? null : _picked == _round.correctRhyme,
        compactGuide: true,
        mascot: LearningMascot.wigloo,
        title: 'Rhyming Words',
        instructions: 'Hear the word. Tap the word that rhymes.',
        difficulty: widget.difficulty,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        current: _roundIndex + 1,
        total: _rounds.length,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
              child: LessonPicture(
                  key: ValueKey(_round.word),
                  example: lessonExamples
                      .firstWhere((e) => e.word.toUpperCase() == _round.word),
                  size: 140)),
          const SizedBox(height: KidsUi.padding),
          Text('What rhymes with ${_round.word}?',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          AudioButton(
              color: const Color(0xFF087F86),
              phrase: lessonExamples
                  .firstWhere((e) => e.word.toUpperCase() == _round.word)
                  .wordAudioKey),
          const SizedBox(height: KidsUi.section),
          GameChoiceGrid(
              children: _shuffled
                  .map((option) => GameAnswerButton(
                      accent: [
                        const Color(0xFF7052CA),
                        const Color(0xFF167769),
                        const Color(0xFFB45731)
                      ][_shuffled.indexOf(option) % 3],
                      label: option.word,
                      selected: _picked == option.word,
                      result: _picked == option.word
                          ? option.word == _round.correctRhyme
                          : null,
                      onPressed: _answered || resultOpen
                          ? null
                          : () => _pick(option.word)))
                  .toList()),
          if (_picked != null)
            GameFeedback(correct: _picked == _round.correctRhyme),
          if (_answered)
            ElevatedButton(
                onPressed: resultOpen ? null : _next,
                child: const Text('Next')),
        ]),
      );
}
