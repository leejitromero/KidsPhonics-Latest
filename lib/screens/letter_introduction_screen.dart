import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/letter_data.dart';
import '../data/lesson_example_data.dart';
import '../models/learning_progress.dart';
import '../providers/app_provider.dart';
import '../theme/kids_ui.dart';
import '../widgets/button_sound.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/lesson_picture.dart';
import 'letter_mastery_check_screen.dart';

/// A letter-specific teaching step before the learner's first Quick Check.
class LetterIntroductionScreen extends StatefulWidget {
  const LetterIntroductionScreen({super.key, required this.letter});
  final String letter;
  @override
  State<LetterIntroductionScreen> createState() =>
      _LetterIntroductionScreenState();
}

class _LetterIntroductionScreenState extends State<LetterIntroductionScreen> {
  AppProvider? _provider;
  bool _opening = false;
  LessonExample get _example =>
      lessonExamples.firstWhere((e) => e.letter == widget.letter);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_provider != null) return;
    _provider = context.read<AppProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_provider!.markLetterViewed(widget.letter));
    });
  }

  @override
  void dispose() {
    unawaited(_provider?.phonicsAudio.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
      data: KidsUi.theme,
      child: Scaffold(
        appBar: AppBar(title: Text('Meet ${widget.letter}')),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('${widget.letter}  ${widget.letter.toLowerCase()}',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 64, fontWeight: FontWeight.w900)),
          Center(child: LessonPicture(example: _example, size: 190)),
          const SizedBox(height: 12),
          Text(_example.example,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          for (final (kind, label, phrase) in [
            (LetterListeningKind.name, 'Hear Letter', _example.letterAudioKey),
            (LetterListeningKind.sound, 'Hear Sound', _example.soundAudioKey),
            (LetterListeningKind.word, 'Hear Word', _example.wordAudioKey),
          ])
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AudioButton(
                    key: ValueKey('introduce-${kind.name}'),
                    phrase: phrase,
                    label: label,
                    compact: true,
                    onPlayed: () =>
                        _provider!.recordLetterListening(widget.letter, kind))),
          if (_example.soundNote != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_example.soundNote!, textAlign: TextAlign.center)),
          FilledButton.icon(
              key: const ValueKey('introduction-quick-check'),
              onPressed: withButtonSound(_opening
                  ? null
                  : () async {
                      setState(() => _opening = true);
                      await _provider!.phonicsAudio.stop();
                      if (!context.mounted) return;
                      await LearnerNavigation.open(
                          context,
                          LetterMasteryCheckScreen(
                              letter: letterContent(widget.letter)));
                      if (mounted) setState(() => _opening = false);
                    }),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Try Quick Check')),
          const SizedBox(height: 8),
          const Text(
              'Listening is practice. Quick Check shows what you remember.',
              textAlign: TextAlign.center),
        ])),
      ));
}
