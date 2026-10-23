import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'home_character_visit.dart';

/// Home placement uses the full background viewport and the space above the dock.
class HomeSceneLayout {
  const HomeSceneLayout(this.student, this.lessons, this.games, this.practice);
  final Rect student, lessons, games, practice;

  static HomeSceneLayout layout(Size viewport,
      {required double contentHeight, required EdgeInsets insets}) {
    final width = viewport.width;
    final side = math.max(
        width * .025, math.max(6.0, math.max(insets.left, insets.right)));
    final gap = (contentHeight * .009).clamp(6.0, 10.0);
    var buttonHeight = math.max(
        48.0, math.min(contentHeight * .13, (width - side * 2) * .39 / 1.5));
    final practiceHeight =
        math.max(48.0, math.min(contentHeight * .10, width * .46 / 2));
    final bottom = contentHeight - insets.bottom - 6;
    final practice = Rect.fromLTWH((width - practiceHeight * 2) / 2,
        bottom - practiceHeight, practiceHeight * 2, practiceHeight);
    final mat = HomeCharacterGeometry.matCenter(viewport);
    // On very wide displays the cropped mat center can lie under the dock.
    // Keep the full student above Practice in that constrained case.
    final floor = Offset(mat.dx, math.min(mat.dy, practice.top - 8));
    final student = HomeCharacterGeometry.idle(Size(width, contentHeight),
        floorCenter: floor);
    if (practice.top - gap - buttonHeight < student.bottom) {
      // On short screens the signs sit beside the shoes; leave a clear gap.
      buttonHeight = math.max(
          48.0, math.min(buttonHeight, (student.left - side - 4) / 1.5));
    }
    final buttonWidth = buttonHeight * 1.5;
    final rowTop = practice.top - gap - buttonHeight;
    final lessons = Rect.fromLTWH(side, rowTop, buttonWidth, buttonHeight);
    final games = Rect.fromLTWH(
        width - side - buttonWidth, rowTop, buttonWidth, buttonHeight);
    return HomeSceneLayout(student, lessons, games, practice);
  }

  Rect mascot(bool gamesGuide, Size scene) {
    final button = gamesGuide ? games : lessons;
    final size = math.min(scene.width * .29, scene.height * .23);
    final top = math.max(button.top + button.height * .275 - size,
        student.top + student.height * .4 + 4);
    return Rect.fromLTWH(button.center.dx - size / 2, top, size, size);
  }
}
