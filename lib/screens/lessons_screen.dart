import '../widgets/mascot_guide.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/learning_progress.dart';
import '../data/phonics_activity_data.dart';
import '../widgets/learner_widgets.dart';
import 'letter_sounds_screen.dart';
import 'rhyming_words_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});
  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  bool _opening = false;
  Future<void> _rhyme() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final difficulty = await chooseGameDifficulty(
          context,
          'Rhyming Words',
          (d) =>
              '${rhymeRoundsForDifficulty(d).length} words · ${rhymeRoundsForDifficulty(d).first.options.length} choices',
          mascot: LearningMascot.wigloo,
          lessonStyle: true);
      if (!mounted || difficulty == null) return;
      await LearnerNavigation.open(
          context, RhymingWordsScreen(difficulty: difficulty));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    Widget lesson(
        String title, String description, List<String> letters, bool vowels) {
      final mastered = vowels ? p.masteredVowelCount : p.masteredLetterCount;
      final started =
          letters.any((l) => p.getLetterStatus(l) != LearningStatus.notStarted);
      return LearnerActivityCard(
          compactFloating: true,
          actionLabel: 'Learn',
          accent: vowels ? const Color(0xFF167769) : const Color(0xFF7052CA),
          title: title,
          description: description,
          icon: vowels ? Icons.music_note : Icons.abc,
          detail: '$mastered / ${letters.length} Mastered',
          status: mastered == letters.length
              ? 'Completed'
              : started
                  ? 'In Progress'
                  : 'Not Started',
          progress: mastered / letters.length,
          onPressed: () => LearnerNavigation.open(
              context, LetterSoundsScreen(vowelsOnly: vowels)));
    }

    return LearnerPage(
        title: 'Lessons',
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const MascotGuide(
              compact: true,
              mascot: LearningMascot.wigloo,
              message: 'Choose a lesson. Explore letters, sounds, and words.'),
          const SizedBox(height: 16),
          lesson('Letter Sounds A–Z', 'Learn letters and their sounds.',
              List.generate(26, (i) => String.fromCharCode(65 + i)), false),
          lesson('Short Vowel Sounds', 'Practice A, E, I, O, U.',
              const ['A', 'E', 'I', 'O', 'U'], true),
          LearnerActivityCard(
              compactFloating: true,
              accent: const Color(0xFFB45731),
              title: 'Rhyming Words',
              description: 'Find words that rhyme.',
              icon: Icons.record_voice_over,
              status: p.rhymingWordsDone ? 'Completed' : 'Ready to Play',
              onPressed: _opening ? null : _rhyme),
        ]));
  }
}
