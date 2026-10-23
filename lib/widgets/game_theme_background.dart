import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'animated_screen_art.dart';

/// The supplied playground frames, shared by the games' activity backgrounds.
class GameThemeBackground extends StatelessWidget {
  const GameThemeBackground(
      {super.key,
      required this.child,
      this.answerResult,
      this.showBanner = false});
  final Widget child;
  final bool? answerResult;
  final bool showBanner;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final banner = math.min(box.maxHeight * .32,
            math.max(box.maxHeight, box.maxWidth * 1672 / 941) * .18);
        return Stack(fit: StackFit.expand, children: [
          const Positioned.fill(
              child: AnimatedScreenArt(
                  frames: gameFrames,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  blend: true,
                  frameDuration: Duration(seconds: 3))),
          if (answerResult != null)
            IgnorePointer(
                child: ColoredBox(
                    key: const ValueKey('answer-background-effect'),
                    color: (answerResult!
                            ? const Color(0xFF6CCB91)
                            : const Color(0xFFFFB4AC))
                        .withValues(alpha: .22))),
          Padding(
              padding: EdgeInsets.only(top: showBanner ? banner : 0),
              child: child),
        ]);
      });
}
