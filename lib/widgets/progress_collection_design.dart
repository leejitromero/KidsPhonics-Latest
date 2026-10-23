import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/learning_progress.dart';
import '../models/weekly_learning_summary.dart';
import 'button_sound.dart';
import 'progress_design.dart';

String collectionStatusName(LearningStatus status) => switch (status) {
      LearningStatus.notStarted => 'New',
      LearningStatus.viewed => 'Explored',
      LearningStatus.practiced => 'Practiced',
      LearningStatus.mastered => 'Mastered',
    };
Color collectionStatusColor(LearningStatus status) => switch (status) {
      LearningStatus.notStarted => const Color(0xFF716C99),
      LearningStatus.viewed => const Color(0xFF0874C9),
      LearningStatus.practiced => const Color(0xFFB85108),
      LearningStatus.mastered => progressGreen,
    };
IconData collectionStatusIcon(LearningStatus status) => switch (status) {
      LearningStatus.notStarted => Icons.circle_outlined,
      LearningStatus.viewed => Icons.visibility_rounded,
      LearningStatus.practiced => Icons.edit_rounded,
      LearningStatus.mastered => Icons.check_rounded,
    };
Color _statusTint(LearningStatus status) => switch (status) {
      LearningStatus.notStarted => const Color(0xFFF0E9FF),
      LearningStatus.viewed => const Color(0xFFE0F3FF),
      LearningStatus.practiced => const Color(0xFFFFF1CC),
      LearningStatus.mastered => const Color(0xFFDCF9EB),
    };

class ProgressCollectionHeader extends StatelessWidget {
  const ProgressCollectionHeader(
      {super.key,
      required this.letters,
      required this.selected,
      required this.onSelected});
  final List<LetterProgress> letters;
  final LearningStatus? selected;
  final ValueChanged<LearningStatus?> onSelected;
  @override
  Widget build(BuildContext context) => ProgressCard(
      tint: const Color(0xFFEFF8FF),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(5),
              decoration: progressGloss(progressPurple, radius: 16),
              child: Image.asset(
                  'assets/images/lesson_logos/letter_recognition.webp',
                  excludeFromSemantics: true)),
          const SizedBox(width: 8),
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('My Letter Collection',
                    style: TextStyle(
                        fontSize: 18,
                        color: progressInk,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 2),
                Text('Tap a letter to practice.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF655F8E))),
              ])),
        ]),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, box) {
          final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
          final columns = box.maxWidth >= 260 * scale ? 2 : 1;
          final width = (box.maxWidth - (columns - 1) * 8) / columns;
          return Wrap(spacing: 8, runSpacing: 8, children: [
            for (final status in [null, ...LearningStatus.values])
              SizedBox(
                  width: width,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.white,
                            status == null
                                ? const Color(0xFFEADAFF)
                                : _statusTint(status)
                          ]),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: selected == status
                                  ? progressPurple
                                  : Colors.white,
                              width: selected == status ? 2 : 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: (status == null
                                        ? progressPurple
                                        : collectionStatusColor(status))
                                    .withValues(alpha: .15),
                                blurRadius: 7,
                                offset: const Offset(0, 3))
                          ]),
                      child: ChoiceChip(
                        surfaceTintColor: Colors.transparent,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        visualDensity: VisualDensity.standard,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        color: const WidgetStatePropertyAll(Colors.transparent),
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                        avatar: Icon(
                            status == null
                                ? Icons.check_circle_rounded
                                : collectionStatusIcon(status),
                            color: status == null
                                ? progressPurple
                                : collectionStatusColor(status),
                            size: 20),
                        label: Text(
                            status == null
                                ? 'All 26'
                                : '${collectionStatusName(status)} (${letters.where((l) => l.status == status).length})',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: status == LearningStatus.viewed
                                    ? const Color(0xFF1454A6)
                                    : progressInk)),
                        selected: selected == status,
                        onSelected:
                            withSelectionSound((_) => onSelected(status)),
                      ))),
          ]);
        }),
      ]));
}

class ProgressLetterTile extends StatelessWidget {
  const ProgressLetterTile(
      {super.key, required this.letter, required this.onPressed});
  final LetterProgress letter;
  final VoidCallback onPressed;
  static const purpleFrame =
      'assets/images/progress_collection/letter_frame_purple.png';
  static const greenFrame =
      'assets/images/progress_collection/letter_frame_green.png';

  @override
  Widget build(BuildContext context) {
    final color = collectionStatusColor(letter.status);
    final mastered = letter.status == LearningStatus.mastered;
    return Semantics(
        label: '${letter.letter}: ${collectionStatusName(letter.status)}',
        button: true,
        child: Tooltip(
            message: collectionStatusName(letter.status),
            child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                    key: ValueKey('progress-letter-${letter.letter}'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: withButtonSound(onPressed),
                    child: LayoutBuilder(
                        builder: (_, box) => ClipRect(
                                child: Stack(fit: StackFit.expand, children: [
                              // Display the frame's source rectangle (200, 40,
                              // 850, 1175), keeping the original PNG unchanged.
                              Positioned(
                                  left: -box.maxWidth * 200 / 850,
                                  top: -box.maxHeight * 40 / 1175,
                                  width: box.maxWidth * 1254 / 850,
                                  height: box.maxHeight * 1254 / 1175,
                                  child: Image.asset(
                                      mastered ? greenFrame : purpleFrame,
                                      key: ValueKey(
                                          'progress-letter-frame-${letter.letter}'),
                                      fit: BoxFit.fill,
                                      cacheWidth: 400,
                                      excludeFromSemantics: true)),
                              Positioned(
                                  left: box.maxWidth * .17,
                                  top: box.maxHeight * .18,
                                  width: box.maxWidth * .66,
                                  height: box.maxHeight * .57,
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(letter.letter,
                                          style: TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 40,
                                              fontWeight: FontWeight.w900,
                                              color: color,
                                              shadows: [
                                                const Shadow(
                                                    color: Colors.white,
                                                    offset: Offset(0, -1)),
                                                Shadow(
                                                    color: color.withValues(
                                                        alpha: .2),
                                                    blurRadius: 2,
                                                    offset: const Offset(0, 2))
                                              ])))),
                              if (mastered)
                                Positioned(
                                    left: box.maxWidth * .454,
                                    top: box.maxHeight * .885,
                                    width: box.maxWidth * .10,
                                    height: box.maxHeight * .075,
                                    child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: Icon(Icons.check_rounded,
                                            key: ValueKey(
                                                'progress-letter-check-${letter.letter}'),
                                            color: color,
                                            size: 24)))
                            ])))))));
  }
}

class ProgressTreasureShelf extends StatelessWidget {
  const ProgressTreasureShelf(
      {super.key, required this.level, required this.stars, required this.xp});
  final int level, stars, xp;
  @override
  Widget build(BuildContext context) => ProgressCard(
      tint: const Color(0xFFFFF6DD),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: progressGloss(const Color(0xFFB56B17), radius: 30),
            child: const Row(children: [
              Icon(Icons.emoji_events_rounded,
                  color: Color(0xFFFFD849), size: 24),
              SizedBox(width: 8),
              Expanded(
                  child: Text('My Treasure Shelf',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)))
            ])),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, box) {
          final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
          final columns = box.maxWidth >= 235 * scale ? 3 : 1;
          final width = (box.maxWidth - (columns - 1) * 8) / columns;
          return Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (icon, label, color, tint) in [
              (
                Icons.emoji_events_rounded,
                'Level $level',
                const Color(0xFFC97300),
                const Color(0xFFFFEFC3)
              ),
              (
                Icons.star_rounded,
                '$stars Stars',
                const Color(0xFFFFB514),
                const Color(0xFFFFEFC3)
              ),
              (
                Icons.bolt_rounded,
                '$xp XP',
                progressPurple,
                const Color(0xFFE9D4FF)
              ),
            ])
              Container(
                  width: width,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                  decoration: progressGloss(tint, radius: 20),
                  child: Column(children: [
                    Icon(icon, size: 28, color: color, shadows: [
                      Shadow(
                          color: Color.lerp(color, Colors.black, .25)!,
                          offset: const Offset(0, 2),
                          blurRadius: 2)
                    ]),
                    const SizedBox(height: 4),
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 3),
                        decoration: BoxDecoration(
                            color: tint,
                            borderRadius: BorderRadius.circular(18)),
                        child: Text(label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: icon == Icons.bolt_rounded
                                    ? progressPurple
                                    : const Color(0xFF803309)))),
                  ])),
          ]);
        }),
        const SizedBox(height: 8),
        Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: const Color(0x99FFF0CC),
                borderRadius: BorderRadius.circular(26)),
            child: const Row(children: [
              Icon(Icons.star_rounded, color: Color(0xFFFFBC24), size: 20),
              SizedBox(width: 6),
              Expanded(
                  child: Text('Stars and XP celebrate your practice!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: progressInk))),
              SizedBox(width: 6),
              Icon(Icons.star_rounded, color: Color(0xFFFFBC24), size: 20)
            ])),
      ]));
}

class ProgressAchievementCard extends StatelessWidget {
  const ProgressAchievementCard(
      {super.key, required this.achievement, required this.onPressed});
  final LearningAchievement achievement;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(26), boxShadow: [
        BoxShadow(
            color: (achievement.unlocked
                    ? const Color(0xFFFFC64C)
                    : const Color(0xFF87BCEF))
                .withValues(alpha: .25),
            blurRadius: 10,
            offset: const Offset(0, 4))
      ]),
      child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              key: ValueKey('progress-badge-${achievement.title}'),
              onTap: withButtonSound(onPressed),
              child: Ink(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                          colors: achievement.unlocked
                              ? [const Color(0xFFFFF8DA), Colors.white]
                              : [const Color(0xFFEDF6FF), Colors.white]),
                      border: Border.all(
                          color: achievement.unlocked
                              ? const Color(0xFFFFD366)
                              : Colors.white,
                          width: 2)),
                  child: Stack(children: [
                    const Positioned.fill(
                        child: IgnorePointer(
                            child: CustomPaint(painter: _CloudStarsPainter()))),
                    Padding(
                        padding: const EdgeInsets.all(10),
                        child: LayoutBuilder(builder: (context, box) {
                          final stacked = box.maxWidth < 260 &&
                              MediaQuery.textScalerOf(context).scale(16) > 21;
                          final medal = SizedBox(
                              width: 56,
                              height: 62,
                              child: CustomPaint(
                                  painter: _MedalPainter(
                                      earned: achievement.unlocked),
                                  child: Center(
                                      child: Icon(
                                          achievement.unlocked
                                              ? Icons.star_rounded
                                              : Icons.lock_rounded,
                                          color: achievement.unlocked
                                              ? const Color(0xFFFFE471)
                                              : const Color(0xFF6B5494),
                                          size: 27,
                                          shadows: const [
                                        Shadow(
                                            color: Colors.white,
                                            offset: Offset(0, -1))
                                      ]))));
                          final text = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(achievement.title,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: progressInk)),
                                const SizedBox(height: 3),
                                Text(achievement.description,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF62598D))),
                                const SizedBox(height: 4),
                                Text(
                                    achievement.unlocked
                                        ? 'You earned it!'
                                        : 'Keep exploring!',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: achievement.unlocked
                                            ? progressGreen
                                            : progressPurple)),
                              ]);
                          return stacked
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [Center(child: medal), text])
                              : Row(children: [
                                  medal,
                                  const SizedBox(width: 8),
                                  Expanded(child: text),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: Color(0xFF9C8ADC), size: 22)
                                ]);
                        })),
                  ])))));
}

class _CloudStarsPainter extends CustomPainter {
  const _CloudStarsPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final cloud = Paint()..color = Colors.white.withValues(alpha: .8);
    for (final (x, y, radius) in [
      (.04, .94, .16),
      (.22, 1.0, .15),
      (.83, 1.0, .17),
      (.98, .88, .19)
    ]) {
      canvas.drawCircle(Offset(size.width * x, size.height * y),
          math.min(size.width, size.height) * radius, cloud);
    }
    for (final (x, y, radius) in [
      (.12, .32, 4.5),
      (.82, .22, 3.5),
      (.88, .56, 4.0)
    ]) {
      final path = Path();
      final center = Offset(size.width * x, size.height * y);
      for (var i = 0; i < 10; i++) {
        final angle = -math.pi / 2 + i * math.pi / 5;
        final length = i.isEven ? radius : radius * .5;
        final point =
            center + Offset(math.cos(angle), math.sin(angle)) * length;
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path..close(), Paint()..color = const Color(0xFFFFD767));
    }
  }

  @override
  bool shouldRepaint(_CloudStarsPainter oldDelegate) => false;
}

class _MedalPainter extends CustomPainter {
  const _MedalPainter({required this.earned});
  final bool earned;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .44);
    final radius = size.width * .43;
    final ribbonScale = size.width / 82;
    if (earned) {
      for (final direction in [-1, 1]) {
        final ribbon = Path()
          ..moveTo(center.dx + direction * 8 * ribbonScale,
              center.dy + 22 * ribbonScale)
          ..lineTo(center.dx + direction * 29 * ribbonScale,
              size.height - 3 * ribbonScale)
          ..lineTo(center.dx + direction * 10 * ribbonScale,
              size.height - 9 * ribbonScale)
          ..lineTo(center.dx, center.dy + 30 * ribbonScale)
          ..close();
        canvas.drawPath(ribbon, Paint()..color = const Color(0xFFFF6742));
      }
    }
    final medal = Path();
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        medal.moveTo(point.dx, point.dy);
      } else {
        medal.lineTo(point.dx, point.dy);
      }
    }
    medal.close();
    canvas.drawShadow(medal, const Color(0x77666699), 3, true);
    canvas.drawPath(
        medal,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: earned
                      ? [const Color(0xFFFFE168), const Color(0xFFE99A1F)]
                      : [const Color(0xFFE8E2FF), const Color(0xFFAAA7EE)])
              .createShader(Offset.zero & size));
    canvas.drawPath(
        medal,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_MedalPainter oldDelegate) => earned != oldDelegate.earned;
}
