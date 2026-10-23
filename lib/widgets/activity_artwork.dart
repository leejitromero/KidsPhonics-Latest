import 'package:flutter/material.dart';

/// Shows the complete design without a second border or play button.
class ActivityArtwork extends StatelessWidget {
  const ActivityArtwork(
      {super.key,
      required this.asset,
      required this.aspectRatio,
      this.fit = BoxFit.contain});
  final String asset;
  final double aspectRatio;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: aspectRatio,
        child: LayoutBuilder(builder: (context, box) {
          final decodeWidth =
              (box.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .ceil()
                  .clamp(1, 900);
          return RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                asset,
                fit: fit,
                cacheWidth: decodeWidth,
                excludeFromSemantics: true,
                gaplessPlayback: true,
              ),
            ),
          );
        }),
      );
}
