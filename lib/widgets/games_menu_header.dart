import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/updated_scene.dart';
import 'kids_navigation_bar.dart';
import 'lesson_menu_card.dart';

class GamesMenuHeader extends StatelessWidget {
  const GamesMenuHeader(
      {super.key,
      required this.character,
      required this.onBack,
      this.compact = false,
      required this.onEdit});
  final String character;
  final bool compact;
  final VoidCallback? onBack, onEdit;

  static double heightFor(BuildContext context, double width) {
    final profile = (width * .18).clamp(56.0, 80.0);
    final banner = math.min(400.0, width - 2 * (profile + 6)) / 3;
    final text = TextPainter(
        text: const TextSpan(
            text: 'Play and learn with fun games!',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                height: 1.15,
                fontWeight: FontWeight.w900)),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context))
      ..layout(maxWidth: width - 20);
    final height = math.max(profile, banner) + text.height + 14;
    text.dispose();
    return height;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final profile = compact ? 52.0 : (box.maxWidth * .18).clamp(56.0, 80.0);
        final bannerWidth =
            math.min(compact ? 280.0 : 400.0, box.maxWidth - 2 * (profile + 6));
        final bannerHeight = compact ? 52.0 : bannerWidth / 3;
        return Column(children: [
          SizedBox(
              height: math.max(profile, bannerHeight),
              child: Stack(children: [
                Align(
                    alignment: Alignment.center,
                    child: Semantics(
                        key: const ValueKey('games-banner'),
                        label: 'Games',
                        image: true,
                        child: SizedBox(
                            width: bannerWidth,
                            height: bannerHeight,
                            child: Stack(fit: StackFit.expand, children: [
                              Image.asset(KidsNavigationArt.base,
                                  fit: BoxFit.contain,
                                  cacheWidth: 900,
                                  excludeFromSemantics: true),
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Row(children: [
                                    for (final letter in 'games'.split(''))
                                      Expanded(
                                          child: Image.asset(
                                              'assets/images/letters/$letter.webp',
                                              fit: BoxFit.contain,
                                              cacheWidth: 120,
                                              excludeFromSemantics: true)),
                                  ])),
                            ])))),
                Align(
                    alignment: Alignment.topLeft,
                    child: Tooltip(
                        message: 'Back',
                        child: Semantics(
                            label: 'Back',
                            child: LessonMenuPress(
                                key: const ValueKey('games-back'),
                                onTap: onBack,
                                radius: 28,
                                child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: const Color(0xFFAC5C15),
                                            width: 2),
                                        gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFFFFF4A5),
                                              Color(0xFFFFBD38),
                                              Color(0xFFE88C20)
                                            ]),
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Color(0x554E281D),
                                              offset: Offset(0, 3),
                                              blurRadius: 4)
                                        ]),
                                    child: const Icon(Icons.arrow_back_rounded,
                                        color: Color(0xFF007BDD),
                                        size: 36)))))),
                Align(alignment: Alignment.topRight, child: _profile(profile)),
              ])),
          Container(
              key: const ValueKey('games-subtitle'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDD8D35), width: 2),
                  gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFF9E8), Color(0xFFFFDC9F)])),
              child: const Text('Play and learn with fun games!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF57230B)))),
        ]);
      });
  Widget _profile(double size) => Semantics(
      label: 'Edit learner profile',
      child: LessonMenuPress(
          key: const ValueKey('games-edit-profile'),
          onTap: onEdit,
          child: SizedBox(
              key: const ValueKey('games-profile'),
              width: size,
              height: size,
              child: Stack(children: [
                Positioned.fill(
                    child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFF60B8),
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(17),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x5541246C),
                                  blurRadius: 5,
                                  offset: Offset(0, 3))
                            ]),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ColoredBox(
                                color: const Color(0xFFFFF3D9),
                                child: Image.asset(
                                    '$sceneAssets/${character}_1.png',
                                    key: ValueKey('games-profile-$character'),
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    cacheWidth: 256,
                                    excludeFromSemantics: true))))),
                Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF963BF4),
                            border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.edit_rounded,
                            size: 17, color: Colors.white))),
              ]))));
}
