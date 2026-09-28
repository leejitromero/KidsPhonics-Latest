import '../data/game_session_order.dart';
import '../widgets/game_word_picture.dart';
// lib/screens/phonics_quiz_screen.dart
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

import '../data/letter_data.dart';
import '../models/difficulty.dart';
import '../widgets/learner_widgets.dart';
import '../theme/kids_ui.dart';

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
    if (_answered) return;
    final isCorrect = letter == _q.correctLetter;
    setState(() {
      _selected = letter;
      _answered = true;
    });

    final provider = context.read<AppProvider>();
    recordGameAnswer(correct: isCorrect);
    if (isCorrect) {
      provider.audio.playCorrect();
      awardGameXp((5 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      await Future.delayed(const Duration(milliseconds: 700));
    } else {
      provider.audio.playWrong();
      await Future.delayed(const Duration(milliseconds: 700));
    }
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
  Widget build(BuildContext context) => GameScaffold(
        answerResult: _selected == null ? null : _selected == _q.correctLetter,
        title: 'Phonics Quiz',
        instructions: 'Listen to the word. Tap the matching letter or letters.',
        difficulty: widget.difficulty,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        current: _qIndex + 1,
        total: _questions.length,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: GameWordPicture(word: _q.word)),
          const SizedBox(height: KidsUi.padding),
          Text(_q.question,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          AudioButton(phrase: _q.voiceHint),
          const SizedBox(height: KidsUi.section),
          GameChoiceGrid(
              children: _shuffledOpts
                  .map((option) => GameAnswerButton(
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
          if (_answered)
            ElevatedButton(
                onPressed: resultOpen ? null : _nextQuestion,
                child: const Text('Next')),
        ]),
      );
}
