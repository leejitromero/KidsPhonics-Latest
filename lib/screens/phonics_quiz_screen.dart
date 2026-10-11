import '../data/game_session_order.dart';
import 'dart:async';
import '../widgets/word_game_layout.dart';
// lib/screens/phonics_quiz_screen.dart
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

import '../data/letter_data.dart';
import '../models/difficulty.dart';
import '../widgets/learner_widgets.dart';

class PhonicsQuizScreen extends StatefulWidget {
  final Difficulty difficulty;
  const PhonicsQuizScreen({super.key, this.difficulty = Difficulty.medium});
  @override
  State<PhonicsQuizScreen> createState() => _PhonicsQuizScreenState();
}

class _PhonicsQuizScreenState extends State<PhonicsQuizScreen>
    with GameSessionUi<PhonicsQuizScreen> {
  int _qIndex = 0;
  String? _selected;
  bool _answered = false;
  Timer? _feedbackTimer;

  late List<String> _shuffledOpts;

  late List<QuizQuestion> _questions = _newSession();
  List<QuizQuestion> _newSession() => GameSessionOrder.next(
      'phonics_quiz-${widget.difficulty.name}',
      quizQuestionsForDifficulty(widget.difficulty),
      (item) => item.word,
      count: GameSessionOrder.roundLength(widget.difficulty));

  @override
  void initState() {
    super.initState();
    _shuffleOpts();
  }

  void _shuffleOpts() {
    _shuffledOpts = List<String>.from(_questions[_qIndex].options)..shuffle();
  }

  QuizQuestion get _q => _questions[_qIndex];

  void _pick(String letter) async {
    if (_answered || resultOpen) return;
    final isCorrect = letter == _q.correctLetter;
    setState(() {
      _selected = letter;
      _answered = true;
    });

    recordGameAnswer(correct: isCorrect);
    if (isCorrect) {
      awardGameXp((5 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
    }
    gameNarration.cancel();
    final sound = gameNarration.letterSound(letter);
    final request = gameNarration.generation;
    await sound;
    if (!mounted || resultOpen) return;
    // Finish the chosen phoneme before answer effects or praise can replace it.
    if (request == gameNarration.generation) {
      if (isCorrect) {
        playGameCorrect();
      } else {
        playGameWrong();
      }
    }
    _feedbackTimer = Timer(Duration(milliseconds: isCorrect ? 1500 : 700),
        () => _finishFeedback(isCorrect));
  }

  void _finishFeedback(bool correct) {
    if (!mounted || resultOpen) return;
    // Preserve the task during dialogs, backgrounding and the time-limit screen.
    if (!canAdvanceGameFeedback) {
      _feedbackTimer = Timer(
          const Duration(milliseconds: 250), () => _finishFeedback(correct));
      return;
    }
    if (correct) {
      _nextQuestion();
    } else {
      setState(() {
        _selected = null;
        _answered = false;
      });
    }
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _nextQuestion() {
    if (!_answered || resultOpen) return;
    if (_qIndex < _questions.length - 1) {
      setState(() {
        _qIndex++;
        _selected = null;
        _answered = false;
        _shuffleOpts();
      });
    } else {
      _showResults();
    }
  }

  void _restart() {
    setState(() {
      _qIndex = 0;
      _questions = _newSession();
      _selected = null;
      _answered = false;

      _shuffleOpts();
    });
  }

  void _showResults() {
    if (resultOpen) return;
    resultOpen = true;
    final provider = context.read<AppProvider>();
    provider.recordActivityCompleted();
    awardGameXp((20 * widget.difficulty.xpMultiplier).round());
    provider.audio.playWin();

    showGameResult(_restart, backLabel: 'Back to Games');
  }

  @override
  int get totalGameItems => _questions.length;

  @override
  Widget build(BuildContext context) => GameScaffold(
        narration: gameNarration,
        fitViewport: true,
        answerResult: _selected == null ? null : _selected == _q.correctLetter,
        title: 'Phonics Quiz',
        instructions: 'Listen and pick the letters.',
        difficulty: widget.difficulty,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        current: _qIndex + 1,
        total: _questions.length,
        child: WordGameLayout(word: _q.word, children: [
          const SizedBox(height: 4),
          AudioButton(phrase: _q.voiceHint, enabled: !_answered && !resultOpen),
          const SizedBox(height: 8),
          WordChoiceGrid(
              children: _shuffledOpts
                  .map((option) => GameAnswerButton(
                      compact: true,
                      label: letterChoiceLabel(option),
                      selected: _selected == option,
                      result: _selected == option
                          ? option == _q.correctLetter
                          : null,
                      onPressed:
                          _answered || resultOpen ? null : () => _pick(option)))
                  .toList()),
          if (_selected != null)
            GameFeedback(correct: _selected == _q.correctLetter),
        ]),
      );
}
