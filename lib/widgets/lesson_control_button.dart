import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/kids_ui.dart';
import 'button_sound.dart';

enum LessonButtonArt { next, previous, sound }

/// Uses the supplied PNGs, with live labels for large text and screen readers.
/// Each mounted control keeps its chosen color instead of changing on rebuild.
class LessonControlButton extends StatefulWidget {
  const LessonControlButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onPressed,
      this.art,
      this.primary = false});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final LessonButtonArt? art;
  final bool primary;
  @override
  State<LessonControlButton> createState() => _LessonControlButtonState();
}

class _LessonControlButtonState extends State<LessonControlButton> {
  late final int _variant = Random().nextInt(6);
  @override
  Widget build(BuildContext context) {
    final art = widget.art;
    final asset = art == null
        ? null
        : 'assets/images/button_designs/${art.name}_button_${_variant % (art == LessonButtonArt.previous ? 2 : 3) + 1}.png';
    return OutlinedButton(
      onPressed: withButtonSound(widget.onPressed),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        minimumSize: const Size(48, 72),
        backgroundColor: KidsUi.cardSurface,
        disabledBackgroundColor: KidsUi.cardSurface,
        foregroundColor: KidsUi.ink,
        disabledForegroundColor: KidsUi.muted,
        side: const BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          height: 48,
          width: double.infinity,
          child: Opacity(
            opacity: widget.onPressed == null ? .38 : 1,
            child: asset == null
                ? Center(
                    child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: widget.primary
                                    ? const [
                                        Color(0xFFAE77F4),
                                        Color(0xFF5931B0)
                                      ]
                                    : const [
                                        Color(0xFFFFD75E),
                                        Color(0xFFEAA326)
                                      ]),
                            border: Border.all(
                                color: const Color(0xFFFFF4CA), width: 2)),
                        child: Icon(widget.icon,
                            size: 26,
                            color: widget.primary ? Colors.white : KidsUi.ink)))
                : FittedBox(
                    fit: BoxFit.contain,
                    // Clip the transparent canvas margins at display time.
                    child: ClipRect(
                        child: Align(
                            heightFactor: .76,
                            child: Image.asset(asset,
                                width: 144,
                                height: 108,
                                fit: BoxFit.contain,
                                cacheWidth: 390,
                                excludeFromSemantics: true)))),
          ),
        ),
        const SizedBox(height: 2),
        Text(widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
