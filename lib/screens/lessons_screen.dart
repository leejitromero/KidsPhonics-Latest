import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/lesson_menu_art.dart';
import '../models/learning_progress.dart';
import '../models/word_lesson_progress.dart';
import '../providers/app_provider.dart';
import '../theme/kids_ui.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/lesson_menu_card.dart';
import '../widgets/lesson_menu_header.dart';
import '../widgets/main_navigation_scope.dart';
import '../widgets/main_navigation_shell.dart';
import '../widgets/school_room_body.dart';
import '../widgets/student_character_picker.dart';
import 'blending_sounds_screen.dart';
import 'alphabet_pictures_screen.dart';
import 'cvc_words_screen.dart';
import 'letter_recognition_screen.dart';
import 'letter_sounds_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});
  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  bool _opening = false;
  final _scroll = ScrollController();
  Future<void> _open(Widget page) async {
    final p = context.read<AppProvider>();
    if (_opening || !p.isReady || p.timeLimitReached) return;
    setState(() => _opening = true);
    await LearnerNavigation.open(context, page, fadeTransition: true);
    if (mounted) setState(() => _opening = false);
  }

  Future<void> _edit() async {
    if (_opening || !context.read<AppProvider>().isReady) return;
    setState(() => _opening = true);
    await showDialog<void>(
        context: context, builder: (_) => const StudentCharacterPicker());
    if (mounted) setState(() => _opening = false);
  }

  Future<void> _back() async {
    if (_opening) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      await navigateKidsTab(context, KidsDestination.home);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final enabled = p.isReady && !_opening && !p.timeLimitReached;
    final letters = p.quickCheckLetters;
    final vowels = letters.where((letter) => 'AEIOU'.contains(letter.letter));
    LessonMenuCard letterCard(String id, String title, Color color,
            Iterable<LetterProgress> records, Widget page) =>
        LessonMenuCard(
            id: id,
            title: title,
            imageAsset: lessonMenuArt[id]!,
            color: color,
            mastered: records.where((record) => record.mastered).length,
            total: records.length,
            started: records
                .any((record) => record.status != LearningStatus.notStarted),
            onPressed: enabled ? () => _open(page) : null);
    LessonMenuCard wordCard(
        String id, String title, Color color, WordLesson lesson, Widget page) {
      final progress = p.wordLessonProgress(lesson);
      return LessonMenuCard(
          id: id,
          title: title,
          imageAsset: lessonMenuArt[id]!,
          color: color,
          mastered: progress.completed.length,
          total: lesson.words.length,
          started: progress.started,
          unit: lesson == WordLesson.cvc ? 'Practiced' : 'Completed',
          onPressed: enabled ? () => _open(page) : null);
    }

    final lessons = [
      letterCard('letter_recognition', 'Letter Recognition',
          const Color(0xFFFF48B2), letters, const LetterRecognitionScreen()),
      letterCard('letter_sounds', 'Letter Sounds A-Z', const Color(0xFF00BEF4),
          letters, const LetterSoundsScreen()),
      letterCard('vowel_sounds', 'Short Vowel Sounds', const Color(0xFFFFCC27),
          vowels, const LetterSoundsScreen(vowelsOnly: true)),
      LessonMenuCard(
          id: 'alphabet_pictures',
          title: 'Alphabet & Pictures',
          imageAsset: lessonMenuArt['alphabet_pictures']!,
          color: const Color(0xFF36C796),
          mastered: letters.where((record) => record.wordListens > 0).length,
          total: 26,
          unit: 'Listened',
          started: letters.any((record) => record.viewCount > 0),
          onPressed:
              enabled ? () => _open(const AlphabetPicturesScreen()) : null),
      wordCard('cvc_words', 'CVC Words', const Color(0xFFA257FF),
          WordLesson.cvc, const CvcWordsScreen()),
      wordCard('blending_sounds', 'Blending Sounds', const Color(0xFFFF48B2),
          WordLesson.blending, const BlendingSoundsScreen()),
    ];
    return Theme(
        data: KidsUi.theme,
        child: Scaffold(
            body: SchoolRoomBody(
                room: SchoolRoom.lessons,
                navigationDestination: KidsDestination.home,
                navigationOnRoute: true,
                child: LayoutBuilder(builder: (context, box) {
                  final width = math.min(560.0, box.maxWidth - 8);
                  final cardWidth = (width - 12) / 2;
                  final available = box.maxHeight -
                      LessonMenuHeader.heightFor(context, box.maxWidth - 8) -
                      48;
                  final cardHeight = math.max(
                      LessonMenuCard.minimumHeight(context, cardWidth),
                      math.min(LessonMenuCard.heightFor(context, cardWidth),
                          available / 3));
                  return SingleChildScrollView(
                      key: const PageStorageKey('lessons-scroll'),
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
                      child: Column(children: [
                        LessonMenuHeader(
                            character: p.studentCharacter,
                            onBack: _opening ? null : _back,
                            onEdit: _opening ? null : _edit),
                        const SizedBox(height: 10),
                        Center(
                            child: SizedBox(
                                width: width,
                                child: Wrap(
                                    key: const ValueKey('lessons-grid'),
                                    alignment: WrapAlignment.center,
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      for (final lesson in lessons)
                                        SizedBox(
                                            width: cardWidth,
                                            height: cardHeight,
                                            child: lesson)
                                    ]))),
                      ]));
                }))));
  }
}
