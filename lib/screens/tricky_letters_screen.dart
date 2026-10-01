import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/letter_data.dart';
import '../providers/app_provider.dart';
import '../widgets/floating_choice.dart';
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
    final mastered = p.masteredLetterCount == 26;
    return LearnerPage(
      title: 'My Tricky Letters',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const MascotGuide(
          compact: true,
          mascot: LearningMascot.wigloo,
          message: 'Little steps, big progress! Let us practice together.',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(colors: [Color(0xFFE3F4FC), Colors.white]),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFC0E1F0)),
          ),
          child: Row(children: [
            Image.asset('assets/images/lesson_logos/tricky_letters.png',
                width: 64, height: 64, cacheWidth: 192),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    letters.isEmpty
                        ? 'Every letter is a little adventure'
                        : 'Your practice picks',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF174D6B))),
                const SizedBox(height: 4),
                Text(
                    letters.isEmpty
                        ? 'Listen. Discover. Grow.'
                        : 'One letter \u2022 5 quick questions',
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF42677D))),
              ],
            )),
          ]),
        ),
        const SizedBox(height: 14),
        if (letters.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .9),
                borderRadius: BorderRadius.circular(22)),
            child: Column(children: [
              Icon(
                  mastered
                      ? Icons.workspace_premium_rounded
                      : Icons.auto_awesome_rounded,
                  size: 44,
                  color: choiceBlue),
              const SizedBox(height: 8),
              Text(
                  mastered
                      ? 'You mastered every letter!'
                      : 'Discover your letters!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                  mastered
                      ? 'Amazing work! Keep your sounds shining with a little practice.'
                      : 'Try a Quick Check in Letter Sounds. Your practice picks will appear here.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: choiceBlue,
                      minimumSize: const Size(0, 48)),
                  onPressed: () => LearnerNavigation.open(
                      context, const LetterSoundsScreen()),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Explore Letter Sounds')),
            ]),
          )
        else ...[
          for (var i = 0; i < letters.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: FloatingChoice(
                seed: i,
                child: Material(
                  color: Colors.white,
                  elevation: 2,
                  shadowColor: choiceBlue.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('tricky-letter-${letters[i].letter}'),
                    onTap: () => LearnerNavigation.open(
                        context,
                        LetterMasteryCheckScreen(
                            letter: letterContent(letters[i].letter))),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Container(
                            width: 54,
                            height: 54,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: choiceBlue,
                                borderRadius: BorderRadius.circular(16)),
                            child: Text(letters[i].letter,
                                style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Practice ${letters[i].letter}',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF174D6B))),
                              const SizedBox(height: 3),
                              Text(
                                  i == 0
                                      ? 'Start here \u2022 5 questions'
                                      : '5 questions \u2022 Take your time',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF42677D))),
                            ])),
                        const Icon(Icons.play_circle_fill_rounded,
                            size: 30, color: choiceBlue),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                  'Your picks update as you learn. Every little try counts!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF42677D)))),
        ],
      ]),
    );
  }
}

