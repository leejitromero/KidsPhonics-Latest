import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An app welcome, visually separate from the characters' speech bubbles.
class HomeGreetingCard extends StatelessWidget {
  const HomeGreetingCard({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
      container: true,
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: LayoutBuilder(builder: (context, box) {
        final padding = math.min(12.0, box.maxHeight * .12);
        final split = text.lastIndexOf('! ');
        final heading = split < 0 ? text : text.substring(0, split + 1);
        final detail = split < 0 ? null : text.substring(split + 2);
        return DecoratedBox(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFE895), Color(0xFFF8B941)]),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x403E2164),
                      blurRadius: 10,
                      offset: Offset(0, 4)),
                ]),
            child: Padding(
                padding: const EdgeInsets.all(3),
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(color: Colors.white, width: 2),
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFFEF9), Color(0xFFFFF2D4)])),
                    child: Padding(
                        key: const ValueKey('home-greeting-content'),
                        padding: EdgeInsets.symmetric(
                            horizontal: padding, vertical: padding),
                        child: Row(children: [
                          const Icon(Icons.auto_awesome_rounded,
                              color: Color(0xFF9A55DB), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: LayoutBuilder(
                                  builder: (context, content) => FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: SizedBox(
                                          width: content.maxWidth,
                                          child: Text.rich(
                                              key: const ValueKey(
                                                  'home-greeting-text'),
                                              TextSpan(children: [
                                                TextSpan(text: heading),
                                                if (detail != null)
                                                  TextSpan(
                                                      text: '\n$detail',
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          height: 1.4,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Color(
                                                              0xFF634C80))),
                                              ]),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontFamily: 'Nunito',
                                                  fontSize: 22,
                                                  height: 1.15,
                                                  fontWeight: FontWeight.w900,
                                                  color:
                                                      Color(0xFF45216F))))))),
                          const SizedBox(width: 8),
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFD28A0B), size: 20),
                        ])))));
      }));
}
