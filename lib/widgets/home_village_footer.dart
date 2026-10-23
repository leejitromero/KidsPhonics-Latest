import 'package:flutter/material.dart';
import '../data/home_village.dart';
import 'button_sound.dart';

const _ink = Color(0xFF392650);

/// Compact live Home summary. Shared Progress/Parents recommendations stay intact.
class HomeVillageFooter extends StatelessWidget {
  const HomeVillageFooter(
      {super.key,
      required this.letter,
      required this.review,
      required this.score,
      required this.level,
      required this.stars,
      required this.xp,
      required this.onContinue});
  final String? letter;
  final bool review;
  final int score, level, stars, xp;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) => Padding(
      key: const ValueKey('home-footer'),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: _raisedPanel(const Color(0xFFFFF5E8)),
            child: Row(children: [
              _LetterToken(letter: letter),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    const Text('Continue Learning',
                        style: TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                        letter == null
                            ? 'Alphabet Master!'
                            : '${review ? 'Review' : 'Practice'} Letter $letter',
                        style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 20,
                            color: Color(0xFF5F2A8E))),
                    const SizedBox(height: 3),
                    Text(
                        letter == null
                            ? 'Keep your magic growing!'
                            : review
                                ? 'Try your next Quick Check!'
                                : 'Ready for a little challenge?',
                        style: const TextStyle(
                            color: Color(0xFF665C7F),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                    if (review) ...[
                      const SizedBox(height: 5),
                      Row(children: [
                        Expanded(
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                    value: score / 5,
                                    minHeight: 6,
                                    color: const Color(0xFF67BA63),
                                    backgroundColor: const Color(0xFFDFD2E7)))),
                        const SizedBox(width: 7),
                        Text('$score / 5',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: _ink)),
                      ]),
                    ]
                  ])),
              const SizedBox(width: 8),
              _ContinueButton(onPressed: onContinue),
            ])),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, box) {
          final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
          final badges = [
            (
              Icons.workspace_premium_rounded,
              'Level $level',
              const Color(0xFFB0741D)
            ),
            (Icons.star_rounded, '$stars Stars', const Color(0xFFB97917)),
            (Icons.hexagon_rounded, '$xp XP', const Color(0xFF2582C6)),
          ];
          return Wrap(spacing: 7, runSpacing: 7, children: [
            for (final badge in badges)
              SizedBox(
                  width: largeText ? box.maxWidth : (box.maxWidth - 14) / 3,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      decoration: _raisedPanel(
                          Color.lerp(Colors.white, badge.$3, .08)!),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ToyIcon(icon: badge.$1, color: badge.$3, size: 23),
                            const SizedBox(width: 5),
                            Flexible(
                                child: Text(badge.$2,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: badge.$3,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12))),
                          ]))),
          ]);
        }),
      ]));
}

BoxDecoration _raisedPanel(Color tint) => BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              tint,
              Color.lerp(tint, const Color(0xFFE3C8B3), .28)!
            ]),
        border: Border.all(color: const Color(0xFFF3C487), width: 2.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0xFFBE8B56), offset: Offset(0, 3), blurRadius: 0),
          BoxShadow(
              color: Color(0x33442C4A), offset: Offset(0, 6), blurRadius: 10),
        ]);

class _LetterToken extends StatelessWidget {
  const _LetterToken({required this.letter});
  final String? letter;
  @override
  Widget build(BuildContext context) => Container(
      width: 46,
      height: 57,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF6C4),
                Color(0xFFFFDC73),
                Color(0xFFF2A139)
              ]),
          border: Border.all(color: const Color(0xFFFFEAAF), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0xFFC78632), offset: Offset(2, 3), blurRadius: 0),
            BoxShadow(
                color: Color(0x22482951), offset: Offset(0, 5), blurRadius: 5)
          ]),
      child: letter == null
          ? const Icon(Icons.auto_awesome_rounded,
              color: Color(0xFF8A499F), size: 30)
          : Text(letter!,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 40,
                  color: Color(0xFF7D389F),
                  shadows: [
                    Shadow(color: Color(0xFFFFFBDA), offset: Offset(0, -1)),
                    Shadow(color: Color(0xFFBD7638), offset: Offset(1, 2))
                  ])));
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onPressed});
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF9AADFF),
                Color(0xFF6264E9),
                Color(0xFF4544C5)
              ]),
          border: Border.all(color: const Color(0xFFCCD6FF), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0xFF35338C), offset: Offset(0, 3)),
            BoxShadow(
                color: Color(0x33515494), offset: Offset(0, 5), blurRadius: 5)
          ]),
      child: IconButton(
          key: const ValueKey('home-start-adventure'),
          tooltip: 'Start Quick Check',
          onPressed: withButtonSound(onPressed),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: 30)));
}

class _ToyIcon extends StatelessWidget {
  const _ToyIcon({required this.icon, required this.color, required this.size});
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Stack(children: [
        Transform.translate(
            offset: const Offset(0, 1.5),
            child: Icon(icon,
                color: Color.lerp(color, Colors.black, .22), size: size)),
        Icon(icon, color: color, size: size),
      ]);
}

/// Home owns this bar; destinations keep the app's existing navigation.
class HomeVillageNavigation extends StatelessWidget {
  const HomeVillageNavigation(
      {super.key,
      required this.onSelect,
      required this.gameAccess,
      this.busy = false});
  final ValueChanged<HomeCategory> onSelect;
  final bool gameAccess, busy;

  @override
  Widget build(BuildContext context) => Container(
      key: const ValueKey('home-bottom-navigation'),
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFCF0), Color(0xFFF0E4D7)]),
          border: Border(top: BorderSide(color: Color(0xFFFFE1A5), width: 2)),
          boxShadow: [
            BoxShadow(
                color: Color(0x224B3350), offset: Offset(0, -3), blurRadius: 12)
          ]),
      child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(5, 5, 5, 6),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: LayoutBuilder(builder: (context, box) {
                final height = (box.maxWidth / 5 * .95).clamp(58.0, 82.0);
                return Row(children: [
                  _NavigationItem(
                      id: 'home',
                      title: 'Home',
                      height: height,
                      active: true,
                      locked: false,
                      onTap: busy ? null : () {}),
                  for (final category in HomeCategory.values)
                    _NavigationItem(
                        id: category.name,
                        title: category.title,
                        height: height,
                        active: false,
                        locked: category == HomeCategory.games && !gameAccess,
                        onTap: busy ||
                                (category == HomeCategory.games && !gameAccess)
                            ? null
                            : () => onSelect(category)),
                ]);
              }),
            ),
          )));
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem(
      {required this.id,
      required this.title,
      required this.height,
      required this.active,
      required this.locked,
      required this.onTap});
  final String id, title;
  final double height;
  final bool active, locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
      child: Semantics(
          selected: active,
          button: true,
          enabled: onTap != null,
          label: locked ? '$title, turned off by a parent' : title,
          child: Tooltip(
            message: locked ? 'Games are turned off by a parent.' : title,
            excludeFromSemantics: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                  key: ValueKey('home-nav-$id'),
                  onTap: withButtonSound(onTap),
                  borderRadius: BorderRadius.circular(14),
                  child: ExcludeSemantics(
                    child: SizedBox(
                      height: height,
                      child: Stack(fit: StackFit.expand, children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 1, 2, 6),
                          child: Opacity(
                            opacity: locked ? .45 : 1,
                            child: Image.asset(homeNavigationArt[id]!,
                                key: ValueKey('home-nav-$id-art'),
                                fit: BoxFit.contain,
                                excludeFromSemantics: true,
                                cacheWidth: 240),
                          ),
                        ),
                        if (active)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 18,
                              height: 3,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF7946BB),
                                  borderRadius: BorderRadius.circular(3)),
                            ),
                          ),
                        if (locked)
                          const Positioned(
                              right: 3,
                              top: 3,
                              child: Icon(Icons.lock_rounded,
                                  color: Color(0xFF62467B), size: 16)),
                      ]),
                    ),
                  )),
            ),
          )));
}
