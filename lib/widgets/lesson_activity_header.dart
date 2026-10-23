import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/kids_ui.dart';
import '../data/lesson_instruction_scripts.dart';
import 'lesson_dialogue_prompt.dart';

const lessonHeaderAssets = 'assets/images/lesson_header';

/// The supplied blank sign, with a separately rendered lesson title.
class LessonTitleBanner extends StatelessWidget {
  const LessonTitleBanner({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 3,
        child: Stack(fit: StackFit.expand, children: [
          Image.asset('$lessonHeaderAssets/banner_lessons.png',
              key: const ValueKey('lessons-banner'),
              fit: BoxFit.contain,
              cacheWidth: 1008,
              excludeFromSemantics: true),
          Positioned.fill(
              child: FractionallySizedBox(
                  widthFactor: .78,
                  heightFactor: .56,
                  child: _FittedLessonText(
                      key: const ValueKey('lesson-title-content'),
                      text: title,
                      textKey: const ValueKey('lesson-title'),
                      fontSize: 26,
                      maxLines: 2))),
        ]),
      );
}

/// One short instruction at a time, matching the child's saved character.
class LessonInstructionDialogue extends StatelessWidget {
  const LessonInstructionDialogue(
      {super.key,
      required this.message,
      this.introduction = const [],
      this.introductionStatus});
  final String message;
  final List<String> introduction;
  final ValueListenable<LessonIntroductionStatus>? introductionStatus;

  @override
  Widget build(BuildContext context) {
    final girl = context.select<AppProvider, bool>(
        (provider) => provider.studentCharacter == 'girl');
    final character = girl ? 'girl' : 'boy';
    final ratio = girl ? 1927 / 816 : 1938 / 811;
    return LayoutBuilder(builder: (context, box) {
      final portrait = box.maxWidth * .23;
      final bubbleWidth = box.maxWidth - portrait;
      return SizedBox(
        height: math.max(portrait, bubbleWidth / ratio),
        child: Row(children: [
          SizedBox.square(
              dimension: portrait,
              child: Image.asset('$lessonHeaderAssets/${character}_profile.png',
                  key: const ValueKey('lesson-guide-profile'),
                  fit: BoxFit.contain,
                  cacheWidth: 360,
                  excludeFromSemantics: true)),
          Expanded(
              child: AspectRatio(
                  aspectRatio: ratio,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.asset(
                        '$lessonHeaderAssets/instructions_dialogue_$character.png',
                        key: const ValueKey('lesson-dialogue-art'),
                        fit: BoxFit.contain,
                        cacheWidth: 1100,
                        excludeFromSemantics: true),
                    Positioned.fill(
                        child: LayoutBuilder(builder: (context, bounds) {
                      return Padding(
                          padding: EdgeInsets.fromLTRB(
                              bounds.maxWidth * .20,
                              bounds.maxHeight * .36,
                              bounds.maxWidth * .20,
                              bounds.maxHeight * .26),
                          child: Semantics(
                              key: const ValueKey('lesson-dialogue-content'),
                              liveRegion: true,
                              child: LessonDialoguePrompt(
                                  message: message,
                                  introduction: introduction,
                                  status: introductionStatus,
                                  builder: (text) => _FittedLessonText(
                                      text: text,
                                      textKey: const ValueKey(
                                          'lesson-instruction-text'),
                                      fontSize: 21,
                                      maxLines: 3))));
                    })),
                  ]))),
        ]),
      );
    });
  }
}

/// Measure the actual scaled font so no text enters the decorative border.
class _FittedLessonText extends StatelessWidget {
  const _FittedLessonText(
      {super.key,
      required this.text,
      required this.textKey,
      required this.fontSize,
      required this.maxLines});
  final String text;
  final Key textKey;
  final double fontSize;
  final int maxLines;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        const style = TextStyle(
            inherit: false,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            height: 1.12,
            color: KidsUi.ink);
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        var low = 1.0, high = fontSize;
        for (var i = 0; i < 16; i++) {
          final size = (low + high) / 2;
          final painter = TextPainter(
              text: TextSpan(text: text, style: style.copyWith(fontSize: size)),
              textDirection: direction,
              textScaler: scaler,
              maxLines: maxLines)
            ..layout(maxWidth: box.maxWidth);
          final fits = !painter.didExceedMaxLines &&
              painter.height <= box.maxHeight &&
              painter.width <= box.maxWidth;
          painter.dispose();
          if (fits) {
            low = size;
          } else {
            high = size;
          }
        }
        return Center(
            child: Text(text,
                key: textKey,
                textAlign: TextAlign.center,
                style: style.copyWith(fontSize: low)));
      });
}
