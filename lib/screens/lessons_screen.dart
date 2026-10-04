import '../widgets/button_sound.dart';
import '../theme/kids_ui.dart';

import 'dart:math' as math;
import '../widgets/mascot_guide.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/learning_progress.dart';

import '../widgets/learner_widgets.dart';
import '../widgets/lessons_menu_page.dart';
import 'letter_sounds_screen.dart';
import 'letter_recognition_screen.dart';
import 'cvc_words_screen.dart';
import 'blending_sounds_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});
  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
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
        title: 'Letter Recognition',
        description: 'See and hear A–Z.',
        imageAsset: 'assets/images/lesson_logos/letter_recognition.png',
        accent: const Color(0xFF087F86),
        onPressed: () =>
            LearnerNavigation.open(context, const LetterRecognitionScreen()),
      ),
      lesson('Letter Sounds A–Z', 'Hear each letter sound.',
          List.generate(26, (i) => String.fromCharCode(65 + i)), false),
      lesson('Short Vowel Sounds', 'Practice A, E, I, O, U.',
          const ['A', 'E', 'I', 'O', 'U'], true),
      _LessonTile(
        title: 'CVC Words',
        description: 'Blend three sounds into a word.',
        imageAsset: 'assets/images/lesson_logos/cvc_words.png',
        accent: const Color(0xFFB45731),
        onPressed: () =>
            LearnerNavigation.open(context, const CvcWordsScreen()),
      ),
      _LessonTile(
        title: 'Blending Sounds',
        description: 'Build a word. Blend the sounds.',
        imageAsset: 'assets/images/lesson_logos/blending_sounds.png',
        accent: const Color(0xFF087F86),
        onPressed: () =>
            LearnerNavigation.open(context, const BlendingSoundsScreen()),
      ),
    ];
    return LessonsMenuPage(
      child: Column(children: [
        const MascotGuide(
          compact: true,
          mascot: LearningMascot.wigloo,
          message: 'Pick a lesson!',
        ),
        const SizedBox(height: 8),
        Expanded(child: LayoutBuilder(builder: (context, box) {
          final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final rows = (lessons.length / 2).ceil();
          final height = math.max(
              190.0 * scale,
              math.min(
                  220.0 * scale, (box.maxHeight - 10 * (rows - 1)) / rows));
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
          color: Color.lerp(Colors.white, accent, .07)!
              .withValues(alpha: KidsUi.cardOpacity),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: accent.withValues(alpha: .25))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: withButtonSound(onPressed),
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
