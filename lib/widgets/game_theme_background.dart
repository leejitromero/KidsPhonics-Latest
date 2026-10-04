import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'animated_screen_art.dart';

/// The supplied Game Zone artwork, shared by the menu and every game.
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
        // Crop the sign from the animated artwork without reserving screen space.
        final croppedTop = 1672 *
            .20 *
            math.max(box.maxHeight / (1672 * .80), box.maxWidth / 941);
        return Stack(fit: StackFit.expand, children: [
          ClipRect(
              child: Stack(fit: StackFit.expand, children: [
            Positioned(
                top: showBanner ? 0 : -croppedTop,
                bottom: 0,
                left: 0,
                right: 0,
                child: const AnimatedScreenArt(
                    frames: gameFrames,
                    alignment: Alignment.topCenter,
                    blend: true,
                    frameDuration: Duration(milliseconds: 650))),
          ])),
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
