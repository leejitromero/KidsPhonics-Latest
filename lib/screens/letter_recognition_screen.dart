import 'package:flutter/material.dart';
import '../widgets/letter_lesson_page.dart';

class LetterRecognitionScreen extends StatelessWidget {
  const LetterRecognitionScreen({super.key, this.initialLetter = 'A'});
  final String initialLetter;

  @override
  Widget build(BuildContext context) => LetterLessonPage(
      audio: LetterLessonAudio.name, initialLetter: initialLetter);
}
