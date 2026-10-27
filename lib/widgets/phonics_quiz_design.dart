import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../data/letter_data.dart';
import 'button_sound.dart';
import 'game_design.dart';
import 'game_feedback_art.dart';
import 'learner_widgets.dart';
import 'word_game_layout.dart';

class PhonicsQuizQuestionView extends StatelessWidget {
  const PhonicsQuizQuestionView(
      {super.key,
      required this.question,
      required this.options,
      required this.selected,
      required this.submitted,
      required this.reviewing,
      required this.canInteract,
      required this.onSelect,
      required this.onCheck,
      required this.onHearSound,
      required this.onHearQuestion,
      required this.onBeforeWord});
  final QuizQuestion question;
  final List<String> options;
  final String? selected;
  final bool submitted, reviewing, canInteract;
  final ValueChanged<String> onSelect, onHearSound;
  final VoidCallback onCheck, onHearQuestion, onBeforeWord;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final compact = box.maxHeight < 440;
        final voice = context.watch<AppProvider>().voiceEnabled;
        final gap = compact ? 4.0 : 8.0;
        final correct = selected == question.correctLetter;
        return WordGameLayout(
            word: question.word,
            pictureAsset: question.pictureAsset,
            pictureExtent:
                compact ? 80 : (box.maxHeight * .30).clamp(130.0, 200.0),
            children: [
              _QuizTextFrame(
                  key: const ValueKey('quiz-question-frame'),
                  child: SizedBox(
                      height: compact ? 36 : 44,
                      child: Row(children: [
                        Expanded(
                            child: LayoutBuilder(
                                builder: (_, bounds) => FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: SizedBox(
                                        width: bounds.maxWidth,
                                        child: Text(question.question,
                                            key:
                                                const ValueKey('quiz-question'),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                height: 1.12,
                                                fontSize: compact ? 16 : 18,
                                                fontWeight: FontWeight.w900,
                                                color: GameDesign.ink)))))),
                        const SizedBox(width: 6),
                        _QuizSpeakerButton(
                            buttonKey: const ValueKey('quiz-hear-question'),
                            size: compact ? 34 : 40,
                            color: const Color(0xFF008DDA),
                            tooltip: 'Hear Question',
                            onPressed: voice && canInteract && !submitted
                                ? onHearQuestion
                                : null),
                      ]))),
              SizedBox(height: gap),
              AudioButton(
                  phrase: question.wordAudioKey,
                  enabled: canInteract && !submitted,
                  onBeforePlay: onBeforeWord,
                  statusBuilder: (message) => SizedBox(
                      height: 14,
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(message,
                              style: const TextStyle(fontSize: 12)))),
                  controlBuilder: (_, onPlay, playing, label) => SizedBox(
                      height: 44,
                      child: Center(
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ForestAudioButton(
                                  label: label,
                                  icon: playing
                                      ? Icons.graphic_eq_rounded
                                      : Icons.volume_up_rounded,
                                  onPressed: onPlay))))),
              SizedBox(height: gap),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final letter in options)
                  Expanded(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                        height: compact ? 60 : 80,
                        width: compact ? 70 : 92,
                        child: GameAnswerButton(
                            label: letterChoiceLabel(letter),
                            labelStyle: const TextStyle(
                                fontSize: 36, color: GameDesign.ink),
                            compact: true,
                            floating: false,
                            selected: selected == letter,
                            result: submitted &&
                                    (letter == selected ||
                                        letter == question.correctLetter)
                                ? letter == question.correctLetter
                                : null,
                            onPressed: canInteract && !submitted
                                ? () => onSelect(letter)
                                : null)),
                    const SizedBox(height: 5),
                    _QuizSpeakerButton(
                        buttonKey: ValueKey('quiz-sound-$letter'),
                        size: compact ? 36 : 44,
                        color: GameDesign.tileColors[letterChoiceLabel(letter)
                                .codeUnits
                                .fold<int>(0, (a, b) => a + b) %
                            GameDesign.tileColors.length],
                        tooltip: 'Hear $letter sound',
                        onPressed: voice && canInteract && !submitted
                            ? () => onHearSound(letter)
                            : null),
                  ])),
              ]),
              SizedBox(height: gap),
              if (submitted)
                Semantics(
                    liveRegion: true,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (correct)
                        GameCorrectFrame(height: compact ? 34 : 44)
                      else
                        _QuizTextFrame(
                            child: SizedBox(
                                height: compact ? 20 : 26,
                                child: const Center(
                                    child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text("Let's learn this sound!",
                                            style: TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.w900,
                                                color: GameDesign.ink)))))),
                      const SizedBox(height: 4),
                      _QuizTextFrame(
                          key: const ValueKey('quiz-feedback-frame'),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            SizedBox(
                                height: compact ? 22 : 28,
                                child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(question.explanation,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: GameDesign.ink)))),
                            const SizedBox(height: 4),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var i = 0; i < question.word.length; i++)
                                    Container(
                                        width: compact ? 26 : 34,
                                        height: compact ? 26 : 34,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            color:
                                                i == question.position.wordIndex
                                                    ? const Color(0xFFFFE36B)
                                                    : const Color(0xFFF0EBF9),
                                            border: Border.all(
                                                color: i ==
                                                        question
                                                            .position.wordIndex
                                                    ? const Color(0xFFFFC400)
                                                    : const Color(0xFFD0C8DF),
                                                width: 2),
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(question.word[i],
                                                style: const TextStyle(
                                                    fontSize: 27,
                                                    fontWeight: FontWeight.w900,
                                                    color: GameDesign.ink)))),
                                ]),
                          ])),
                    ]))
              else
                SizedBox(
                    height: 44,
                    child: Center(
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ForestAudioButton(
                                key: const ValueKey('quiz-check-answer'),
                                label: 'Check Answer',
                                icon: Icons.check_circle_rounded,
                                onPressed: selected == null || !canInteract
                                    ? null
                                    : onCheck)))),
              if (reviewing)
                const SizedBox(
                    height: 16,
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                            'Practice review: original quiz score stays the same.',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800)))),
              const SizedBox(height: 4),
            ]);
      });
}

/// Live text on a bright, glossy panel; no artwork can obscure its contents.
class _QuizTextFrame extends StatelessWidget {
  const _QuizTextFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFF0065CB), width: 2),
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF99F6FF),
                Color(0xFF00B9FF),
                Color(0xFF0075E0)
              ]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x50302B80), blurRadius: 4, offset: Offset(0, 3))
          ]),
      padding: const EdgeInsets.all(4),
      child: Stack(alignment: Alignment.center, children: [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD77D), width: 2),
                gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFEF8), Color(0xFFFFF0D4)])),
            child: child),
        const Positioned(
            left: 0,
            top: 0,
            child: IgnorePointer(
                child: Icon(Icons.star_rounded,
                    size: 17,
                    color: Color(0xFFFFCF28),
                    shadows: [
                  Shadow(
                      color: Color(0xFFC77D00),
                      blurRadius: 1,
                      offset: Offset(0, 1))
                ]))),
        const Positioned(
            right: 0,
            bottom: 0,
            child: IgnorePointer(
                child: Icon(Icons.star_rounded,
                    size: 14,
                    color: Color(0xFFFFCF28),
                    shadows: [
                  Shadow(
                      color: Color(0xFFC77D00),
                      blurRadius: 1,
                      offset: Offset(0, 1))
                ]))),
      ]));
}

class _QuizSpeakerButton extends StatelessWidget {
  const _QuizSpeakerButton(
      {required this.buttonKey,
      required this.tooltip,
      required this.color,
      required this.size,
      required this.onPressed});
  final Key buttonKey;
  final String tooltip;
  final Color color;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
      dimension: size,
      child: Opacity(
          opacity: onPressed == null ? .65 : 1,
          child: DecoratedBox(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFFB56816), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x503E2454),
                        offset: Offset(0, 2),
                        blurRadius: 3)
                  ],
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(color, Colors.white, .45)!,
                        color,
                        Color.lerp(color, Colors.black, .15)!
                      ])),
              child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFFFF5D9), width: 2)),
                  child: Stack(fit: StackFit.expand, children: [
                    Positioned(
                        top: 3,
                        left: size * .18,
                        right: size * .18,
                        height: size * .22,
                        child: IgnorePointer(
                            child: DecoratedBox(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(size),
                                    gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xA6FFFFFF),
                                          Color(0x00FFFFFF)
                                        ]))))),
                    IconButton(
                        key: buttonKey,
                        tooltip: tooltip,
                        onPressed: withButtonSound(onPressed),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                            shape: const CircleBorder(),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white),
                        icon: Icon(Icons.volume_up_rounded, size: size * .57)),
                  ])))));
}
