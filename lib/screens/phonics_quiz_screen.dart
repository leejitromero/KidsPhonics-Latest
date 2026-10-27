import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/game_session_order.dart';
import '../data/letter_data.dart';
import '../models/difficulty.dart';
import '../providers/app_provider.dart';
import '../widgets/game_instruction_guide.dart';
import '../widgets/activity_round_header.dart';
import '../widgets/game_mascot_coach.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/phonics_quiz_design.dart';

class PhonicsQuizScreen extends StatefulWidget {
  const PhonicsQuizScreen({super.key, this.difficulty = Difficulty.medium});
  final Difficulty difficulty;
  @override
  State<PhonicsQuizScreen> createState() => _PhonicsQuizScreenState();
}

class _PhonicsQuizScreenState extends State<PhonicsQuizScreen>
    with GameSessionUi<PhonicsQuizScreen>, WidgetsBindingObserver {
  late List<QuizQuestion> _questions = _newSession();
  final List<QuizQuestion> _mistakes = [];
  List<QuizQuestion> _reviewQuestions = [];
  late List<String> _options;
  int _index = 0, _generation = 0, _cueRequest = 0, _feedbackStep = 0;
  String? _selected;
  bool _submitted = false, _reviewing = false, _completionAwarded = false;
  bool _introFinished = false, _needsCue = true, _cuePlaying = false;
  bool _feedbackRunning = false, _workScheduled = false;
  Timer? _resumeTimer, _holdTimer;
  Completer<void>? _holdDone;
  QuizQuestion get _q => (_reviewing ? _reviewQuestions : _questions)[_index];
  bool get _active =>
      canAdvanceGameFeedback && TickerMode.valuesOf(context).enabled;

  List<QuizQuestion> _newSession() {
    final pool = quizQuestionsForDifficulty(widget.difficulty);
    final words = GameSessionOrder.next(
        'phonics-quiz-v2-${widget.difficulty.name}',
        pool.where((q) => q.position == QuizSoundPosition.beginning),
        (q) => q.word,
        count: GameSessionOrder.roundLength(widget.difficulty));
    final allowed = quizPositionsFor(widget.difficulty);
    final positions =
        List.generate(words.length, (i) => allowed[i % allowed.length])
          ..shuffle();
    return [
      for (var i = 0; i < words.length; i++)
        pool.singleWhere(
            (q) => q.word == words[i].word && q.position == positions[i])
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _options = List.of(_q.options)..shuffle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleWork();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _cueRequest++;
      _cuePlaying = false;
      gameNarration.cancel();
    } else {
      _scheduleWork();
    }
  }

  void _scheduleWork() {
    if (_workScheduled || !mounted) return;
    _workScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _workScheduled = false;
      if (!mounted || !_active) return;
      if (_submitted) {
        unawaited(_runFeedback());
      } else if (_introFinished && _needsCue && _selected == null) {
        unawaited(_playCue());
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _introDone() {
    _introFinished = true;
    _scheduleWork();
  }

  void _cancelCue() {
    _needsCue = false;
    _cueRequest++;
    _cuePlaying = false;
    gameNarration.cancel();
  }

  Future<void> _playCue() async {
    if (_cuePlaying || !_active || _submitted || !_needsCue) return;
    final p = context.read<AppProvider>();
    if (!p.voiceEnabled) {
      _needsCue = false;
      return;
    }
    final request = ++_cueRequest;
    final round = _generation;
    _cuePlaying = true;
    bool current() =>
        mounted &&
        round == _generation &&
        request == _cueRequest &&
        !_submitted &&
        _active;
    try {
      for (final phrase in [_q.wordAudioKey, _q.position.audioKey]) {
        if (!current()) return;
        gameNarration.updateEnvironment(enabled: p.voiceEnabled, active: true);
        final playback = gameNarration.word(phrase);
        final audioGeneration = gameNarration.generation;
        await playback;
        if (!current() || audioGeneration != gameNarration.generation) return;
      }
      if (current()) _needsCue = false;
    } finally {
      if (request == _cueRequest) _cuePlaying = false;
    }
  }

  void _select(String letter) {
    if (!_active || _submitted) return;
    _cancelCue();
    setState(() => _selected = letter);
  }

  void _hearSound(String letter) {
    if (!_active || _submitted) return;
    _cancelCue();
    unawaited(gameNarration.letterSound(letter));
  }

  void _hearQuestion() {
    if (!_active || _submitted) return;
    _cancelCue();
    unawaited(gameNarration.word(_q.position.audioKey));
  }

  void _check() {
    if (!_active || _submitted || _selected == null) return;
    _cancelCue();
    final correct = _selected == _q.correctLetter;
    setState(() {
      _submitted = true;
      _feedbackStep = 0;
    });
    // A quiz has one submission per question. Review never changes its score,
    // daily-answer counts, completion bonus, or rewards.
    if (!_reviewing) {
      recordGameAnswer(correct: correct);
      if (correct) {
        awardGameXp((5 * widget.difficulty.xpMultiplier).round());
        awardGameStar();
      } else {
        _mistakes.add(_q);
      }
    }
    unawaited(_runFeedback());
  }

  void _endHold() {
    _holdTimer?.cancel();
    final done = _holdDone;
    _holdDone = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  Future<void> _hold(Duration duration) {
    _endHold();
    final done = Completer<void>();
    _holdDone = done;
    _holdTimer = Timer(duration, () {
      if (!done.isCompleted) done.complete();
      if (_holdDone == done) _holdDone = null;
    });
    return done.future;
  }

  void _retryFeedback() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted && _submitted && !resultOpen) unawaited(_runFeedback());
    });
  }

  Future<void> _runFeedback() async {
    if (_feedbackRunning || !mounted || !_submitted || resultOpen) return;
    if (!_active) {
      _retryFeedback();
      return;
    }
    _resumeTimer?.cancel();
    _feedbackRunning = true;
    final round = _generation;
    final p = context.read<AppProvider>();
    bool current() =>
        mounted && round == _generation && _submitted && !resultOpen;
    try {
      while (current() && _feedbackStep < 3) {
        if (!_active) return;
        if (_feedbackStep < 2) {
          gameNarration.updateEnvironment(
              enabled: p.voiceEnabled, active: true);
          final playback = _feedbackStep == 0
              ? gameNarration.word(_q.wordAudioKey)
              : gameNarration.letterSound(_q.correctLetter);
          final audioGeneration = gameNarration.generation;
          await Future.wait(
              [playback, _hold(const Duration(milliseconds: 400))]);
          if (!current() ||
              !_active ||
              audioGeneration != gameNarration.generation) {
            return;
          }
        } else {
          if (_selected == _q.correctLetter) {
            await playGameCorrect();
          } else {
            await playGameWrong();
          }
          if (!current() || !_active) return;
          await _hold(const Duration(milliseconds: 800));
          if (!current() || !_active) return;
        }
        _feedbackStep++;
      }
      if (current() && _active) _advance();
    } finally {
      _feedbackRunning = false;
      if (current()) _retryFeedback();
    }
  }

  void _prepare(int index) {
    _generation++;
    _cueRequest++;
    _resumeTimer?.cancel();
    _endHold();
    gameNarration.cancel();
    _index = index;
    _selected = null;
    _submitted = false;
    _feedbackStep = 0;
    _needsCue = true;
    _cuePlaying = false;
    _options = List.of(_q.options)..shuffle();
    _scheduleWork();
  }

  void _advance() {
    final length = _reviewing ? _reviewQuestions.length : _questions.length;
    if (_index + 1 < length) {
      setState(() => _prepare(_index + 1));
    } else {
      _showResults();
    }
  }

  void _showResults() {
    if (resultOpen) return;
    setState(() => resultOpen = true);
    if (!_completionAwarded) {
      _completionAwarded = true;
      final p = context.read<AppProvider>();
      p.recordActivityCompleted();
      awardGameXp((20 * widget.difficulty.xpMultiplier).round());
      p.audio.playWin();
    }
    showGameResult(_restart,
        backLabel: 'Back to Games',
        accuracyNote: 'Review practice does not change this quiz score.',
        reviewCount: _reviewing ? 0 : _mistakes.length,
        onReview: _reviewing || _mistakes.isEmpty ? null : _startReview);
  }

  void _startReview() {
    setState(() {
      resultOpen = false;
      _reviewing = true;
      _reviewQuestions = List.of(_mistakes);
      _prepare(0);
    });
  }

  void _restart() {
    setState(() {
      _reviewing = false;
      _completionAwarded = false;
      _mistakes.clear();
      _reviewQuestions = [];
      _questions = _newSession();
      _prepare(0);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _cueRequest++;
    _resumeTimer?.cancel();
    _endHold();
    super.dispose();
  }

  @override
  int get totalGameItems => _questions.length;

  @override
  Widget build(BuildContext context) => GameScaffold(
      narration: gameNarration,
      fitViewport: true,
      answerResult: !_submitted ? null : _selected == _q.correctLetter,
      title: 'Phonics Quiz',
      roundHeader: ActivityRoundHeader(
          difficulty: widget.difficulty,
          current: _index + 1,
          total: _reviewing ? _reviewQuestions.length : _questions.length,
          label: _reviewing ? 'Review' : 'Question',
          fitLabels: true),
      instructions:
          'Listen to the word, choose your answer, then tap Check Answer!',
      instructionPanel: GameMascotCoach(
          title: 'Phonics Quiz',
          instructions: 'Listen, choose, then check.',
          controller: gameNarration,
          child: GameInstructionGuide(
              gameTitle: 'Phonics Quiz', onFinished: _introDone)),
      difficulty: widget.difficulty,
      hasProgress: (_selected != null || scoredAttempts > 0 || _reviewing) &&
          !resultOpen,
      current: _index + 1,
      total: _reviewing ? _reviewQuestions.length : _questions.length,
      progressLabel: _reviewing ? 'Review' : 'Question',
      child: PhonicsQuizQuestionView(
          question: _q,
          options: _options,
          selected: _selected,
          submitted: _submitted,
          reviewing: _reviewing,
          canInteract: _active,
          onSelect: _select,
          onCheck: _check,
          onHearSound: _hearSound,
          onHearQuestion: _hearQuestion,
          onBeforeWord: _cancelCue));
}
