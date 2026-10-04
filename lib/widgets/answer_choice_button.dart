import 'package:flutter/material.dart';
import 'button_sound.dart';
import 'game_design.dart';

/// The supplied glossy frames, with live, accessible answer content on top.
class AnswerChoiceButton extends StatelessWidget {
  const AnswerChoiceButton(
      {super.key,
      required this.child,
      required this.onPressed,
      this.variant = 0,
      this.result,
      this.selected = false,
      this.buttonKey});

  final Widget child;
  final VoidCallback? onPressed;
  final int variant;
  final bool? result;
  final bool selected;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final edge = box.biggest.shortestSide;
        final inset = edge * .17;
        return Stack(fit: StackFit.expand, children: [
          if (GameDesign.active(context))
            IgnorePointer(
                child: ForestTile(
                    variant: variant, child: const SizedBox.expand()))
          else
            IgnorePointer(
                child: ClipRect(
                    child: FractionallySizedBox(
              widthFactor: 1.22,
              heightFactor: 1.22,
              child: Image.asset(
                  'assets/images/answer_choices/frame-${variant % 4 + 1}.png',
                  fit: BoxFit.fill,
                  cacheWidth: 512,
                  excludeFromSemantics: true),
            ))),
          ElevatedButton(
            key: buttonKey,
            onPressed: withButtonSound(onPressed),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(inset),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFF3E2454),
              disabledForegroundColor: const Color(0xFF3E2454),
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(edge * .24),
                  side: BorderSide(
                      color: selected
                          ? const Color(0xFFFFD23F)
                          : Colors.transparent,
                      width: 3)),
            ),
            child: child,
          ),
          if (result != null)
            Positioned(
                top: 1,
                right: 1,
                child: IgnorePointer(
                    child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: result!
                          ? const Color(0xFF167769)
                          : const Color(0xFFB63D50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                          result! ? Icons.check_rounded : Icons.refresh_rounded,
                          color: Colors.white,
                          size: edge < 70 ? 14 : 22)),
                ))),
        ]);
      });
}
