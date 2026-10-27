import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'parent_report_frames.dart';

/// Live saved rewards fitted to the supplied artwork's individual empty boxes.
class ParentRewardsFrame extends StatelessWidget {
  const ParentRewardsFrame(
      {super.key,
      required this.level,
      required this.xp,
      required this.stars,
      required this.earned,
      required this.total,
      required this.onViewAll});

  static const asset = 'assets/images/parent_reports/frame_rewrds.png';
  static const _title = TextStyle(
      color: ParentReportFrame.ink,
      fontSize: 18,
      height: 1.1,
      fontWeight: FontWeight.w900);
  static const _value = TextStyle(
      color: ParentReportFrame.ink,
      fontSize: 23,
      height: 1.15,
      fontWeight: FontWeight.w900);
  static const _label = TextStyle(
      color: ParentReportFrame.ink,
      fontSize: 12,
      height: 1.3,
      fontWeight: FontWeight.w700);
  static const _caption =
      TextStyle(color: ParentReportFrame.muted, fontSize: 12, height: 1.35);
  static const _footer =
      'Rewards celebrate your practice. Mastery comes from letter quick checks.';

  final int level, xp, stars, earned, total;
  final VoidCallback? onViewAll;

  double _height(
      BuildContext context, String text, TextStyle style, double width) {
    final painter = TextPainter(
        text: TextSpan(text: text, style: style.copyWith(fontFamily: 'Nunito')),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context))
      ..layout(maxWidth: width);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final scale = box.maxWidth / _RewardsBand.cropWidth;
        final stats = [
          (Icons.workspace_premium_rounded, '$level', 'Level'),
          (Icons.bolt_rounded, '$xp', 'XP'),
          (Icons.star_rounded, '$stars', 'Stars')
        ];
        double statHeight(int i) =>
            22 +
            4 +
            _height(context, stats[i].$2, _value, 385 * scale) +
            _height(context, stats[i].$3, _label, 385 * scale);
        final achievement = '$earned / $total Achievements';
        Widget stat(int i) => Semantics(
            label: '${stats[i].$3}: ${stats[i].$2}',
            excludeSemantics: true,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(stats[i].$1, size: 22, color: const Color(0xFF278238)),
              const SizedBox(height: 4),
              Text(stats[i].$2, style: _value, textAlign: TextAlign.center),
              Text(stats[i].$3, style: _label, textAlign: TextAlign.center)
            ]));
        return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DefaultTextStyle.merge(
                style: const TextStyle(
                    fontFamily: 'Nunito', color: ParentReportFrame.ink),
                child: Column(
                    key: const ValueKey('parent-rewards-frame'),
                    children: [
                      _RewardsBand(
                          top: 6,
                          bottom: 330,
                          height: math.max(
                              324 * scale,
                              (_height(context, 'Rewards', _title,
                                          610 * scale) +
                                      4) *
                                  324 /
                                  65),
                          slots: const [
                            (
                              Rect.fromLTRB(320, 180, 950, 245),
                              Center(
                                  child: Text('Rewards',
                                      style: _title,
                                      textAlign: TextAlign.center))
                            ),
                            (
                              Rect.fromLTRB(320, 268, 675, 303),
                              FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Milestones and badges.',
                                      style: _caption))
                            ),
                          ]),
                      _RewardsBand(
                          top: 330,
                          bottom: 450,
                          height: math.max(
                              120 * scale,
                              math.max(
                                      48,
                                      _height(context, 'View All', _label,
                                              370 * scale) +
                                          12) *
                                  120 /
                                  106),
                          slots: [
                            (
                              const Rect.fromLTRB(110, 334, 520, 440),
                              TextButton(
                                  onPressed: onViewAll,
                                  style: TextButton.styleFrom(
                                      foregroundColor: ParentReportFrame.ink,
                                      minimumSize: const Size(48, 48),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      shape: const StadiumBorder()),
                                  child: const Text('View All',
                                      style: _label,
                                      textAlign: TextAlign.center))
                            ),
                          ]),
                      _RewardsBand(
                          top: 450,
                          bottom: 714,
                          height: math.max(
                              264 * scale,
                              (math.max(statHeight(0), statHeight(1)) + 12) *
                                  264 /
                                  202),
                          slots: [
                            (
                              const Rect.fromLTRB(113, 476, 530, 678),
                              KeyedSubtree(
                                  key: const ValueKey('parent-rewards-level'),
                                  child: stat(0))
                            ),
                            (
                              const Rect.fromLTRB(580, 476, 993, 678),
                              KeyedSubtree(
                                  key: const ValueKey('parent-rewards-xp'),
                                  child: stat(1))
                            ),
                          ]),
                      _RewardsBand(
                          top: 714,
                          bottom: 942,
                          height: math.max(
                              228 * scale,
                              (math.max(
                                          statHeight(2),
                                          _height(context, achievement, _label,
                                              385 * scale)) +
                                      12) *
                                  228 /
                                  166),
                          slots: [
                            (
                              const Rect.fromLTRB(113, 744, 530, 910),
                              KeyedSubtree(
                                  key: const ValueKey('parent-rewards-stars'),
                                  child: stat(2))
                            ),
                            (
                              const Rect.fromLTRB(580, 744, 993, 910),
                              Center(
                                  child: Text(achievement,
                                      textAlign: TextAlign.center,
                                      style: _label))
                            ),
                          ]),
                      _RewardsBand(
                          top: 942,
                          bottom: 1022,
                          height: math.max(80 * scale, 12 * 80 / 35),
                          slots: [
                            (
                              const Rect.fromLTRB(115, 962, 1000, 997),
                              Center(
                                  child: Semantics(
                                      label: 'Achievements earned',
                                      child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: LinearProgressIndicator(
                                              key: const ValueKey(
                                                  'parent-rewards-progress'),
                                              value: total == 0
                                                  ? 0
                                                  : (earned / total)
                                                      .clamp(0, 1),
                                              minHeight: 8,
                                              color: const Color(0xFF278238),
                                              backgroundColor:
                                                  const Color(0xFFBBD0AE)))))
                            )
                          ]),
                      _RewardsBand(
                          top: 1022,
                          bottom: 1210,
                          height: math.max(
                              188 * scale,
                              (_height(context, _footer, _caption,
                                          870 * scale) +
                                      14) *
                                  188 /
                                  140),
                          slots: const [
                            (
                              Rect.fromLTRB(120, 1040, 990, 1180),
                              Center(
                                  child: Text(_footer,
                                      style: _caption,
                                      textAlign: TextAlign.center))
                            )
                          ]),
                      _RewardsBand(
                          top: 1210,
                          bottom: 1392,
                          height: 182 * scale,
                          slots: const []),
                    ])));
      });
}

/// Adjacent source bands share the same original PNG. Each blank row can grow
/// for accessible text without moving content outside its illustrated box.
class _RewardsBand extends StatelessWidget {
  const _RewardsBand(
      {required this.top,
      required this.bottom,
      required this.height,
      required this.slots});
  static const cropWidth = 1087.0;
  final double top, bottom, height;
  final List<(Rect, Widget)> slots;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final sx = box.maxWidth / cropWidth;
        final sy = height / (bottom - top);
        return SizedBox(
            width: box.maxWidth,
            height: height,
            child: Stack(children: [
              Positioned.fill(
                  child: ClipRect(
                      child: Stack(children: [
                Positioned(
                    left: -18 * sx,
                    top: -top * sy,
                    width: 1122 * sx,
                    height: 1402 * sy,
                    child: Image.asset(ParentRewardsFrame.asset,
                        fit: BoxFit.fill, excludeFromSemantics: true)),
              ]))),
              for (final (rect, child) in slots)
                Positioned(
                    left: (rect.left - 18) * sx,
                    top: (rect.top - top) * sy,
                    width: rect.width * sx,
                    height: rect.height * sy,
                    child: child),
            ]));
      });
}
