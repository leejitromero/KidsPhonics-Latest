import '../widgets/button_sound.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/lesson_journey.dart';
import '../providers/app_provider.dart';
import '../widgets/learner_widgets.dart';

class JourneyLessonScreen extends StatefulWidget {
  const JourneyLessonScreen({super.key, required this.lesson});
  final JourneyLesson lesson;
  @override
  State<JourneyLessonScreen> createState() => _JourneyLessonScreenState();
}

class _JourneyLessonScreenState extends State<JourneyLessonScreen> {
  int _index = 0, _correct = 0;
  String? _answer;
  bool _saving = false, _done = false;

  Future<void> _choose(String answer) async {
    if (_answer != null || _saving) return;
    final question = widget.lesson.questions[_index];
    setState(() {
      _answer = answer;
      if (answer == question.answer) _correct++;
    });
    await context
        .read<AppProvider>()
        .recordDailyAnswer(correct: answer == question.answer);
  }

  Future<void> _next() async {
    if (_saving) return;
    if (_index + 1 < widget.lesson.questions.length) {
      setState(() {
        _index++;
        _answer = null;
      });
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AppProvider>().completeJourneyLesson(
          widget.lesson.id, _correct, widget.lesson.questions.length);
      if (mounted) setState(() => _done = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.lesson.questions[_index];
    return LearnerPage(
      title: widget.lesson.title,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.lesson.description, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 16),
        if (_done) ...[
          const Icon(Icons.celebration, size: 64, color: Color(0xFF7052CA)),
          const Text('Lesson complete!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          Text('$_correct / ${widget.lesson.questions.length} correct',
              textAlign: TextAlign.center),
          const Text('Keep practicing to build confidence.',
              textAlign: TextAlign.center),
          ElevatedButton(
              onPressed: withButtonSound(() => Navigator.pop(context)),
              child: const Text('Back to Lessons')),
        ] else ...[
          Text('Activity ${_index + 1} / ${widget.lesson.questions.length}'),
          const SizedBox(height: 12),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(question.prompt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800)))),
          if (question.audio != null)
            AudioButton(
                key: ValueKey(_index),
                phrase: question.audio!,
                label: 'Listen'),
          const SizedBox(height: 16),
          for (final choice in question.choices)
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                    onPressed: withButtonSound(
                        _answer == null ? () => _choose(choice) : null),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 56)),
                    child: Text(choice, style: const TextStyle(fontSize: 22)))),
          if (_answer != null) ...[
            Text(
                _answer == question.answer
                    ? 'Well done!'
                    : 'Let’s learn this one.',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(question.explanation, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: withButtonSound(_saving ? null : _next),
                child: Text(_index + 1 == widget.lesson.questions.length
                    ? 'Finish Lesson'
                    : 'Next')),
          ],
        ],
      ]),
    );
  }
}
