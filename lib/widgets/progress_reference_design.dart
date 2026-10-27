import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/progress_badge.dart';
import 'button_sound.dart';
import 'progress_design.dart';
import 'progress_rewards_frames.dart';

class ProgressSurface extends StatelessWidget {
  const ProgressSurface(
      {super.key,
      required this.child,
      this.color = const Color(0xFFF7F0FF),
      this.padding = 12});
  final Widget child;
  final Color color;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, color]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(
                color: Color(0x326B3B75), offset: Offset(0, 4), blurRadius: 8)
          ]),
      child: DefaultTextStyle.merge(
          style: const TextStyle(color: progressInk), child: child));
}

class ProgressTitleBanner extends StatelessWidget {
  const ProgressTitleBanner(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.asset});
  final String title, subtitle, asset;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFAD65F8), Color(0xFF7526DE)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFDB88), width: 3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x706E3B35), offset: Offset(0, 4), blurRadius: 4)
          ]),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 26,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const SizedBox(height: 5),
          Text(subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.white)),
        ])),
        const SizedBox(width: 8),
        SizedBox(
            width: 64,
            height: 62,
            child: Stack(alignment: Alignment.center, children: [
              Image.asset(asset,
                  fit: BoxFit.contain, excludeFromSemantics: true),
              const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(Icons.star_rounded,
                      color: Color(0xFFFFD44A), size: 21)),
              const Positioned(
                  bottom: 0,
                  left: 0,
                  child: Icon(Icons.star_rounded,
                      color: Color(0xFFFFEC9E), size: 15)),
            ])),
      ]));
}

class ProgressSectionLabel extends StatelessWidget {
  const ProgressSectionLabel(this.title, this.icon,
      {super.key, this.color = progressPurple});
  final String title;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: color, size: 23),
        const SizedBox(width: 7),
        Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: color))),
      ]);
}

class ProgressValueBar extends StatelessWidget {
  const ProgressValueBar(
      {super.key,
      required this.current,
      required this.total,
      required this.color});
  final int current, total;
  final Color color;
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LinearProgressIndicator(
          value: total == 0 ? 0 : (current / total).clamp(0.0, 1.0),
          minHeight: 9,
          backgroundColor: const Color(0xFFE2DCEF),
          color: color));
}

class ProgressSkillRow extends StatelessWidget {
  const ProgressSkillRow(
      {super.key,
      required this.title,
      required this.unit,
      required this.current,
      required this.total,
      required this.color,
      required this.icon,
      required this.onPressed});
  final String title, unit;
  final int current, total;
  final Color color;
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
          onTap: withButtonSound(onPressed),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(children: [
                Container(
                    width: 36,
                    height: 42,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(14)),
                    child: switch (title) {
                      'Letters' => Image.asset(
                          'assets/images/lesson_logos/letter_recognition.webp',
                          fit: BoxFit.contain,
                          excludeFromSemantics: true),
                      'Vowels' => Image.asset('assets/images/letters/a.webp',
                          fit: BoxFit.contain, excludeFromSemantics: true),
                      'CVC Words' => Image.asset(
                          'assets/images/lessons_menu/cvc_words.webp',
                          fit: BoxFit.contain,
                          excludeFromSemantics: true),
                      'Blending Sounds' => Image.asset(
                          'assets/images/lessons_menu/blending_sounds.webp',
                          fit: BoxFit.contain,
                          excludeFromSemantics: true),
                      _ => Icon(icon, size: 28, color: color),
                    }),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      ProgressValueBar(
                          current: current, total: total, color: color),
                    ])),
                const SizedBox(width: 8),
                SizedBox(
                    width: 62,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('$current / $total',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w900))),
                      FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(unit,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF645583)))),
                    ])),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: color, size: 18),
              ]))));
}

class ProgressCountRing extends StatelessWidget {
  const ProgressCountRing(
      {super.key,
      required this.count,
      required this.total,
      this.label = 'letters mastered'});
  final int count, total;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
      label: '$count of $total $label',
      child: SizedBox(
          width:
              112 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.8),
          height:
              112 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.8),
          child: Stack(alignment: Alignment.center, children: [
            const Positioned(
                top: 0,
                child: Icon(Icons.star_rounded,
                    color: Color(0xFFFFC62B), size: 24)),
            Positioned.fill(
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                        value: count / total,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        color: progressPurple,
                        backgroundColor: const Color(0xFFE5DDF0)))),
            Padding(
                padding: const EdgeInsets.all(19),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('$count / $total',
                              style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  color: progressPurple))),
                      Text(label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, height: 1.1)),
                    ])),
          ])));
}

class ProgressBadgeCard extends StatelessWidget {
  const ProgressBadgeCard(
      {super.key,
      required this.badge,
      required this.index,
      required this.onPressed});
  final ProgressBadge badge;
  final int index;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFFEF45A3),
      Color(0xFF18B0EE),
      Color(0xFF28BD73),
      Color(0xFF9040ED),
      Color(0xFFFF9B28)
    ];
    const icons = [
      Icons.auto_stories_rounded,
      Icons.star_rounded,
      Icons.abc_rounded,
      Icons.extension_rounded,
      Icons.local_fire_department_rounded
    ];
    final color = colors[index % colors.length];
    final medal = Center(
        child: SizedBox(
            width: 52,
            height: 62,
            child: Stack(alignment: Alignment.center, children: [
              if (index < 5 && index != 1)
                Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                        [
                          'assets/images/lesson_logos/letter_recognition.webp',
                          'assets/images/letters/a.webp',
                          'assets/images/lessons_menu/cvc_words.webp',
                          'assets/images/lessons_menu/blending_sounds.webp',
                          'assets/images/home_banner/fire.png',
                        ][index],
                        fit: BoxFit.contain,
                        excludeFromSemantics: true))
              else if (index == 1)
                const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('A E I\nO U',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: progressPurple,
                            fontSize: 14,
                            height: 1.05,
                            fontWeight: FontWeight.w900)))
              else
                Icon(icons[index % icons.length],
                    color: color,
                    size: 34,
                    shadows: const [
                      Shadow(color: Color(0x5556337A), offset: Offset(0, 2))
                    ]),
            ])));
    final details =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(badge.title,
          style: const TextStyle(
              fontSize: 17,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: progressInk)),
      const SizedBox(height: 4),
      Text(badge.description,
          style: const TextStyle(
              fontSize: 12, height: 1.3, color: Color(0xFF685583))),
      const SizedBox(height: 9),
      Row(children: [
        Expanded(
            child: ProgressValueBar(
                current: badge.count,
                total: badge.target,
                color: badge.earned ? progressGreen : color)),
        const SizedBox(width: 8),
        Text('${badge.count} / ${badge.target}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
      ]),
    ]);
    return Semantics(
        button: true,
        label:
            '${badge.title}, ${badge.earned ? 'earned' : 'locked'}, ${badge.count} of ${badge.target}',
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                key: ValueKey('progress-badge-${badge.id}'),
                onTap: withButtonSound(onPressed),
                borderRadius: BorderRadius.circular(24),
                child: LayoutBuilder(builder: (context, box) {
                  final width = box.maxWidth * .61;
                  final contentHeight = rewardTextHeight(
                          context,
                          badge.title,
                          const TextStyle(
                              fontSize: 17,
                              height: 1.15,
                              fontWeight: FontWeight.w900),
                          width) +
                      4 +
                      rewardTextHeight(context, badge.description,
                          const TextStyle(fontSize: 12, height: 1.3), width) +
                      9 +
                      math.max(
                          8,
                          rewardTextHeight(
                              context,
                              '${badge.count} / ${badge.target}',
                              const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w900),
                              width));
                  final height = math.max(
                      box.maxWidth * 578 / 2060, (contentHeight + 2) / .68);
                  final lock = Icon(
                      badge.earned
                          ? Icons.verified_rounded
                          : Icons.lock_rounded,
                      color: badge.earned
                          ? progressGreen
                          : const Color(0xFF9081B6),
                      size: 23);
                  return SizedBox(
                      height: height,
                      child: Stack(fit: StackFit.expand, children: [
                        const ProgressRewardArtwork(
                            name: 'frame_rewards_contain'),
                        Positioned(
                            left: box.maxWidth * .085,
                            top: height * .24,
                            width: box.maxWidth * .14,
                            height: height * .48,
                            child: medal),
                        Positioned(
                            key: ValueKey('rewards-card-content-${badge.id}'),
                            left: box.maxWidth * .275,
                            top: height * .16,
                            width: width,
                            height: height * .68,
                            child: Center(child: details)),
                        Positioned(
                            left: box.maxWidth * .90,
                            top: height * .28,
                            width: box.maxWidth * .06,
                            height: height * .44,
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(child: lock),
                                  const FittedBox(
                                      child: Icon(Icons.chevron_right_rounded,
                                          size: 20, color: progressPurple))
                                ])),
                      ]));
                }))));
  }
}
