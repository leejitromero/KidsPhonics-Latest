import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/kids_ui.dart';
import 'animated_screen_art.dart';
import 'button_sound.dart';

/// Full-screen lesson scenery with the supplied sign above the lesson content.
class LessonsMenuPage extends StatelessWidget {
  const LessonsMenuPage({super.key, required this.child});
  final Widget child;
  static const bannerAsset = 'assets/images/new_ui/lessons_banner.webp';

  @override
  Widget build(BuildContext context) => Theme(
        data: KidsUi.theme,
        child: Scaffold(
          backgroundColor: const Color(0xFF94DAFA),
          body: LayoutBuilder(builder: (context, box) {
            final safe = MediaQuery.paddingOf(context);
            final bannerWidth =
                math.min(540.0, box.maxWidth - safe.left - safe.right - 76);
            final bannerHeight = bannerWidth / 3;
            final contentTop = safe.top + math.max(48, bannerHeight) + 24;
            return Stack(fit: StackFit.expand, children: [
              const AnimatedScreenArt(
                frames: lessonFrames,
                alignment: Alignment.topCenter,
                blend: true,
                frameDuration: Duration(milliseconds: 650),
              ),
              Positioned(
                top: safe.top + 8,
                left: safe.left + 64,
                right: safe.right + 12,
                height: bannerHeight,
                child: IgnorePointer(
                  child: Image.asset(
                    bannerAsset,
                    key: const ValueKey('lessons-banner'),
                    fit: BoxFit.contain,
                    semanticLabel: 'Lessons',
                    cacheWidth:
                        (bannerWidth * MediaQuery.devicePixelRatioOf(context))
                            .ceil(),
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
