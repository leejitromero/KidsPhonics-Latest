import 'package:flutter/material.dart';
import '../models/difficulty.dart';
import 'game_design.dart';
import 'quick_choice_art.dart';

/// Keep both the difficulty and jar count on one readable line, including
/// narrow screens with enlarged text.
class RhymingRoundHeader extends StatelessWidget {
  const RhymingRoundHeader(
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
              height: 34,
              child: Row(children: [
                Expanded(
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12)),
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(difficulty.label,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white))))),
                const SizedBox(width: 8),
                Expanded(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text('$current / $total jar',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: GameDesign.ink)))),
              ])),
          const SizedBox(height: 6),
          LinearProgressIndicator(
              value: current / total,
              minHeight: 7,
              borderRadius: BorderRadius.circular(12),
              color: color,
              backgroundColor: const Color(0xFFDAD6DF)),
        ]));
  }
}

/// High-contrast controls remain readable over every playground frame.
class RhymingControlButton extends StatelessWidget {
  const RhymingControlButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onPressed,
      this.purple = false});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool purple;
  @override
  Widget build(BuildContext context) => Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: purple
                  ? const [Color(0xFFF1DEFF), Color(0xFFC79BFF)]
                  : const [Color(0xFFFFFDF1), Color(0xFFFFE6AD)]),
          border: Border.all(
              color: purple ? const Color(0xFFAC71EE) : const Color(0xFFE3AF59),
              width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x453E2771), offset: Offset(0, 3), blurRadius: 3)
          ]),
      child: IconButton(
          tooltip: label,
          onPressed: onPressed,
          color: GameDesign.ink,
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 28)));
}

class RhymingTargetPanels extends StatelessWidget {
  const RhymingTargetPanels(
      {super.key,
      required this.word,
      required this.collected,
      required this.onHear});
  final String word;
  final int collected;
  final VoidCallback? onHear;
  static const height = 112.0;
  @override
  Widget build(BuildContext context) => Column(children: [
        SizedBox(
            height: 64,
            width: double.infinity,
            child: ForestPanel(
                key: const ValueKey('rhyme-target-panel'),
                leaves: false,
                padding: EdgeInsets.zero,
                child: Tooltip(
                    message: 'Hear target word',
                    child: TextButton(
                        onPressed: onHear,
                        style: TextButton.styleFrom(
                            foregroundColor: GameDesign.ink,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(48, 48)),
                        child: Row(children: [
                          Expanded(
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(word,
                                      key: const ValueKey('rhyme-target'),
                                      style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                          color: GameDesign.ink)))),
                          const SizedBox(width: 4),
                          Icon(Icons.volume_up_rounded,
                              size: 20,
                              color: onHear == null
                                  ? const Color(0xFF9585B3)
                                  : GameDesign.ink),
                        ]))))),
        const SizedBox(height: 6),
        SizedBox(
            height: 42,
            width: double.infinity,
            child: ForestPanel(
                key: const ValueKey('rhyme-score-panel'),
                leaves: false,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Semantics(
                    liveRegion: true,
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('$collected / 3 rhymes',
                            style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 19,
                                color: GameDesign.ink,
                                fontWeight: FontWeight.w900)))))),
      ]);
}

class RhymingPauseOverlay extends StatelessWidget {
  const RhymingPauseOverlay({super.key, required this.onResume});
  final VoidCallback onResume;
  @override
  Widget build(BuildContext context) => ColoredBox(
      color: const Color(0x9923355B),
      child: Center(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: ForestPanel(
                      key: const ValueKey('rhyming-pause-card'),
                      leaves: false,
                      accent: const Color(0xFFAC67F0),
                      padding: const EdgeInsets.all(16),
                      child: Stack(children: [
                        const Positioned(
                            top: 0,
                            left: 0,
                            child: Icon(Icons.star_rounded,
                                size: 21, color: Color(0xFFFFCE53))),
                        const Positioned(
                            top: 0,
                            right: 0,
                            child: Icon(Icons.star_rounded,
                                size: 18, color: Color(0xFFC79BEE))),
                        Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Paused',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 34,
                                              fontWeight: FontWeight.w900,
                                              color: GameDesign.ink)))),
                              const SizedBox(height: 14),
                              SizedBox(
                                  height: 56,
                                  child: FilledButton(
                                      key: const ValueKey(
                                          'rhyming-resume-button'),
                                      onPressed: onResume,
                                      style: quickColorButtonStyle(
                                          index: 3,
                                          radius: 36,
                                          minimumSize: const Size(48, 48),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8)),
                                      child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.play_arrow_rounded,
                                                size: 30),
                                            SizedBox(width: 6),
                                            Flexible(
                                                child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text('Resume',
                                                        style: TextStyle(
                                                            fontSize: 23,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w900)))),
                                          ]))),
                            ]),
                      ]))))));
}
