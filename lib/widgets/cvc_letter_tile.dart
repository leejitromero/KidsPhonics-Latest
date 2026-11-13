import 'package:flutter/material.dart';
import 'button_sound.dart';

/// One independent frame so the three letters can move together while blending.
/// Fractional insets keep live text inside the cream face, clear of the stars.
class CvcLetterTile extends StatelessWidget {
  const CvcLetterTile({
    super.key,
    required this.letter,
    required this.highlighted,
    required this.vowel,
    required this.reducedMotion,
    required this.onPressed,
  });

  static const frameAsset = 'assets/images/cvc_letter_frame.webp';
  final String letter;
  final bool highlighted, vowel, reducedMotion;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => MergeSemantics(
          child: Semantics(
        label: 'Hear $letter sound',
        button: true,
        selected: highlighted,
        child: OutlinedButton(
          onPressed: withButtonSound(onPressed),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: const Color(0xFF37145E),
            side: BorderSide.none,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: ExcludeSemantics(
            child: Center(
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: LayoutBuilder(builder: (context, box) {
                  return Stack(fit: StackFit.expand, children: [
                    Image.asset(frameAsset,
                        fit: BoxFit.contain,
                        cacheWidth: 480,
                        excludeFromSemantics: true),
                    Positioned(
                      left: box.maxWidth * .17,
                      right: box.maxWidth * .17,
                      top: box.maxHeight * .32,
                      bottom: box.maxHeight * .30,
                      child: AnimatedContainer(
                        key: ValueKey('cvc-letter-face-$letter'),
                        duration: reducedMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: highlighted
                              ? const Color(0xFFFFE781)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: highlighted
                              ? const [
                                  BoxShadow(
                                      color: Color(0x66FFCE30), blurRadius: 12),
                                ]
                              : null,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(letter,
                              key: ValueKey('cvc-letter-label-$letter'),
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 88,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                color: highlighted
                                    ? const Color(0xFF085A47)
                                    : vowel
                                        ? const Color(0xFF9A175F)
                                        : const Color(0xFF37145E),
                              )),
                        ),
                      ),
                    ),
                    Positioned(
                      left: box.maxWidth * .37,
                      right: box.maxWidth * .37,
                      top: box.maxHeight * .80,
                      bottom: box.maxHeight * .08,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Icon(Icons.volume_up_rounded,
                            color: highlighted
                                ? const Color(0xFFFFF3A6)
                                : Colors.white),
                      ),
                    ),
                  ]);
                }),
              ),
            ),
          ),
        ),
      ));
}
