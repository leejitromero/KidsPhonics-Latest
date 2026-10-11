import 'package:flutter/material.dart';

/// Four aligned wing poses share one decoded texture to keep taps smooth.
class FlappyBirdSprite extends StatelessWidget {
  const FlappyBirdSprite({
    super.key,
    required this.size,
    this.frame = 0,
    this.tilt = 0,
  }) : assert(frame >= 0 && frame < 4);

  static const asset = 'assets/images/new_ui/flappy_bird_frames.webp';
  // Registered viewports in the 1254px atlas keep the face and feet steady.
  // The horizontal wing pose needs more space than a strict half-sheet crop.
  static const _sheetSide = 1254.0;
  static const _frameSide = 588.0;
  static const _origins = [
    Offset(78, 98),
    Offset(661, 98),
    Offset(78, 627),
    Offset(661, 627),
  ];
  final double size;
  final int frame;
  final double tilt;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: tilt,
        child: SizedBox.square(
          dimension: size,
          child: ClipRect(
            clipper: _BirdFrameClipper(frame),
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: size * _sheetSide / _frameSide,
              maxWidth: size * _sheetSide / _frameSide,
              minHeight: size * _sheetSide / _frameSide,
              maxHeight: size * _sheetSide / _frameSide,
              child: Transform.translate(
                offset: _origins[frame] * (-size / _frameSide),
                child: Image.asset(
                  asset,
                  width: size * _sheetSide / _frameSide,
                  height: size * _sheetSide / _frameSide,
                  fit: BoxFit.fill,
                  cacheWidth: 512,
                  excludeFromSemantics: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        ),
      );
}

class _BirdFrameClipper extends CustomClipper<Rect> {
  const _BirdFrameClipper(this.frame);
  final int frame;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
        // Clear the horizontal pose's edge pixels from the next frame's gutter.
        frame == 3 ? size.width * 24 / FlappyBirdSprite._frameSide : 0,
        0,
        size.width,
        size.height,
      );

  @override
  bool shouldReclip(_BirdFrameClipper oldClipper) => frame != oldClipper.frame;
}
