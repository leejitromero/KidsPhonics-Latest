import 'package:flutter/material.dart';
import '../models/difficulty.dart';
import '../theme/kids_ui.dart';
import 'game_design.dart';

class ActivityRoundHeader extends StatelessWidget {
  const ActivityRoundHeader(
      {super.key,
      this.difficulty,
      this.current,
      this.total,
      required this.label});
  final Difficulty? difficulty;
  final int? current, total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = switch (difficulty) {
      Difficulty.easy => const Color(0xFF167769),
      Difficulty.hard => const Color(0xFFB45731),
      _ => const Color(0xFF7052CA),
    };
    final hasProgress = current != null && total != null && total! > 0;
    if (difficulty == null && !hasProgress) return const SizedBox.shrink();
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        if (difficulty != null)
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color.lerp(accent, Colors.white, .18)!, accent]),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(difficulty!.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900))),
        if (hasProgress) ...[
          const SizedBox(width: 6),
          Expanded(
              child: Text('$current / $total ${label.toLowerCase()}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      color: GameDesign.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900))),
        ],
      ]),
      if (hasProgress) ...[
        const SizedBox(height: 6),
        Semantics(
            label: '$label $current of $total',
            child: LinearProgressIndicator(
                value: (current! / total!).clamp(0, 1),
                minHeight: 7,
                color: accent,
                backgroundColor: const Color(0xFFDAD6DF),
                borderRadius: BorderRadius.circular(12))),
      ],
    ]);
    if (GameDesign.active(context)) {
      return ForestPanel(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: content);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: .18))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          if (difficulty != null)
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: accent, borderRadius: BorderRadius.circular(10)),
                child: Text(difficulty!.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800))),
          if (hasProgress) ...[
            const SizedBox(width: 8),
            Expanded(
                child: Text('$current / $total ${label.toLowerCase()}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        color: KidsUi.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800))),
          ],
        ]),
        if (hasProgress) ...[
          const SizedBox(height: 8),
          Semantics(
              label: '$label $current of $total',
              child: LinearProgressIndicator(
                  value: (current! / total!).clamp(0, 1),
                  minHeight: 6,
                  color: accent,
                  backgroundColor: accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8))),
        ],
      ]),
    );
  }
}
