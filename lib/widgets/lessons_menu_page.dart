import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/kids_ui.dart';
import 'animated_screen_art.dart';
import 'button_sound.dart';

/// Keeps the artwork's hanging Lessons sign above the interactive lesson cards.
class LessonsMenuPage extends StatelessWidget {
  const LessonsMenuPage({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
        data: KidsUi.theme,
        child: Scaffold(
          backgroundColor: const Color(0xFF94DAFA),
          body: LayoutBuilder(builder: (context, box) {
            final safe = MediaQuery.paddingOf(context);
            // Match BoxFit.cover at top center, preserving the title on tablets.
            final artworkHeight =
                math.max(box.maxHeight, box.maxWidth * 1672 / 941);
            final contentTop = math.max(artworkHeight * .20, safe.top + 60);
            return Stack(fit: StackFit.expand, children: [
              const AnimatedScreenArt(
                frames: lessonFrames,
                alignment: Alignment.topCenter,
                blend: true,
                frameDuration: Duration(milliseconds: 650),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: contentTop,
                child: IgnorePointer(
                  child: Semantics(
                    header: true,
                    namesRoute: true,
                    label: 'Lessons',
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Positioned(
                top: contentTop,
                left: safe.left + 12,
                right: safe.right + 12,
                bottom: safe.bottom + 12,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: child,
                  ),
                ),
              ),
              Positioned(
                top: safe.top + 8,
                left: safe.left + 8,
                child: IconButton.filledTonal(
                  tooltip: 'Back',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: Colors.white.withValues(alpha: .92),
                    foregroundColor: KidsUi.ink,
                  ),
                  onPressed: withButtonSound(() => Navigator.maybePop(context)),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            ]);
          }),
        ),
      );
}
