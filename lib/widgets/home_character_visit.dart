import 'dart:math' as math;
import 'package:flutter/material.dart';

/// One cancellable timeline: approach and settle before the screen curtain.
abstract final class HomeCharacterVisitTiming {
  static const walk = Duration(milliseconds: 1100);
  static const pause = Duration(milliseconds: 400);
  static final duration = walk + pause;
  static const curtain = Duration(milliseconds: 1800);

  static double elapsed(double t) => t * duration.inMilliseconds;
  static double movement(double t) => Curves.easeInOutSine
      .transform((elapsed(t) / walk.inMilliseconds).clamp(0.0, 1.0));
  static bool walking(double t) => t > 0 && elapsed(t) < walk.inMilliseconds;
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
