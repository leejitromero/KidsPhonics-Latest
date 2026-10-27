import 'package:flutter/material.dart';
import 'button_sound.dart';

/// Original supplied artwork, with its transparent outer margin excluded from
/// layout. The PNG bytes and the rounded outline remain unchanged.
class _FeedbackArt extends StatelessWidget {
  const _FeedbackArt({required this.asset, required this.source});
  final String asset;
  final Rect source;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final scaleX = box.maxWidth / source.width;
        final scaleY = box.maxHeight / source.height;
        return ClipRect(
            child: Stack(children: [
          Positioned(
              left: -source.left * scaleX,
              top: -source.top * scaleY,
              width: 2172 * scaleX,
              height: 724 * scaleY,
              child: Image.asset(asset,
                  fit: BoxFit.fill,
                  cacheWidth: 1086,
                  excludeFromSemantics: true)),
        ]));
      });
}

/// Readable success feedback shared by the games that previously used plain text.
class GameCorrectFrame extends StatelessWidget {
  const GameCorrectFrame({super.key, this.height = 44, this.detail});
  static const asset = 'assets/images/new_ui/correct_frame.png';
  final double height;
  final String? detail;

  @override
  Widget build(BuildContext context) => Semantics(
      liveRegion: true,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
            child: SizedBox(
                width: height * 4.5,
                height: height,
                child: Stack(fit: StackFit.expand, children: [
                  const _FeedbackArt(
                      asset: asset, source: Rect.fromLTRB(160, 102, 2016, 630)),
                  Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: height * .3, vertical: height * .12),
                      child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check_circle_rounded,
                                color: Color(0xFF17500B), size: 24),
                            SizedBox(width: 7),
                            Text('Correct!',
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF174908))),
                          ]))),
                ]))),
        if (detail != null)
          Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF3),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(detail!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF174908), fontWeight: FontWeight.w700))),
      ]));
}

/// The supplied Next artwork is used only by Missing Vowel.
class MissingVowelNextButton extends StatelessWidget {
  const MissingVowelNextButton({super.key, required this.onPressed});
  static const asset = 'assets/images/new_ui/missing_vowel_next.png';
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Center(
      child: SizedBox(
          width: 186,
          height: 60,
          child: ElevatedButton(
              key: const ValueKey('missing-vowel-next'),
              onPressed: withButtonSound(onPressed),
              style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: const StadiumBorder()),
              child: const Stack(fit: StackFit.expand, children: [
                _FeedbackArt(
                    asset: asset, source: Rect.fromLTRB(128, 40, 2036, 668)),
                // The artwork already contains the visible label. Retain a
                // single live label for accessibility and button interaction.
                Center(
                    child: Opacity(
                        opacity: 0,
                        alwaysIncludeSemantics: true,
                        child: Text('Next', style: TextStyle(fontSize: 24)))),
              ]))));
}
