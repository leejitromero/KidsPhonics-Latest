import '../widgets/button_sound.dart';
import '../widgets/mascot_guide.dart';
import '../widgets/lesson_picture.dart';
import '../data/lesson_example_data.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/mastery_question.dart';
import '../services/mastery_audio_service.dart';
import 'package:provider/provider.dart';
import '../data/letter_data.dart';
import '../providers/app_provider.dart';
import '../theme/kids_ui.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/floating_choice.dart';

class LetterMasteryCheckScreen extends StatefulWidget {
  final LetterItem letter;
  final MasteryAudio? audio;
  const LetterMasteryCheckScreen({super.key, required this.letter, this.audio});
  @override
  State<LetterMasteryCheckScreen> createState() =>
      _LetterMasteryCheckScreenState();
}

class _LetterMasteryCheckScreenState extends State<LetterMasteryCheckScreen> {
  int _question = 0, _correct = 0;
  String? _picked;
  bool _saving = false, _finished = false;
  late List<MasteryQuestion> _questions;
  late final MasteryAudio _audio;
  StreamSubscription<int>? _milestoneSubscription;
  int? _milestone;
  bool _heard = false, _playing = false;
  String? _audioError;
  MasteryQuestion get _current => _questions[_question];
  String get _answer => _current.answer;
  bool get _canAnswer =>
      !_saving &&
      !_playing &&
      _picked == null &&
      (!_current.requiresAudio || _heard);

  @override
  void initState() {
    super.initState();
    _questions = buildLessonPracticeQuestions(widget.letter.letter);
    _audio = widget.audio ?? LocalMasteryAudio();
    _milestoneSubscription =
        context.read<AppProvider>().masteryMilestones.listen((milestone) {
      if (mounted) setState(() => _milestone = milestone);
    });
  }

  @override
  void dispose() {
    unawaited(_milestoneSubscription?.cancel());
    unawaited(_audio.dispose());
    super.dispose();
  }

  Future<void> _hear() async {
    if (_playing || _picked != null) return;
    setState(() {
      _playing = true;
      _audioError = null;
    });
    // Explicit listening is required assessment content, independent of the
    // optional voice-assistance preference. No preference is changed.
    if (widget.audio == null) {
      final p = context.read<AppProvider>();
      await p.phonicsAudio.stop();
      await p.audio.stop();
      if (!mounted) return;
    }
    final played = await _audio.play(_current.audioPhrase!);
    if (!mounted) return;
    setState(() {
      _playing = false;
      _heard = _heard || played;
      if (!played) _audioError = 'Word could not play. Tap to try again.';
    });
  }

  Future<void> _pick(String answer) async {
    if (!_canAnswer) return;
    final provider = context.read<AppProvider>();
    final correct = answer == _answer;
    setState(() {
      _picked = answer;
      _saving = true;
      if (correct) _correct++;
    });
    unawaited(
        correct ? provider.audio.playCorrect() : provider.audio.playWrong());
    await provider.recordLetterPractice(widget.letter.letter, correct);
    if (_question == 4) {
      await provider.completeLetterAssessment(
          widget.letter.letter, _correct, 5);
    }
    if (!mounted) return;
    setState(() => _saving = false);
  }

  void _next() {
    if (_saving || _picked == null || _finished) return;
    setState(() {
      if (_question == 4) {
        _finished = true;
        return;
      }
      _question++;
      _picked = null;
      _heard = false;
      _audioError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mastered = context
        .watch<AppProvider>()
        .getLetterProgress(widget.letter.letter)
        .mastered;
    return GameScaffold(
      showHeader: true,
      answerResult: _finished || _picked == null ? null : _picked == _answer,
      compactGuide: true,
      mascot: LearningMascot.wigloo,
      title: 'Quick Check',
      instructions: 'Choose one answer.',
      instructionPanel: _finished ? null : _instructionPanel(),
      current: _finished ? null : _question + 1,
      total: _finished ? null : 5,
      hasProgress: (_question > 0 || _picked != null) && !_finished,
      onLeave: () => _audio.stop(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_finished) ...[
          Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFE1F3FC), Colors.white]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFB6DCEC)),
              ),
              child: Column(children: [
                const MascotPortrait(mascot: LearningMascot.wigloo, size: 80),
                Text(_correct >= 4 ? 'Great work!' : 'Keep practicing!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: choiceBlue)),
                Text('Score: $_correct / 5',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        5,
                        (i) => Icon(
                            i < _correct
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 32,
                            color: i < _correct
                                ? const Color(0xFFD99413)
                                : const Color(0xFF7796A7)))),
                const SizedBox(height: 12),
                Text(
                    mastered
                        ? (_correct < 4 ? 'Still Mastered' : 'MASTERED')
                        : 'PRACTICED',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24)),
                if (mastered && _correct < 4)
                  const Text('Your earlier passing check still counts.',
                      textAlign: TextAlign.center),
                if (_milestone != null)
                  Text('Achievement: $_milestone letters mastered!',
                      textAlign: TextAlign.center),
              ])),
          const SizedBox(height: 24),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: choiceBlue, foregroundColor: Colors.white),
              onPressed: withButtonSound(() => setState(() {
                    _question = 0;
                    _correct = 0;
                    _picked = null;
                    _finished = false;
                    _milestone = null;
                    _questions =
                        buildLessonPracticeQuestions(widget.letter.letter);
                    _heard = false;
                    _audioError = null;
                  })),
              child: const Text('Try Again')),
          TextButton(
              onPressed: withButtonSound(() => Navigator.pop(context)),
              child: const Text('Back to Lesson')),
        ] else ...[
          if (_current.requiresAudio) ...[
            const SizedBox(height: 4),
            Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                    key: const ValueKey('hear-sound'),
                    onPressed: withButtonSound(
                        _playing || _picked != null ? null : _hear),
                    icon: Icon(
                        _playing
                            ? Icons.graphic_eq_rounded
                            : _heard
                                ? Icons.replay_rounded
                                : Icons.volume_up,
                        size: 20),
                    label: Text(_playing
                        ? 'Listening…'
                        : _heard
                            ? 'Listen Again'
                            : 'Hear Word'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF087F86),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            _playing ? const Color(0xFFFFDF88) : null,
                        disabledForegroundColor:
                            _playing ? const Color(0xFF49315D) : null,
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        minimumSize: const Size(0, 44)))),
            if (!_heard && !_playing) const Text('Listen first, then choose.'),
            if (_audioError != null) Text(_audioError!),
          ],
          const SizedBox(height: 8),
          LayoutBuilder(
              builder: (context, box) => Wrap(spacing: 10, children: [
                    ..._current.options.map((option) => SizedBox(
                        width: MediaQuery.textScalerOf(context).scale(18) > 28
                            ? box.maxWidth
                            : (box.maxWidth - 10) / 2,
                        child: _answerCard(option))),
                  ])),
          if (_picked != null) ...[
            GameFeedback(
                correct: _picked == _answer,
                detail: _picked == _answer ? null : 'The answer is $_answer.'),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: choiceBlue, foregroundColor: Colors.white),
                onPressed: withButtonSound(_saving ? null : _next),
                child: Text(_saving
                    ? 'Saving…'
                    : _question == 4
                        ? 'See Result'
                        : 'Next Question')),
          ],
        ],
      ]),
    );
  }

  Widget _answerCard(String option) {
    final selected = _picked == option;
    final color = selected
        ? (option == _answer ? KidsUi.correct : KidsUi.incorrect)
        : choiceBlue;
    final hasPicture = practiceExamples.any((e) => e.word == option);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FloatingChoice(
        enabled: _canAnswer,
        seed: _current.options.indexOf(option),
        child: ElevatedButton(
          key: ValueKey(option),
          onPressed: withButtonSound(_canAnswer ? () => _pick(option) : null),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: color.withValues(
                alpha: _picked == null && !_canAnswer ? .7 : 1),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
            elevation: 3,
            shadowColor: color.withValues(alpha: .3),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0x99FFFFFF), width: 2)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (hasPicture)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: const Color(0xFFF2FAFF),
                    borderRadius: BorderRadius.circular(14)),
                child: LessonPicture(
                    example:
                        practiceExamples.firstWhere((e) => e.word == option),
                    size: 64),
              ),
            if (hasPicture) const SizedBox(height: 6),
            Text(option,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: hasPicture ? 18 : 32,
                    fontWeight: FontWeight.w900)),
            if (selected)
              Icon(
                  option == _answer
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _instructionPanel() => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE2F3FC), Colors.white],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFB6DCEC), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7052CA).withValues(alpha: .15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF392657).withValues(alpha: .06),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MascotPortrait(mascot: LearningMascot.wigloo, size: 48),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Letter ${widget.letter.letter} adventure',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: choiceBlue)),
                        const Text('One little step at a time!',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF42677D))),
                        const SizedBox(height: 8),
                        Row(
                            children: List.generate(
                                5,
                                (i) => Expanded(
                                        child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: AnimatedContainer(
                                        duration: MediaQuery
                                                .disableAnimationsOf(context)
                                            ? Duration.zero
                                            : const Duration(milliseconds: 300),
                                        height: 7,
                                        decoration: BoxDecoration(
                                            color: i <= _question
                                                ? choiceBlue
                                                : const Color(0xFFD4E5EF),
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                      ),
                                    )))),
                      ]),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFE6DDF3)),
            ),
            Text(_current.prompt,
                style: const TextStyle(
                    fontSize: 22,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: KidsUi.ink)),
            if (_current.picture != null) ...[
              const SizedBox(height: 12),
              Center(
                child: LessonPicture(
                    example: practiceExamples
                        .firstWhere((e) => e.word == _current.picture),
                    size: 104),
              ),
            ],
          ],
        ),
      );
}
