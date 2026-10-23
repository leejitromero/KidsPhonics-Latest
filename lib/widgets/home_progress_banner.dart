import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/updated_scene.dart';

abstract final class HomeBannerArt {
  static const logo = 'assets/images/home_banner/logo.png';
  static const panel = 'assets/images/home_banner/panel.png';
  static const trophy = 'assets/images/home_banner/trophy.png';
  static const xp = 'assets/images/home_banner/xp.png';
  static const star = 'assets/images/home_banner/star.png';
  static const fire = 'assets/images/home_banner/fire.png';
  static const flower = 'assets/images/home_banner/flower.png';
  static const assets = [logo, panel, trophy, xp, star, fire, flower];
  static String portrait(String character) => '$sceneAssets/${character}_1.png';
}

/// Logo and panel keep their own original proportions on every viewport.
class HomeBannerGeometry {
  const HomeBannerGeometry(this.logo, this.panel);
  final Rect logo, panel;

  static HomeBannerGeometry layout(Size scene, EdgeInsets insets,
      {required double characterTop, double logoWidthFraction = .62}) {
    final top = insets.top + 4;
    final side = math.max(12.0, math.max(insets.left, insets.right));
    final panelWidth = math.min(720.0, math.max(1.0, scene.width - side * 2));
    final logoWidth = math.min(540.0, scene.width * logoWidthFraction);
    final logoHeight = logoWidth * 585 / 1350;
    final panelHeight = panelWidth * 333 / 1235;
    final available = math.max(1.0, characterTop - 28 - top);
    final scale = math.min(1.0, available / (logoHeight + panelHeight - 6));
    final logo = Rect.fromLTWH((scene.width - logoWidth * scale) / 2, top,
        logoWidth * scale, logoHeight * scale);
    final panel = Rect.fromLTWH((scene.width - panelWidth * scale) / 2,
        logo.bottom - 6 * scale, panelWidth * scale, panelHeight * scale);
    return HomeBannerGeometry(logo, panel);
  }
}

/// Presentation only: progress, mastery, rewards and saves remain in AppProvider.
class HomeProgressBanner extends StatelessWidget {
  const HomeProgressBanner(
      {super.key,
      required this.geometry,
      required this.character,
      required this.name,
      required this.letter,
      required this.level,
      required this.xp,
      required this.stars,
      required this.streak,
      required this.onProfile,
      this.showProfile = true});
  final HomeBannerGeometry geometry;
  final String character, name;
  final String? letter;
  final int level, xp, stars, streak;
  final VoidCallback? onProfile;
  final bool showProfile;

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fromRect(
            rect: geometry.logo,
            child: IgnorePointer(
                child: Semantics(
                    key: const ValueKey('home-logo-art'),
                    label: 'KidsPhonics',
                    image: true,
                    child: Image.asset(HomeBannerArt.logo,
                        fit: BoxFit.contain,
                        cacheWidth: 1350,
                        excludeFromSemantics: true)))),
        Positioned.fromRect(
            rect: geometry.panel,
            child: Semantics(
                container: true,
                liveRegion: true,
                child: LayoutBuilder(builder: (context, box) {
                  final scale = box.maxWidth / 1235;
                  Widget at(double x, double y, double w, double h,
                          Widget child) =>
                      Positioned(
                          left: x * scale,
                          top: y * scale,
                          width: w * scale,
                          height: h * scale,
                          child: child);
                  return Stack(
                      key: const ValueKey('home-progress-banner'),
                      fit: StackFit.expand,
                      children: [
                        Image.asset(HomeBannerArt.panel,
                            fit: BoxFit.contain,
                            cacheWidth: 1235,
                            excludeFromSemantics: true),
                        at(
                            62,
                            82,
                            824,
                            195,
                            Column(children: [
                              Expanded(
                                  flex: 10,
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text.rich(
                                          key: const ValueKey(
                                              'home-banner-recommendation'),
                                          TextSpan(children: [
                                            const TextSpan(
                                                text:
                                                    'Your next little step: '),
                                            TextSpan(
                                                text: letter == null
                                                    ? 'Review letters'
                                                    : 'Letter $letter',
                                                style: const TextStyle(
                                                    color: Color(0xFF9B4106))),
                                          ]),
                                          maxLines: 1,
                                          style: const TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 51,
                                              height: 1.15,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF59210D))))),
                              Expanded(
                                  flex: 10,
                                  child: Row(children: [
                                    Expanded(
                                        child: _BannerMetric(
                                            icon: HomeBannerArt.trophy,
                                            label: 'Level $level',
                                            valueKey: 'home-banner-level')),
                                    Expanded(
                                        child: _BannerMetric(
                                            icon: HomeBannerArt.xp,
                                            label: '$xp XP',
                                            valueKey: 'home-banner-xp')),
                                    Expanded(
                                        child: _BannerMetric(
                                            icon: HomeBannerArt.star,
                                            label: '$stars Stars',
                                            valueKey: 'home-banner-stars')),
                                  ])),
                              Expanded(
                                  flex: 9,
                                  child: _BannerMetric(
                                      icon: HomeBannerArt.fire,
                                      label: '$streak Day Streak',
                                      valueKey: 'home-banner-streak')),
                            ])),
                        if (showProfile) ...[
                          at(
                              976,
                              103,
                              171,
                              127,
                              ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(23 * scale),
                                  child: Image.asset(
                                      HomeBannerArt.portrait(character),
                                      key: const ValueKey('home-banner-avatar'),
                                      cacheWidth: 256,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      gaplessPlayback: true,
                                      semanticLabel:
                                          'Selected $character character'))),
                          at(
                              963,
                              239,
                              142,
                              37,
                              FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: SizedBox(
                                      width: 142,
                                      child: Text(
                                          name.isEmpty
                                              ? 'Choose profile'
                                              : name,
                                          key: const ValueKey(
                                              'home-banner-name'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 34,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF59210D)))))),
                          at(
                              965,
                              277,
                              142,
                              25,
                              _BannerMetric(
                                  icon: HomeBannerArt.flower,
                                  label: 'Level $level',
                                  valueKey: 'home-banner-profile-level')),
                        ],
                        at(
                            932,
                            70,
                            262,
                            247,
                            Semantics(
                                button: true,
                                label: 'Change character profile',
                                enabled: onProfile != null,
                                child: GestureDetector(
                                    key: const ValueKey('home-banner-profile'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: onProfile))),
                      ]);
                }))),
      ]);
}

class _BannerMetric extends StatelessWidget {
  const _BannerMetric(
      {required this.icon, required this.label, required this.valueKey});
  final String icon, label, valueKey;

  @override
  Widget build(BuildContext context) => Semantics(
      label: label,
      excludeSemantics: true,
      child: Padding(
          padding: const EdgeInsets.all(1),
          child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset(icon,
                    width: 45,
                    height: 46,
                    fit: BoxFit.contain,
                    cacheWidth: 156,
                    excludeFromSemantics: true),
                const SizedBox(width: 8),
                Text(label,
                    key: ValueKey(valueKey),
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 36,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF59210D))),
              ]))));
}
