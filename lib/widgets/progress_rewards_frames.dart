import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'progress_design.dart';

/// Displays the supplied artwork without changing the original PNG. Only its
/// transparent outer margin is excluded from the layout. The treasure panel's
/// empty center stretches so its trophy and corner stars keep their proportions.
class ProgressRewardArtwork extends StatelessWidget {
  const ProgressRewardArtwork({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final (size, crop) = switch (name) {
      'frame_mybadge' => (
          const Size(2172, 724),
          const Rect.fromLTRB(12, 90, 2160, 596)
        ),
      'frame_alphabet_milstone' => (
          const Size(2171, 724),
          const Rect.fromLTRB(24, 104, 2146, 612)
        ),
      'frame_rewards_contain' => (
          const Size(2154, 730),
          const Rect.fromLTRB(48, 76, 2108, 654)
        ),
      _ => (const Size(1672, 941), const Rect.fromLTRB(24, 30, 1654, 856)),
    };
    return LayoutBuilder(builder: (_, box) {
      final scale = box.maxWidth / crop.width;
      final treasure = name == 'frame_mytreasure';
      return ClipRect(
          child: Stack(children: [
        Positioned(
            left: -crop.left * box.maxWidth / crop.width,
            top: -crop.top * (treasure ? scale : box.maxHeight / crop.height),
            width: size.width * box.maxWidth / crop.width,
            height: treasure
                ? box.maxHeight + (size.height - crop.height) * scale
                : size.height * box.maxHeight / crop.height,
            child: Image.asset('assets/images/progress_collection/$name.png',
                scale: treasure ? 1 / scale : null,
                centerSlice: treasure
                    ? Rect.fromLTRB(
                        550 * scale, 450 * scale, 1100 * scale, 560 * scale)
                    : null,
                fit: BoxFit.fill,
                excludeFromSemantics: true)),
      ]));
    });
  }
}

double rewardTextHeight(
    BuildContext context, String text, TextStyle style, double width) {
  final painter = TextPainter(
      text: TextSpan(
          text: text, style: DefaultTextStyle.of(context).style.merge(style)),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context))
    ..layout(maxWidth: width);
  final height = painter.height;
  painter.dispose();
  return height;
}

class ProgressRewardsHeader extends StatelessWidget {
  const ProgressRewardsHeader({super.key, this.earned, this.total});
  final int? earned, total;
  static const titleStyle = TextStyle(
      fontSize: 18,
      height: 1.15,
      fontWeight: FontWeight.w900,
      color: progressPurple);
  static const captionStyle =
      TextStyle(fontSize: 11, height: 1.3, color: progressInk);
  static const caption = 'Complete learning goals to unlock your badges.';

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final badges = total != null;
        final title = badges ? 'My Badges' : 'Alphabet Milestones';
        final textWidth = box.maxWidth * (badges ? .48 : .66);
        final contentHeight = rewardTextHeight(
                context, title, titleStyle, textWidth) +
            (badges
                ? 4 +
                    rewardTextHeight(context, caption, captionStyle, textWidth)
                : 0);
        final height = math.max(
            box.maxWidth * (badges ? 506 / 2148 : 508 / 2122),
            math.max(badges ? 94.0 : 70.0, (contentHeight + 4) / .68));
        return SizedBox(
            key: ValueKey(
                badges ? 'rewards-badges-header' : 'rewards-milestone-header'),
            height: height,
            child: Stack(fit: StackFit.expand, children: [
              ProgressRewardArtwork(
                  name: badges ? 'frame_mybadge' : 'frame_alphabet_milstone'),
              Positioned(
                  left: box.maxWidth * (badges ? .22 : .26),
                  top: height * .16,
                  width: textWidth,
                  height: height * .68,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: titleStyle),
                        if (badges) ...[
                          const SizedBox(height: 4),
                          const Text(caption, style: captionStyle),
                        ],
                      ])),
              if (badges)
                Positioned(
                    left: box.maxWidth * .745,
                    top: height * .34,
                    width: box.maxWidth * .20,
                    height: height * .34,
                    child: Center(
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('$earned / $total',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFC53179)))))),
            ]));
      });
}

class ProgressTreasureFrame extends StatelessWidget {
  const ProgressTreasureFrame(
      {super.key,
      required this.level,
      required this.stars,
      required this.xp,
      required this.progressBar});
  final int level, stars, xp;
  final Widget progressBar;
  static const note =
      'Badges celebrate progress; viewing them does not award extra XP or stars.';

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        const valueStyle =
            TextStyle(fontSize: 23, height: 1.2, fontWeight: FontWeight.w900);
        const labelStyle =
            TextStyle(fontSize: 11, height: 1.3, color: progressInk);
        final values = [
          (
            'Level $level',
            'learning level',
            Icons.emoji_events_rounded,
            progressPurple
          ),
          (
            '$stars Stars',
            'earned',
            Icons.star_rounded,
            const Color(0xFFE9A414)
          ),
          ('$xp XP', 'experience', Icons.bolt_rounded, progressPurple),
        ];
        final bodyWidth = box.maxWidth * .76;
        final scale = MediaQuery.textScalerOf(context).scale(11) / 11;
        final columns = (bodyWidth / (78 * scale)).floor().clamp(1, 3);
        final itemWidth = (bodyWidth - (columns - 1) * 6 - .01) / columns;
        var itemHeight = 0.0;
        for (final (value, label, _, _) in values) {
          itemHeight = math.max(
              itemHeight,
              25 +
                  rewardTextHeight(
                      context, value, valueStyle, double.infinity) +
                  rewardTextHeight(context, label, labelStyle, itemWidth));
        }
        final rows = (3 / columns).ceil();
        final caption = '${200 - xp % 200} XP to Level ${level + 1}';
        final bodyHeight = rows * itemHeight +
            (rows - 1) * 8 +
            12 +
            8 +
            5 +
            rewardTextHeight(context, caption, labelStyle, bodyWidth) +
            5 +
            rewardTextHeight(context, note, labelStyle, bodyWidth);
        final titleHeight = rewardTextHeight(context, 'My Treasure',
            ProgressRewardsHeader.titleStyle, box.maxWidth * .56);
        final titleTop = box.maxWidth * .12;
        final bodyTop =
            math.max(box.maxWidth * .27, titleTop + titleHeight + 12);
        final height = math.max(box.maxWidth * 826 / 1630,
            bodyTop + bodyHeight + box.maxWidth * .18 + 6);
        return SizedBox(
            key: const ValueKey('rewards-treasure-frame'),
            height: height,
            child: Stack(fit: StackFit.expand, children: [
              const Positioned.fill(
                  child: ProgressRewardArtwork(name: 'frame_mytreasure')),
              Positioned(
                  key: const ValueKey('rewards-treasure-content'),
                  left: box.maxWidth * .12,
                  top: bodyTop,
                  width: bodyWidth,
                  height: bodyHeight + 4,
                  child: Column(children: [
                    Wrap(
                        spacing: 6,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final (value, label, icon, color) in values)
                            SizedBox(
                                width: itemWidth,
                                height: itemHeight,
                                child: Column(children: [
                                  Icon(icon, size: 25, color: color),
                                  FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(value,
                                          maxLines: 1,
                                          textAlign: TextAlign.center,
                                          style: valueStyle.copyWith(
                                              color: color))),
                                  Text(label,
                                      textAlign: TextAlign.center,
                                      style: labelStyle),
                                ])),
                        ]),
                    const SizedBox(height: 12),
                    SizedBox(height: 8, child: progressBar),
                    const SizedBox(height: 5),
                    Text(caption,
                        textAlign: TextAlign.center, style: labelStyle),
                    const SizedBox(height: 5),
                    const Text(note,
                        textAlign: TextAlign.center, style: labelStyle),
                  ])),
              Positioned(
                  left: box.maxWidth * .32,
                  right: box.maxWidth * .12,
                  top: titleTop,
                  child: const Text('My Treasure',
                      style: ProgressRewardsHeader.titleStyle)),
            ]));
      });
}
