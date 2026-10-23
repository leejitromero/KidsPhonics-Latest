import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/kids_ui.dart';
import 'animated_screen_art.dart';
import 'button_sound.dart';
import 'lesson_activity_header.dart';
import '../data/lesson_instruction_scripts.dart';

/// Full-screen lesson scenery with the supplied sign above the lesson content.
class LessonsMenuPage extends StatelessWidget {
  const LessonsMenuPage(
      {super.key,
      required this.title,
      required this.instruction,
      this.introduction = const [],
      this.introductionStatus,
      required this.child});
  final List<String> introduction;
  final ValueListenable<LessonIntroductionStatus>? introductionStatus;
  final String title, instruction;
  final Widget child;
  static const bannerAsset = '$lessonHeaderAssets/banner_lessons.png';

  @override
  Widget build(BuildContext context) => Theme(
        data: KidsUi.theme,
        child: Scaffold(
          backgroundColor: const Color(0xFF94DAFA),
          body: LayoutBuilder(builder: (context, box) {
            final safe = MediaQuery.paddingOf(context);
            final availableWidth = box.maxWidth - safe.left - safe.right;
            final bannerWidth = math.min(288.0, availableWidth - 128);
            final bannerHeight = bannerWidth / 3;
            return Stack(fit: StackFit.expand, children: [
              const AnimatedScreenArt(
                frames: lessonFrames,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                blend: true,
                frameDuration: Duration(seconds: 3),
              ),
              Positioned(
                top: safe.top + 8,
                left: safe.left + 12,
                right: safe.right + 12,
                bottom: safe.bottom + 12,
                child: Column(children: [
                  SizedBox(
                      height: math.max(48, bannerHeight),
                      child: Center(
                          child: SizedBox(
                              width: bannerWidth,
                              child: LessonTitleBanner(title: title)))),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: LessonInstructionDialogue(
                          message: instruction,
                          introduction: introduction,
                          introductionStatus: introductionStatus)),
                  const SizedBox(height: 8),
                  Expanded(
                      child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: child))),
                ]),
              ),
              Positioned(
                top: safe.top + 8,
                left: safe.left + 8,
                child: IconButton.filledTonal(
                  tooltip: 'Back',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: const Color(0xFF9148EC),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFEEE0FF), width: 2),
                    shape: const CircleBorder(),
                    elevation: 4,
                    shadowColor: const Color(0xFF6331A9),
                  ),
                  onPressed: withButtonSound(() => Navigator.maybePop(context)),
                  icon: const Stack(clipBehavior: Clip.none, children: [
                    Icon(Icons.arrow_back_rounded),
                    Positioned(
                        right: -10,
                        bottom: -9,
                        child: Icon(Icons.star_rounded,
                            size: 18, color: Color(0xFFFFD52E))),
                  ]),
                ),
              ),
            ]);
          }),
        ),
      );
}
