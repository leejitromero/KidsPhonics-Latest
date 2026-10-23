import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared presentation for the existing recommendation and its existing action.
class RecommendedPracticeCard extends StatelessWidget {
  const RecommendedPracticeCard({
    super.key,
    required this.leading,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.buttonIcon = Icons.play_arrow_rounded,
    this.actionKey,
  });
  final Widget leading;
  final String title, description, buttonLabel;
  final VoidCallback? onPressed;
  final IconData buttonIcon;
  final Key? actionKey;
  static const asset =
      'assets/images/progress_collection/recommended_practice_frame.png';

  @override
  Widget build(BuildContext context) => Center(
      heightFactor: 1,
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: LayoutBuilder(builder: (_, box) {
            final width = box.maxWidth;
            final height = math.max(240.0, width * 2 / 3);
            return SizedBox(
                width: width,
                height: height,
                child: Stack(fit: StackFit.expand, children: [
                  ClipPath(
                      clipper: const _RecommendationArtworkClipper(),
                      child: Image.asset(asset,
                          fit: BoxFit.fill, excludeFromSemantics: true)),
                  Positioned(
                      left: width * .165,
                      top: height * .17,
                      width: width * .745,
                      height: height * .10,
                      child: const Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Recommended Practice',
                                  style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF995800)))))),
                  Positioned(
                      left: width * .085,
                      top: height * .36,
                      width: width * .17,
                      height: height * .24,
                      child: FittedBox(fit: BoxFit.contain, child: leading)),
                  Positioned(
                      left: width * .305,
                      top: height * .34,
                      width: width * .60,
                      height: height * .28,
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                  width: width * .60,
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(title,
                                            style: const TextStyle(
                                                fontFamily: 'Nunito',
                                                fontSize: 18,
                                                height: 1.12,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF32116A))),
                                        const SizedBox(height: 4),
                                        Text(description,
                                            style: const TextStyle(
                                                fontFamily: 'Nunito',
                                                fontSize: 12,
                                                height: 1.2,
                                                color: Color(0xFF655582)))
                                      ]))))),
                  Positioned(
                      left: width * .06,
                      top: height * .66,
                      width: width * .87,
                      height: height * .20,
                      child: FilledButton(
                          key: actionKey,
                          onPressed: onPressed,
                          style: ButtonStyle(
                              padding: const WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6)),
                              minimumSize:
                                  const WidgetStatePropertyAll(Size.zero),
                              backgroundColor: const WidgetStatePropertyAll(
                                  Colors.transparent),
                              foregroundColor: WidgetStateProperty.resolveWith(
                                  (states) =>
                                      states.contains(WidgetState.disabled)
                                          ? const Color(0xB3FFFFFF)
                                          : Colors.white),
                              surfaceTintColor: const WidgetStatePropertyAll(
                                  Colors.transparent),
                              shadowColor: const WidgetStatePropertyAll(
                                  Colors.transparent),
                              elevation: const WidgetStatePropertyAll(0),
                              shape:
                                  const WidgetStatePropertyAll(StadiumBorder())),
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(buttonIcon, size: 22),
                                const SizedBox(width: 6),
                                Text(buttonLabel,
                                    style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900))
                              ]))))
                ]));
          })));
}

/// The original PNG has an opaque black exterior; clip only that exterior
/// during painting, without modifying or regenerating the supplied artwork.
class _RecommendationArtworkClipper extends CustomClipper<Path> {
  const _RecommendationArtworkClipper();
  @override
  Path getClip(Size size) => Path()
    ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(size.width * 32 / 1536, size.height * 91 / 1024,
            size.width * 1496 / 1536, size.height * 962 / 1024),
        Radius.elliptical(size.width * 132 / 1536, size.height * 132 / 1024)));
  @override
  bool shouldReclip(_RecommendationArtworkClipper oldClipper) => false;
}
