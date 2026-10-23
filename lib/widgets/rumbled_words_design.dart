import 'package:flutter/material.dart';
import 'button_sound.dart';
import 'game_design.dart';
import '../models/difficulty.dart';

class RumbledRoundHeader extends StatelessWidget {
  const RumbledRoundHeader(
      {super.key,
      required this.difficulty,
      required this.current,
      required this.total});
  final Difficulty difficulty;
  final int current, total;
  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      Difficulty.easy => const Color(0xFF167769),
      Difficulty.medium => const Color(0xFF7052CA),
      Difficulty.hard => const Color(0xFFB45731),
    };
    return ForestPanel(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Column(children: [
          SizedBox(
              height: 32,
              child: Row(children: [
                Expanded(
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12)),
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(difficulty.label,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white))))),
                const SizedBox(width: 8),
                Expanded(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text('$current / $total words',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: GameDesign.ink))))
              ])),
          const SizedBox(height: 5),
          Semantics(
              label: 'Word $current of $total',
              child: LinearProgressIndicator(
                  value: current / total,
                  minHeight: 7,
                  color: color,
                  backgroundColor: const Color(0xFFDAD6DF),
                  borderRadius: BorderRadius.circular(12)))
        ]));
  }
}

/// A centered board that keeps the same tile size for slots and letter choices.
class RumbledTileGrid extends StatelessWidget {
  const RumbledTileGrid(
      {super.key,
      required this.side,
      required this.columns,
      required this.gap,
      required this.children});
  final double side, gap;
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
      child: SizedBox(
          width: columns * side + (columns - 1) * gap + .01,
          child: Wrap(
              spacing: gap,
              runSpacing: gap,
              alignment: WrapAlignment.center,
              children: [
                for (final child in children)
                  SizedBox(width: side, height: side, child: child)
              ])));
}

/// Glossy rounded controls with live labels and the game's original callbacks.
class RumbledActionButton extends StatelessWidget {
  const RumbledActionButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onPressed,
      required this.height,
      this.purple = false,
      this.cream = false,
      this.buttonKey});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double height;
  final bool purple, cream;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) => Container(
      height: height,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, .18, .55, 1],
              colors: cream
                  ? const [
                      Color(0xFFFFFEF6),
                      Color(0xFFFFF5DA),
                      Color(0xFFF4DEB9),
                      Color(0xFFE9C995)
                    ]
                  : purple
                      ? const [
                          Color(0xFFE3A3FF),
                          Color(0xFFB04CFA),
                          Color(0xFF8A2AE2),
                          Color(0xFF6320B9)
                        ]
                      : const [
                          Color(0xFF7CF4CF),
                          Color(0xFF05C8AC),
                          Color(0xFF00A094),
                          Color(0xFF007C82)
                        ]),
          border: Border.all(
              color: purple ? const Color(0xFFD6ACFF) : const Color(0xFFFFE697),
              width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x443D2467), offset: Offset(0, 3), blurRadius: 5)
          ]),
      child: OutlinedButton(
          key: buttonKey,
          onPressed: withButtonSound(onPressed),
          style: OutlinedButton.styleFrom(
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              foregroundColor: cream ? GameDesign.ink : Colors.white,
              disabledForegroundColor:
                  cream ? const Color(0xFF6B5782) : const Color(0xFFDDEBEA),
              side: const BorderSide(color: Color(0xBBFFFFFF), width: 2),
              shape: const StadiumBorder()),
          child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 28),
                const SizedBox(width: 10),
                Text(label,
                    style: const TextStyle(
                        fontSize: 23,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900))
              ]))));
}
