import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/updated_scene.dart';

/// Text fits inside the white center, away from the border and speech tail.
class SceneDialogue extends StatelessWidget {
  const SceneDialogue(
      {super.key,
      required this.text,
      required this.art,
      this.flip = false,
      this.introduction = false,
      this.contentInsets});
  final String text, art;
  final bool flip, introduction;

  /// Optional fractional insets for the Settings guide's oval artwork.
  final EdgeInsets? contentInsets;

  static double aspectRatioFor(String art) =>
      art == 'dialogue_box_3.png' ? 1 : 4 / 3;

  /// Tip of the supplied artwork, including its transparent outer margins.
  static Offset tailFor(String art, {bool flip = false}) {
    final tip = switch (art) {
      'dialogue_box_1.png' => const Offset(.108, .900),
      'dialogue_box_2.png' => const Offset(.113, .929),
      'dialogue_box_4.png' => const Offset(.139, .921),
      _ => const Offset(.24, .925),
    };
    return Offset(flip ? 1 - tip.dx : tip.dx, tip.dy);
  }

  @override
  Widget build(BuildContext context) => Semantics(
      liveRegion: true,
      label: introduction ? text : null,
      excludeSemantics: introduction,
      child: LayoutBuilder(builder: (_, available) {
        final width = math.min(
            available.maxWidth, available.maxHeight * aspectRatioFor(art));
        return Center(
            child: SizedBox(
                width: width,
                height: width / aspectRatioFor(art),
                child: LayoutBuilder(builder: (_, box) {
                  final burst = art == 'dialogue_box_3.png';
                  final cloud = art == 'dialogue_box_2.png';
                  final horizontal = introduction
                      ? .20
                      : burst || cloud
                          ? .18
                          : .14;
                  return Stack(fit: StackFit.expand, children: [
                    Transform.flip(
                        flipX: flip,
                        child: Image.asset('$sceneAssets/$art',
                            key: const ValueKey('scene-dialogue-art'),
                            fit: BoxFit.contain,
                            cacheWidth: 942,
                            excludeFromSemantics: true)),
                    Positioned(
                        left:
                            box.maxWidth * (contentInsets?.left ?? horizontal),
                        right:
                            box.maxWidth * (contentInsets?.right ?? horizontal),
                        top: box.maxHeight *
                            (contentInsets?.top ??
                                (burst
                                    ? .30
                                    : cloud
                                        ? .34
                                        : .20)),
                        bottom: box.maxHeight *
                            (contentInsets?.bottom ?? (burst ? .28 : .25)),
                        child: ClipRect(
                            key: const ValueKey('scene-dialogue-content'),
                            child: introduction
                                ? _IntroductionText(text: text)
                                : _FittingDialogueText(text: text))),
                  ]);
                })));
      }));
}

// Measure with the same font, text scale and width used for painting. This
// keeps full sentences inside the white opening without clipping or ellipses.
double _textHeight(String text, TextStyle style, TextScaler scaler,
    TextDirection direction, double width) {
  final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler)
    ..layout(maxWidth: width);
  final height = painter.height;
  painter.dispose();
  return height;
}

double _fittingFont(
    double maximum, double available, double Function(double) height) {
  var lower = .001, upper = maximum;
  for (var i = 0; i < 18; i++) {
    final candidate = (lower + upper) / 2;
    if (height(candidate) <= available) {
      lower = candidate;
    } else {
      upper = candidate;
    }
  }
  return lower;
}

class _FittingDialogueText extends StatelessWidget {
  const _FittingDialogueText({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        const base = TextStyle(
            inherit: false,
            fontFamily: 'Nunito',
            fontSize: 18,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: Color(0xFF633012));
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        final font = _fittingFont(
            18,
            box.maxHeight,
            (size) => _textHeight(text, base.copyWith(fontSize: size), scaler,
                direction, box.maxWidth));
        return Center(
            child: Text(text,
                key: const ValueKey('scene-dialogue-text'),
                textAlign: TextAlign.center,
                style: base.copyWith(fontSize: font)));
      });
}

class _IntroductionText extends StatelessWidget {
  const _IntroductionText({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final sentence = RegExp(r'[.!?]\s+').firstMatch(text);
        final title =
            sentence == null ? text : text.substring(0, sentence.start + 1);
        final detail = sentence == null ? null : text.substring(sentence.end);
        final padding =
            math.min(8.0, math.min(box.maxWidth * .04, box.maxHeight * .08));
        final gap = math.min(8.0, box.maxHeight * .05);
        const titleStyle = TextStyle(
            inherit: false,
            fontFamily: 'Nunito',
            fontSize: 28,
            height: 1.12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF592210));
        const detailStyle = TextStyle(
            inherit: false,
            fontFamily: 'Nunito',
            fontSize: 20,
            height: 1.18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6515C2));
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        final font = _fittingFont(
            math.min(40, math.max(18, box.maxWidth * .15)),
            math.max(
                .001, box.maxHeight - (detail == null ? 0 : gap + padding * 2)),
            (size) =>
                _textHeight(title, titleStyle.copyWith(fontSize: size), scaler,
                    direction, box.maxWidth) +
                (detail == null
                    ? 0
                    : _textHeight(
                        detail,
                        detailStyle.copyWith(fontSize: size * .70),
                        scaler,
                        direction,
                        math.max(1, box.maxWidth - padding * 2))));
        // Font fallback and platform rounding can add a line after measuring.
        // Fit the final rendered column too, so every glyph remains in the opening.
        return Center(
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                    width: box.maxWidth,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(title,
                          key: const ValueKey('scene-dialogue-text'),
                          textAlign: TextAlign.center,
                          style: titleStyle.copyWith(fontSize: font)),
                      if (detail != null) ...[
                        SizedBox(height: gap),
                        DecoratedBox(
                            decoration: BoxDecoration(
                                color: const Color(0xFFF1DFF6),
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                                padding: EdgeInsets.all(padding),
                                child: Text(detail,
                                    key:
                                        const ValueKey('scene-dialogue-detail'),
                                    textAlign: TextAlign.center,
                                    style: detailStyle.copyWith(
                                        fontSize: font * .70)))),
                      ],
                    ]))));
      });
}

/// Places the actual artwork tail above its speaker's head. Width shrinks only
/// when needed to stay inside the scene and below the logo or safe top inset.
abstract final class SceneSpeechGeometry {
  /// Center the introduction in the open band between banner and mascot heads.
  static Rect introduction(
      {required Size scene,
      required Rect speaker,
      required String art,
      required double minTop,
      double sideInset = 12}) {
    final aspect = SceneDialogue.aspectRatioFor(art);
    final availableHeight = math.max(1.0, speaker.top - 8 - minTop);
    final width = math.max(
        1.0,
        math.min(math.min(scene.width - sideInset * 2, 640.0),
            availableHeight * aspect));
    final height = width / aspect;
    return Rect.fromLTWH((scene.width - width) / 2,
        minTop + (availableHeight - height) / 2, width, height);
  }

  static Rect aboveHead(
      {required Size scene,
      required Rect speaker,
      required String art,
      bool flip = false,
      required double preferredWidth,
      double minTop = 0,
      double sideInset = 12,
      double gap = 8}) {
    final tail = SceneDialogue.tailFor(art, flip: flip);
    final aspect = SceneDialogue.aspectRatioFor(art);
    final horizontalRoom = flip
        ? (speaker.center.dx - sideInset) / tail.dx
        : (scene.width - sideInset - speaker.center.dx) / (1 - tail.dx);
    final verticalRoom = math.max(1.0, speaker.top - gap - minTop) / tail.dy;
    final width = math.max(
        1.0,
        math.min(
            preferredWidth, math.min(horizontalRoom, verticalRoom * aspect)));
    final height = width / aspect;
    return Rect.fromLTWH(speaker.center.dx - tail.dx * width,
        speaker.top - gap - tail.dy * height, width, height);
  }
}
