import 'package:flutter/material.dart';
import '../theme/kids_ui.dart';
import 'game_design.dart';

/// A readable focal point for activities that combine a picture and a question.
class ActivityPrompt extends StatelessWidget {
  const ActivityPrompt(
      {super.key,
      required this.picture,
      required this.title,
      this.caption,
      this.accent = const Color(0xFF087F86)});
  final Widget picture;
  final String title;
  final String? caption;
  final Color accent;

  @override
  Widget build(BuildContext context) => GameDesign.active(context)
      ? ForestPanel(
          glass: true,
          accent: const Color(0xFFAE82F5),
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            picture,
            const SizedBox(height: 10),
            ForestPanel(
                leaves: false,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: GameDesign.ink,
                        fontSize: 27,
                        fontWeight: FontWeight.w900))),
            if (caption != null)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(caption!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: GameDesign.ink, fontSize: 16))),
          ]))
      : Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  KidsUi.cardSurface,
                  Color.lerp(Colors.white, accent, .08)!
                      .withValues(alpha: KidsUi.cardOpacity)
                ]),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: accent.withValues(alpha: .2)),
            boxShadow: [
              BoxShadow(
                  color: accent.withValues(alpha: .1),
                  blurRadius: 16,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Column(children: [
            picture,
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: KidsUi.ink)),
            if (caption != null) ...[
              const SizedBox(height: 8),
              Text(caption!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ]),
        );
}
