import '../data/game_session_order.dart';
import 'dart:math' as math;
import '../widgets/mascot_guide.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/learning_progress.dart';
import '../data/phonics_activity_data.dart';
import '../widgets/learner_widgets.dart';
import 'letter_sounds_screen.dart';
import 'rhyming_words_screen.dart';
import 'tricky_letters_screen.dart';

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
              '${rhymeRoundsForDifficulty(d).length.clamp(0, GameSessionOrder.roundLength(d))} words · ${rhymeRoundsForDifficulty(d).first.options.length} choices',
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
      return _LessonTile(
          imageAsset:
              'assets/images/lesson_logos/${vowels ? 'vowel_sounds' : 'letter_sounds'}.png',
          accent: vowels ? const Color(0xFF167769) : const Color(0xFF7052CA),
          title: title,
          description: description,
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

    final lessons = <Widget>[
      _LessonTile(
        title: 'Practice My Tricky Letters',
        description: 'A short practice picked from your letter progress.',
        imageAsset: 'assets/images/lesson_logos/tricky_letters.png',
        accent: const Color(0xFF167769),
        status: 'Practice',
        onPressed: () =>
            LearnerNavigation.open(context, const TrickyLettersScreen()),
      ),
      lesson('Letter Sounds A–Z', 'Learn letters and their sounds.',
          List.generate(26, (i) => String.fromCharCode(65 + i)), false),
      lesson('Short Vowel Sounds', 'Practice A, E, I, O, U.',
          const ['A', 'E', 'I', 'O', 'U'], true),
      _LessonTile(
        title: 'Rhyming Words',
        description: 'Find words that rhyme.',
        imageAsset: 'assets/images/lesson_logos/rhyming_words.png',
        accent: const Color(0xFFB45731),
        status: p.rhymingWordsDone ? 'Completed' : 'Ready to Play',
        onPressed: _opening ? null : _rhyme,
      ),
    ];
    return LearnerPage(
      title: 'Lessons',
      fitViewport: true,
      child: Column(children: [
        const MascotGuide(
          compact: true,
          mascot: LearningMascot.wigloo,
          message: 'Choose a lesson. Let’s learn together!',
        ),
        const SizedBox(height: 8),
        Expanded(child: LayoutBuilder(builder: (context, box) {
          final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final height = math.max(
              150.0 * scale, math.min(220.0 * scale, (box.maxHeight - 10) / 2));
          return GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: height,
              children: lessons);
        })),
      ]),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile(
      {required this.title,
      required this.description,
      required this.imageAsset,
      required this.accent,
      required this.onPressed,
      this.detail,
      this.status,
      this.progress});
  final String title, description, imageAsset;
  final Color accent;
  final VoidCallback? onPressed;
  final String? detail, status;
  final double? progress;

  @override
  Widget build(BuildContext context) => Semantics(
        hint: description,
        child: Material(
          color: Color.lerp(Colors.white, accent, .07),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: accent.withValues(alpha: .25))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(children: [
                Expanded(
                    child: Image.asset(imageAsset,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                        cacheWidth:
                            (160 * MediaQuery.devicePixelRatioOf(context))
                                .ceil())),
                const SizedBox(height: 4),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                if (detail != null)
                  Text(detail!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11)),
                if (progress != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          color: accent,
                          borderRadius: BorderRadius.circular(4))),
                if (status != null)
                  Text(status!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent)),
              ]),
            ),
          ),
        ),
      );
}
