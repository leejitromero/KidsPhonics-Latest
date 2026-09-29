import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/letter_data.dart';
import '../providers/app_provider.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/mascot_guide.dart';
import 'letter_mastery_check_screen.dart';
import 'letter_sounds_screen.dart';

class TrickyLettersScreen extends StatelessWidget {
  const TrickyLettersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final letters = p.lettersNeedingPractice.take(3).toList();
    return LearnerPage(
      title: 'My Tricky Letters',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const MascotGuide(
            mascot: LearningMascot.wigloo,
            message: 'A little practice helps! Let’s try one letter together.'),
        const SizedBox(height: 20),
        if (letters.isEmpty) ...[
          const Icon(Icons.auto_awesome_rounded,
              size: 56, color: Color(0xFF167769)),
          const SizedBox(height: 12),
          Text(
              p.masteredLetterCount == 26
                  ? 'You mastered every letter!'
                  : 'Let’s discover your letters!',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text(
              'No letters need extra practice yet. Explore Letter Sounds and try a Quick Check.',
              textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton.icon(
              onPressed: () =>
                  LearnerNavigation.open(context, const LetterSoundsScreen()),
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Explore Letter Sounds')),
        ] else ...[
          const Text('Choose one little challenge',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
              '5 questions for one letter. You can stop after each practice.'),
          const SizedBox(height: 16),
          for (final letter in letters)
            LearnerActivityCard(
              key: ValueKey('tricky-letter-${letter.letter}'),
              compactFloating: true,
              title: 'Letter ${letter.letter}',
              description: 'Listen, choose, and build your confidence.',
              icon: Icons.abc_rounded,
              actionLabel: 'Practice ${letter.letter}',
              detail: letter == letters.first
                  ? 'Suggested first · 5 questions'
                  : '5 questions',
              onPressed: () => LearnerNavigation.open(
                  context,
                  LetterMasteryCheckScreen(
                      letter: letterContent(letter.letter))),
            ),
          const Text(
              'Chosen from your practiced letters that are not yet mastered. Your list updates as you learn.',
              style: TextStyle(fontSize: 14, color: Color(0xFF655677))),
        ],
      ]),
    );
  }
}
