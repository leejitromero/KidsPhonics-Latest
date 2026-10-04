import 'animated_screen_art.dart';
import 'package:flutter/material.dart';

/// Lightweight, offline artwork that scales to phones and tablets.
class AdventureBackground extends StatelessWidget {
  const AdventureBackground(
      {super.key, required this.child, this.answerResult});
  final Widget child;
  final bool? answerResult;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE6DCFF),
              Color(0xFFDFF8F4),
              Color(0xFFFFEBCB),
            ],
          ),
        ),
        child: Stack(fit: StackFit.expand, children: [
          const Positioned.fill(
              child: AnimatedScreenArt(
                  frames: skyFrames,
                  blend: true,
                  frameDuration: Duration(milliseconds: 450))),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: answerResult == null ? 0 : 1,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 280),
                child: DecoratedBox(
                  key: const ValueKey('answer-background-effect'),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -.3),
                      radius: 1.2,
                      colors: answerResult == false
                          ? const [Color(0xFFFFF0EC), Color(0xFFF6B5B5)]
                          : const [Color(0xFFEFFFF1), Color(0xFF92DEB7)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          child,
        ]),
      );
}

class AdventureMascot extends StatelessWidget {
  const AdventureMascot({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: 116,
          height: 116,
          child: Stack(alignment: Alignment.center, children: [
            Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .13),
                    shape: BoxShape.circle)),
            const Icon(Icons.star_rounded, size: 116, color: Color(0xFFFFD76A)),
            const Positioned(
                top: 49,
                child: Row(children: [
                  Icon(Icons.circle, size: 7, color: Color(0xFF49315D)),
                  SizedBox(width: 16),
                  Icon(Icons.circle, size: 7, color: Color(0xFF49315D)),
                ])),
            const Positioned(
                top: 56,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 25, color: Color(0xFF49315D))),
          ]),
        ),
      );
}
