import 'package:flutter/material.dart';
import '../widgets/letter_lesson_page.dart';

class LetterRecognitionScreen extends StatelessWidget {
  const LetterRecognitionScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const LetterLessonPage(audio: LetterLessonAudio.name);
}
