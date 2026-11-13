import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../controllers/cvc_lesson_controller.dart';
import '../theme/kids_ui.dart';
import 'cvc_letter_tile.dart';

/// Reading is the focus: three independent letter frames and the blended word.
class CvcWordBoard extends StatelessWidget {
  const CvcWordBoard({super.key, required this.lesson, this.availableHeight});
  final CvcLessonController lesson;
  final double? availableHeight;

  @override
  Widget build(BuildContext context) {
    final word = lesson.word;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final complete = lesson.phase == CvcPhase.complete;
    final compact = availableHeight != null && availableHeight! < 330;
    final padding = compact ? 12.0 : 16.0;
    final headingHeight = compact ? 28.0 : 36.0;
    final topGap = compact ? 8.0 : 12.0;
    final resultGap = compact ? 10.0 : 16.0;
    final resultHeight = compact ? 60.0 : 80.0;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFEF4), Color(0xFFF0E9FF)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFFDE82), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x34502E8F), blurRadius: 12, offset: Offset(0, 5)),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              height: headingHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _Label(
                    text: 'Short ${word.vowel}',
                    background: const Color(0xFFE9D9FF)),
              ),
            ),
            SizedBox(height: topGap),
            LayoutBuilder(builder: (context, bounds) {
              final fullWidth = math.min(148.0, (bounds.maxWidth - 24) / 3);
              final tileRoom = (availableHeight ?? double.infinity) -
                  (padding * 2 +
                      headingHeight +
                      topGap +
                      resultGap +
                      resultHeight);
              // Retain a 48px touch target after the blend animation contracts.
              final width = math.min(fullWidth, math.max(60.0, tileRoom * .8));
              final progress = lesson.blend.clamp(0.0, 1.0);
              final letterWidth = width * (1 - .16 * progress);
              final duration = reduced
                  ? Duration.zero
                  : Duration(
                      milliseconds:
                          lesson.phase == CvcPhase.fastBlend ? 180 : 700);
              return SizedBox(
                key: const ValueKey('cvc-letter-row'),
                height: width * 1.25,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0)
                        AnimatedContainer(
                            duration: duration, width: 12 * (1 - progress)),
                      AnimatedContainer(
                        key: ValueKey('cvc-letter-position-$i'),
                        duration: duration,
                        width: letterWidth,
                        height: width * 1.25,
                        child: CvcLetterTile(
                          key: ValueKey('cvc-letter-$i'),
                          letter: word.word[i],
                          highlighted: lesson.highlighted == i,
                          vowel: i == 1,
                          reducedMotion: reduced,
                          onPressed: () => lesson.hearLetter(i),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            SizedBox(height: resultGap),
            AnimatedContainer(
              key: const ValueKey('cvc-word-result'),
              duration:
                  reduced ? Duration.zero : const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              height: resultHeight,
              decoration: BoxDecoration(
                color: complete
                    ? const Color(0xFFE3F9D6)
                    : const Color(0xFFFFFCED),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: complete
                        ? const Color(0xFF55A735)
                        : const Color(0xFFB590E4),
                    width: 2),
              ),
              child: Row(children: [
                SizedBox.square(
                  dimension: 28,
                  child: AnimatedScale(
                    scale: complete ? 1 : 0,
                    duration: reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    child: const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF247B3C), size: 28),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(word.word,
                        key: const ValueKey('cvc-whole-word'),
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 52,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: complete
                                ? const Color(0xFF14592E)
                                : KidsUi.ink)),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox.square(
                  dimension: 28,
                  child: AnimatedScale(
                    scale: complete ? 1 : 0,
                    duration: reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFFAD6900), size: 24),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.background});
  final String text;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(14)),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: KidsUi.ink)),
        ),
      );
}
