import 'button_sound.dart';
import 'package:flutter/material.dart';
import 'animated_screen_art.dart';

/// Display the complete supplied 941 x 1672 canvas, including its logo and
/// Parents sign. Tap regions cover each sign across all three animation frames.
class HomeFlightMenu extends StatelessWidget {
  const HomeFlightMenu(
      {super.key,
      required this.onLessons,
      required this.onGames,
      required this.onProgress,
      required this.onParents});
  final VoidCallback onLessons, onProgress, onParents;
  final VoidCallback? onGames;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 941 / 1672,
        child: LayoutBuilder(builder: (_, box) {
          final scale = box.maxWidth / 941;
          Widget target(
                  String key, String label, Rect rect, VoidCallback? onTap) =>
              Positioned(
                  left: rect.left * scale,
                  top: rect.top * scale,
                  width: rect.width * scale,
                  height: rect.height * scale,
                  child: Semantics(
                      button: true,
                      enabled: onTap != null,
                      label: onTap == null
                          ? '$label, turned off by a parent'
                          : label,
                      child: Tooltip(
                          excludeFromSemantics: true,
                          message: onTap == null
                              ? 'Games are turned off by a parent.'
                              : label,
                          child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                  key: ValueKey(key),
                                  onTap: withButtonSound(onTap),
                                  borderRadius: BorderRadius.circular(32),
                                  splashColor:
                                      Colors.white.withValues(alpha: .35),
                                  child: onTap == null
                                      ? const Center(
                                          child: CircleAvatar(
                                              backgroundColor:
                                                  Color(0xEE30214F),
                                              foregroundColor: Colors.white,
                                              child: Icon(Icons.lock_rounded)))
                                      : const SizedBox.expand())))));
          return Stack(clipBehavior: Clip.hardEdge, children: [
            const Positioned.fill(
                child: AnimatedScreenArt(
                    frames: homeFrames,
                    fit: BoxFit.contain,
                    frameDuration: homeFrameDuration)),
            target('home-lessons', 'Lessons',
                const Rect.fromLTWH(20, 950, 280, 320), onLessons),
            target('home-games', 'Game Zone',
                const Rect.fromLTWH(335, 970, 270, 360), onGames),
            target('home-progress', 'Progress',
                const Rect.fromLTWH(635, 950, 290, 380), onProgress),
            target('home-parents', 'Parents',
                const Rect.fromLTWH(30, 1400, 480, 220), onParents),
          ]);
        }),
      );
}
