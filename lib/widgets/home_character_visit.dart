import 'dart:math' as math;
import 'package:flutter/material.dart';

/// One cancellable timeline: approach, settle, then disappear under clouds.
abstract final class HomeCharacterVisitTiming {
  static const walk = Duration(milliseconds: 1100);
  static const pause = Duration(milliseconds: 400);
  static const cloud = Duration(milliseconds: 750);
  static final duration = walk + pause + cloud;

  static double elapsed(double t) => t * duration.inMilliseconds;
  static double movement(double t) => Curves.easeInOutSine
      .transform((elapsed(t) / walk.inMilliseconds).clamp(0.0, 1.0));
  static bool walking(double t) => t > 0 && elapsed(t) < walk.inMilliseconds;
  static double clouds(double t) =>
      ((elapsed(t) - (walk + pause).inMilliseconds) / cloud.inMilliseconds)
          .clamp(0.0, 1.0);
}

abstract final class HomeCharacterGeometry {
  /// Center of the supplied classroom rug, mapped through centered BoxFit.cover.
  static Offset matCenter(Size viewport) {
    const source = Size(1024, 1536);
    const center = Offset(512, 1008);
    final scale = math.max(
        viewport.width / source.width, viewport.height / source.height);
    return Offset((viewport.width - source.width * scale) / 2,
            (viewport.height - source.height * scale) / 2) +
        center * scale;
  }

  static Rect idle(Size scene, {Offset? floorCenter}) {
    // Match the reference's central, full-body silhouette, keeping one scale
    // for both axes. Leave the existing banner and activity row clear.
    final height = math.min(scene.height * .32, scene.width * .84);
    final floor = floorCenter ?? Offset(scene.width / 2, scene.height * .665);
    return Rect.fromLTWH(
        floor.dx - height * .75 / 2, floor.dy - height, height * .75, height);
  }

  static Rect approach(Rect start, Rect mascot, {required bool left}) {
    // Stop on the inner edge, rather than crossing the mascot's center. Only
    // the trailing leg may sit behind the guide; the head and torso stay above.
    final occlusion = math.min(start.width * .12, mascot.width * .22);
    final x = left ? mascot.right - occlusion : mascot.left + occlusion;
    final shift = left
        ? math.min(0.0, x - start.center.dx)
        : math.max(0.0, x - start.center.dx);
    return start.shift(Offset(shift, 0));
  }
}

/// Local, soft puffs rise around the student while the guides stay in front.
/// Vector drawing keeps the effect smooth at phone and tablet resolutions.
class HomeCharacterCloud extends StatelessWidget {
  const HomeCharacterCloud({super.key, required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: CustomPaint(painter: _CharacterCloudPainter(progress)));
}

class _CharacterCloudPainter extends CustomPainter {
  const _CharacterCloudPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final t = Curves.easeInOut.transform(progress);
    final opacity = (progress * 3).clamp(0.0, 1.0);
    final puff = Paint();
    // Stagger the rows from shoes to hair, rather than sliding the whole cloud.
    for (var row = 0; row < 5; row++) {
      final growth = ((t - row * .1) / .55).clamp(0.0, 1.0);
      if (growth == 0) continue;
      for (var col = 0; col < 3; col++) {
        final center = Offset(
            size.width * (.22 + col * .28), size.height * (.82 - row * .155));
        final radius = size.width * (.29 + (row % 2) * .025) * growth;
        puff.shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: opacity),
          const Color(0xFFEAF4FF).withValues(alpha: opacity),
          const Color(0xFFDCD6FF).withValues(alpha: opacity * .55),
          Colors.white.withValues(alpha: 0),
        ], stops: const [
          0,
          .65,
          .87,
          1
        ]).createShader(Rect.fromCircle(center: center, radius: radius));
        canvas.drawCircle(center, radius, puff);
      }
    }
    final sparkle = Paint()
      ..color = const Color(0xFFFFEAAA)
          .withValues(alpha: math.sin(progress * math.pi).clamp(0.0, 1.0))
      ..strokeWidth = math.max(1.0, size.width * .008)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final center = Offset(
          size.width * (i.isEven ? .14 : .86), size.height * (.18 + i * .14));
      final r = size.width * .025;
      canvas.drawLine(center - Offset(r, 0), center + Offset(r, 0), sparkle);
      canvas.drawLine(center - Offset(0, r), center + Offset(0, r), sparkle);
    }
  }

  @override
  bool shouldRepaint(_CharacterCloudPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
