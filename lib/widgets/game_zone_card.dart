import 'button_sound.dart';
import 'package:flutter/material.dart';

class GameZoneCard extends StatelessWidget {
  const GameZoneCard(
      {super.key,
      required this.title,
      required this.description,
      required this.imageAsset,
      required this.accent,
      required this.onPressed});
  final String title, description, imageAsset;
  final Color accent;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(26), boxShadow: [
        BoxShadow(
            color: accent.withValues(alpha: .19),
            blurRadius: 12,
            offset: const Offset(0, 5))
      ]),
      child: Material(
          color: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
              side: BorderSide(
                  color: Color.lerp(Colors.white, accent, .24)!, width: 3)),
          child: InkWell(
              onTap: withButtonSound(onPressed),
              child: Ink(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                        Color.lerp(Colors.white, accent, .22)!,
                        Color.lerp(Colors.white, accent, .36)!
                            .withValues(alpha: .94)
                      ])),
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AspectRatio(
                                aspectRatio: 1.15,
                                child: Image.asset(imageAsset,
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true,
                                    cacheWidth: (220 *
                                            MediaQuery.devicePixelRatioOf(
                                                context))
                                        .ceil())),
                            const SizedBox(height: 5),
                            Text(title,
                                style: const TextStyle(
                                    color: Color(0xFF19134E),
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    height: 1.12)),
                            const SizedBox(height: 7),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                      child: Text(description,
                                          style: const TextStyle(
                                              color: Color(0xFF29235F),
                                              fontSize: 14,
                                              height: 1.25))),
                                  const SizedBox(width: 6),
                                  Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color.lerp(
                                                    accent, Colors.white, .25)!,
                                                accent
                                              ]),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: .7),
                                              width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                                color: accent.withValues(
                                                    alpha: .25),
                                                offset: const Offset(0, 3),
                                                blurRadius: 3)
                                          ]),
                                      child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 32)),
                                ]),
                          ]))))));
}
