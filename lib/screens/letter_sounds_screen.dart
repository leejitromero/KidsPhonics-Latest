import 'package:flutter/material.dart';
import '../widgets/letter_lesson_page.dart';
import 'vowel_sounds_screen.dart';

class LetterSoundsScreen extends StatelessWidget {
  final bool vowelsOnly;
  const LetterSoundsScreen({super.key, this.vowelsOnly = false});
  @override
  Widget build(BuildContext context) => vowelsOnly
      ? const VowelSoundsScreen()
      : const LetterLessonPage(audio: LetterLessonAudio.sound);
}
