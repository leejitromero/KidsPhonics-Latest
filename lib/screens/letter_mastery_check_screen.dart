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
      await p.voiceFeedback.stop();
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
      compactGuide: true,
      mascot: LearningMascot.wigloo,
      title: 'Quick Check',
      instructions: 'Listen or read the question. Choose one answer.',
      current: _finished ? null : _question + 1,
      total: _finished ? null : 5,
      hasProgress: (_question > 0 || _picked != null) && !_finished,
      onLeave: () => _audio.stop(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_finished) ...[
          const Icon(Icons.stars, size: 64, color: KidsUi.correct),
          Text(_correct >= 4 ? 'Great work!' : 'Keep practicing!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28)),
          Text('Score: $_correct / 5',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32)),
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
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () => setState(() {
                    _question = 0;
                    _correct = 0;
                    _picked = null;
                    _finished = false;
                    _milestone = null;
                    _questions =
                        buildLessonPracticeQuestions(widget.letter.letter);
                    _heard = false;
                    _audioError = null;
                  }),
              child: const Text('Try Again')),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Lesson')),
        ] else ...[
          Text(_current.prompt,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          if (_current.picture != null)
            Center(
                child: LessonPicture(
                    example: lessonExamples
                        .firstWhere((e) => e.word == _current.picture),
                    size: 120)),
          if (_current.requiresAudio) ...[
            const SizedBox(height: 16),
            Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                    key: const ValueKey('hear-sound'),
                    onPressed: _playing || _picked != null ? null : _hear,
                    icon: const Icon(Icons.volume_up, size: 20),
                    label: Text(_playing ? 'Playing…' : 'Hear Word'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF087F86),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        minimumSize: const Size(0, 44)))),
            if (!_heard && !_playing) const Text('Listen first, then choose.'),
            if (_audioError != null) Text(_audioError!),
          ],
          const SizedBox(height: 16),
          LayoutBuilder(
              builder: (context, box) => Wrap(spacing: 10, children: [
                    ..._current.options.map((option) => SizedBox(
                        width: MediaQuery.textScalerOf(context).scale(18) > 28
                            ? box.maxWidth
                            : (box.maxWidth - 10) / 2,
                        child: GameAnswerButton(
                            accent: [
                              const Color(0xFF7052CA),
                              const Color(0xFF167769),
                              const Color(0xFFB45731),
                              const Color(0xFF256AB0)
                            ][_current.options.indexOf(option) % 4],
                            visual: lessonExamples.any((e) => e.word == option)
                                ? LessonPicture(
                                    example: lessonExamples
                                        .firstWhere((e) => e.word == option),
                                    size: 56)
                                : null,
                            buttonKey: ValueKey(option),
                            label: option,
                            selected: _picked == option,
                            result:
                                _picked == option ? option == _answer : null,
                            onPressed:
                                _canAnswer ? () => _pick(option) : null))),
                  ])),
          if (_picked != null) ...[
            GameFeedback(
                correct: _picked == _answer,
                detail: _picked == _answer ? null : 'The answer is $_answer.'),
            ElevatedButton(
                onPressed: _saving ? null : _next,
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
}
