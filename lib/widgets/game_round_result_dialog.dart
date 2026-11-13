import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/difficulty.dart';
import '../models/game_round_result.dart';
import '../theme/kids_ui.dart';
import 'button_sound.dart';
import 'completion_celebration.dart';
import 'game_difficulty_dialog.dart';

class GameResultDialog extends StatefulWidget {
  const GameResultDialog(
      {super.key,
      required this.correct,
      required this.attempts,
      required this.earnedXp,
      required this.earnedStars,
      required this.onAgain,
      required this.onBack,
      this.onReview,
      this.reviewCount = 0,
      this.accuracyNote = 'The first submitted answer counts.',
      this.totalItems,
      this.correctItems,
      this.backLabel = 'Back to Games',
      this.title = 'Game Results',
      this.difficulty = Difficulty.easy,
      this.answers = const [],
      this.onDifficultySelected,
      this.scoreUnit = 'correct',
      this.ratingCorrect,
      this.ratingTotal,
      this.completed = true,
      this.ratingStars,
      this.ratingLabel = 'accuracy',
      this.savePending = false,
      this.onRetrySaving});
  final int correct, attempts, earnedXp, earnedStars;
  final int? totalItems, correctItems, ratingCorrect, ratingTotal;
  final VoidCallback onAgain, onBack;
  final VoidCallback? onReview;
  final ValueChanged<Difficulty>? onDifficultySelected;
  final int reviewCount;
  final String accuracyNote, backLabel, title, scoreUnit;
  final Difficulty difficulty;
  final List<GameRoundAnswer> answers;
  final bool completed;
  final int? ratingStars;
  final String ratingLabel;
  final bool savePending;
  final VoidCallback? onRetrySaving;
  @override
  State<GameResultDialog> createState() => _GameResultDialogState();
}

class _GameResultDialogState extends State<GameResultDialog>
    with SingleTickerProviderStateMixin {
  static const purple = Color(0xFF54138A), ink = Color(0xFF351153);
  late final _stars = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1050));
  bool _used = false, _choosing = false, _allAnswers = false;
  int get _total => widget.totalItems ?? widget.attempts;
  int get _score => widget.correctItems ?? widget.correct;
  int get _ratingTotal => widget.ratingTotal ?? _total;
  int get _ratingCorrect => widget.ratingCorrect ?? _score;
  int get _rating =>
      widget.ratingStars ??
      gameRoundStars(
          correct: _ratingCorrect,
          total: _ratingTotal,
          completed: widget.completed);
  int get _percent => _ratingTotal == 0
      ? 0
      : (_ratingCorrect / _ratingTotal * 100).round().clamp(0, 100);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _stars.value = 1;
    } else if (_stars.value == 0 && !_stars.isAnimating) {
      _stars.forward();
    }
  }

  @override
  void dispose() {
    _stars.dispose();
    super.dispose();
  }

  void _act(VoidCallback action) {
    if (_used || _choosing) return;
    setState(() => _used = true);
    action();
  }

  Future<void> _difficulty() async {
    if (_used || _choosing || widget.onDifficultySelected == null) return;
    setState(() => _choosing = true);
    final choice = await showDialog<Difficulty>(
        context: context,
        builder: (context) => GameDifficultyDialog(
            title: widget.title,
            detail: (d) => d.description,
            onSelected: (d) => Navigator.pop(context, d)));
    if (!mounted) return;
    setState(() => _choosing = false);
    if (choice != null) _act(() => widget.onDifficultySelected!(choice));
  }

  Widget _frame(Widget child,
          {Color color = const Color(0xFFFFF8E9),
          EdgeInsets padding = const EdgeInsets.all(12)}) =>
      Container(
          decoration: BoxDecoration(
              color: const Color(0xFF6A2297),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFFBF35), width: 2.5),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x66401D50),
                    offset: Offset(0, 5),
                    blurRadius: 5)
              ]),
          padding: const EdgeInsets.all(5),
          child: Container(
              padding: padding,
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: const Color(0xFFFFEAB2), width: 1.5)),
              child: child));

  Widget _button(String text, IconData icon, List<Color> colors, VoidCallback? action,
          {String? keyName}) =>
      DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors),
              border: Border.all(color: const Color(0xFFFFD16C), width: 2),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x66421E50),
                    offset: Offset(0, 3),
                    blurRadius: 2)
              ]),
          child: TextButton.icon(
              key: keyName == null ? null : ValueKey(keyName),
              onPressed: withButtonSound(_used || _choosing ? null : action),
              style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
              icon: Icon(icon, size: 24),
              label: Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))));

  Widget _answer(GameRoundAnswer answer, int index) => Container(
      key: ValueKey('result-answer-${answer.id}'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
              colors: [Color(0xFFF0DAFC), Color(0xFFFFF6E7)]),
          border: Border.all(color: const Color(0xFFD9B2EB))),
      child: Column(children: [
        Text('Question ${index + 1} · ${answer.prompt}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        if (answer.word != null) ...[
          const SizedBox(height: 8),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < answer.word!.length; i++)
                  Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: i == answer.highlightedIndex
                              ? const Color(0xFFFFD83F)
                              : const Color(0xFFFFF9E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDDC3E5))),
                      child: Text(answer.word![i],
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w900)))
              ])),
        ],
        const SizedBox(height: 8),
        _answerLine('Your answer: ${answer.selected}', answer.correct),
        if (!answer.correct) ...[
          const SizedBox(height: 5),
          _answerLine('Correct answer: ${answer.expected}', true)
        ],
      ]));
  Widget _answerLine(String text, bool correct) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFEACFF6),
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800))),
        const SizedBox(width: 5),
        Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: correct ? const Color(0xFF16842B) : const Color(0xFFC04F61),
            size: 23)
      ]));

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final wrong = widget.answers.where((a) => !a.correct).length;
    return Theme(
        data: KidsUi.theme,
        child: PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: 500,
                    maxHeight: math.max(
                        120,
                        MediaQuery.sizeOf(context).height -
                            24 -
                            MediaQuery.paddingOf(context).vertical)),
                child: CompletionCelebration(
                    child: _frame(
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          Flexible(
                              child: SingleChildScrollView(
                                  key: const ValueKey('game-result-scroll'),
                                  child: Column(children: [
                                    Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 9, horizontal: 8),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(22),
                                            gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFAD48E5),
                                                  purple
                                                ]),
                                            border: Border.all(
                                                color: const Color(0xFFFFCD58),
                                                width: 2)),
                                        child: Text(widget.title.toUpperCase(),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white))),
                                    const SizedBox(height: 10),
                                    const Text('Round Complete!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 28,
                                            height: 1.1,
                                            fontWeight: FontWeight.w900,
                                            color: ink)),
                                    const SizedBox(height: 5),
                                    Semantics(
                                        label: '$_rating of 3 stars',
                                        child: ExcludeSemantics(
                                            child: AnimatedBuilder(
                                                animation: _stars,
                                                builder: (_, __) => Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          for (var i = 0;
                                                              i < 3;
                                                              i++)
                                                            Transform.scale(
                                                                scale: i >=
                                                                        _rating
                                                                    ? 1
                                                                    : .65 +
                                                                        .35 *
                                                                            Curves.easeOutBack.transform(((_stars.value - i * .18) / .55).clamp(
                                                                                0.0, 1.0)),
                                                                child: Icon(
                                                                    Icons
                                                                        .star_rounded,
                                                                    key: ValueKey(
                                                                        'result-star-$i'),
                                                                    size: 64,
                                                                    color: i <
                                                                            _rating
                                                                        ? const Color(
                                                                            0xFFFFC82D)
                                                                        : const Color(0xFFBDB0CB),
                                                                    shadows: [
                                                                      Shadow(
                                                                          color: i < _rating
                                                                              ? const Color(
                                                                                  0xFFBD730D)
                                                                              : const Color(
                                                                                  0xFF8D7C9E),
                                                                          offset: const Offset(
                                                                              0,
                                                                              3),
                                                                          blurRadius:
                                                                              1)
                                                                    ]))
                                                        ])))),
                                    Text('Score: $_score / $_total',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 27,
                                            fontWeight: FontWeight.w900,
                                            color: ink)),
                                    Text(
                                        '$_percent% ${widget.ratingLabel} · ${widget.difficulty.label}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: ink)),
                                    if (widget.scoreUnit != 'correct')
                                      Text(widget.scoreUnit,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 12)),
                                    const SizedBox(height: 8),
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 5),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFFFED85),
                                                  Color(0xFFFFC12E)
                                                ]),
                                            border: Border.all(
                                                color: const Color(0xFFE3A02C),
                                                width: 2)),
                                        child: Text('+${widget.earnedXp} XP',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 22,
                                                color: ink))),
                                    Text('Stars Earned: +${widget.earnedStars}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 5),
                                    Text(
                                        _rating == 3
                                            ? 'Wonderful work! Keep shining!'
                                            : 'Great effort! Keep learning!',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: ink)),
                                    const SizedBox(height: 10),
                                    if (widget.answers.isNotEmpty)
                                      _frame(
                                          Column(children: [
                                            Row(children: [
                                              const Expanded(
                                                  child: Text('Review Answers',
                                                      style: TextStyle(
                                                          fontSize: 19,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color: ink))),
                                              Text('$wrong to practice',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: purple))
                                            ]),
                                            for (var i = 0;
                                                i < widget.answers.length;
                                                i++)
                                              if (_allAnswers ||
                                                  !widget.answers[i].correct)
                                                _answer(widget.answers[i], i),
                                            if (!_allAnswers &&
                                                widget.answers.length > wrong)
                                              TextButton(
                                                  onPressed: () => setState(
                                                      () => _allAnswers = true),
                                                  child: Text(
                                                      '${widget.answers.length - wrong} other answers correct · View all',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight
                                                              .w800))),
                                          ]),
                                          padding: const EdgeInsets.all(9)),
                                    Text(widget.accuracyNote,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 12, color: KidsUi.muted)),
                                    if (widget.savePending)
                                      TextButton.icon(
                                          key: const ValueKey(
                                              'result-retry-save'),
                                          onPressed: widget.onRetrySaving,
                                          icon: const Icon(Icons.save_outlined),
                                          label: const Text(
                                              'Rewards are waiting to save. Retry')),
                                    if (widget.onReview != null &&
                                        widget.reviewCount > 0)
                                      TextButton(
                                          key: const ValueKey(
                                              'quiz-review-mistakes'),
                                          onPressed: _used || _choosing
                                              ? null
                                              : () => _act(widget.onReview!),
                                          child: Text(
                                              'Practice Mistakes (${widget.reviewCount})')),
                                    const SizedBox(height: 8),
                                  ]))),
                          const SizedBox(height: 8),
                          _button(
                              'Play Again',
                              Icons.replay_rounded,
                              const [Color(0xFFB7F94B), Color(0xFF179B0A)],
                              () => _act(widget.onAgain),
                              keyName: 'result-play-again'),
                          const SizedBox(height: 8),
                          LayoutBuilder(builder: (_, box) {
                            final actions = [
                              if (widget.onDifficultySelected != null)
                                _button(
                                    'Change Difficulty',
                                    Icons.tune_rounded,
                                    const [
                                      Color(0xFF39D8EF),
                                      Color(0xFF008A9D)
                                    ],
                                    _difficulty,
                                    keyName: 'result-change-difficulty'),
                              _button(
                                  widget.backLabel,
                                  Icons.sports_esports_rounded,
                                  const [Color(0xFFC154EA), Color(0xFF7321B9)],
                                  () => _act(widget.onBack),
                                  keyName: 'result-back'),
                            ];
                            return scale > 1.4 || box.maxWidth < 290
                                ? Column(children: [
                                    for (var i = 0;
                                        i < actions.length;
                                        i++) ...[
                                      if (i > 0) const SizedBox(height: 7),
                                      actions[i]
                                    ]
                                  ])
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                        for (var i = 0;
                                            i < actions.length;
                                            i++) ...[
                                          if (i > 0) const SizedBox(width: 7),
                                          Expanded(child: actions[i])
                                        ]
                                      ]);
                          }),
                        ]),
                        padding: const EdgeInsets.all(10))),
              ),
            )));
  }
}
