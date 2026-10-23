import 'package:flutter/material.dart';

const settingsInk = Color(0xFF370878);
const settingsPurple = Color(0xFF8426E9);

/// Surfaces used only by Settings; the room and navigation remain unchanged.
class SettingsReferenceCard extends StatelessWidget {
  const SettingsReferenceCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF40BDF0),
                Color(0xFFB8F8FF),
                Color(0xFF29BCE6)
              ]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x40406687), blurRadius: 8, offset: Offset(0, 4)),
            BoxShadow(color: Color(0x66FFE89B), offset: Offset(0, 2)),
          ]),
      child: Material(
          color: const Color(0xFFFFFCF5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Colors.white, width: 1.5)),
          clipBehavior: Clip.antiAlias,
          child: Ink(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFFFFCF4), Colors.white])),
              child: child)));
}

class SettingsReferenceIcon extends StatelessWidget {
  const SettingsReferenceIcon({super.key, this.icon, this.child});
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final side = MediaQuery.sizeOf(context).width < 360 ? 48.0 : 62.0;
    final star = icon == Icons.auto_awesome_rounded;
    return ExcludeSemantics(
        child: SizedBox.square(
            dimension: side,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(19),
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: child == null
                                  ? const [
                                      Color(0xFFF6E7FF),
                                      Color(0xFFECE2FF),
                                      Color(0xFFE0F7FF)
                                    ]
                                  : const [
                                      Color(0xFFFFE7F3),
                                      Colors.white,
                                      Color(0xFFD1F4FF)
                                    ])))),
              Positioned.fill(
                  child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: child ??
                          ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) => LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: star
                                          ? const [
                                              Color(0xFFFFF389),
                                              Color(0xFFFFCA24),
                                              Color(0xFFFF970D)
                                            ]
                                          : const [
                                              Color(0xFFD68DFF),
                                              Color(0xFF9425F1),
                                              Color(0xFF5100AA)
                                            ])
                                  .createShader(bounds),
                              child: Icon(star ? Icons.star_rounded : icon,
                                  size: side * .72,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                        color: Color(0xFF6E18B7),
                                        offset: Offset(0, 2),
                                        blurRadius: 2)
                                  ])))),
              const Positioned(
                  left: -2,
                  bottom: -2,
                  child: SizedBox(
                      width: 22,
                      height: 25,
                      child: CustomPaint(painter: _BlueSprig()))),
              if (icon == Icons.volume_up_rounded)
                const Positioned(
                    right: -1,
                    top: -2,
                    child: Icon(Icons.music_note_rounded,
                        size: 20, color: Color(0xFF02B6EF))),
              if (star || child != null)
                Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(Icons.star_rounded,
                        size: 12,
                        color:
                            star ? settingsPurple : const Color(0xFF04B9F2))),
            ])));
  }
}

class SettingsReferenceArrow extends StatelessWidget {
  const SettingsReferenceArrow({super.key, this.edit = false});
  final bool edit;
  @override
  Widget build(BuildContext context) => ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD88EFF), Color(0xFF9A2BFA), Color(0xFF620DC1)])
          .createShader(bounds),
      child: Icon(edit ? Icons.edit_rounded : Icons.chevron_right_rounded,
          color: Colors.white, size: 32));
}

class SettingsReferenceHeader extends StatelessWidget {
  const SettingsReferenceHeader({super.key, required this.onBack});
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
          color: settingsInk,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
                color: Color(0x555B391B), blurRadius: 7, offset: Offset(0, 4))
          ]),
      child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(colors: [
                Color(0xFF2ABCF1),
                Color(0xFF87F5FF),
                Color(0xFF21AFDB)
              ])),
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: const Color(0xFFFFDA70), width: 3),
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFF4AF),
                        Color(0xFFFFFDE9),
                        Color(0xFFFFE8A6)
                      ]),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.white, blurRadius: 2, spreadRadius: -1)
                  ]),
              child: Stack(children: [
                const Positioned(
                    right: 0,
                    top: 0,
                    child: ExcludeSemantics(
                        child: Icon(Icons.star_rounded,
                            color: Color(0xFFFFBC20),
                            size: 34,
                            shadows: [
                          Shadow(
                              color: Color(0xFFFF9514),
                              offset: Offset(0, 2),
                              blurRadius: 2)
                        ]))),
                Row(children: [
                  Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF6020AE), width: 2),
                          gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFD68AFF),
                                Color(0xFF962CF3),
                                Color(0xFF6812C7)
                              ]),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x77764194),
                                offset: Offset(0, 3),
                                blurRadius: 3)
                          ]),
                      child: IconButton(
                          key: const ValueKey('settings-back'),
                          tooltip: 'Back to Home',
                          onPressed: onBack,
                          iconSize: 32,
                          color: Colors.white,
                          padding: const EdgeInsets.all(10),
                          icon: const Icon(Icons.arrow_back_rounded))),
                  const SizedBox(width: 12),
                  const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Padding(
                            padding: EdgeInsets.only(right: 30),
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text('Settings',
                                    style: TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 40,
                                        height: 1.1,
                                        color: settingsInk)))),
                        SizedBox(height: 5),
                        Text('Make your adventure feel right.',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF663018))),
                      ])),
                ]),
              ]))));
}

class _BlueSprig extends CustomPainter {
  const _BlueSprig();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 22, size.height / 25);
    final paint = Paint()
      ..shader = const LinearGradient(
              colors: [Color(0xFF7AF7FF), Color(0xFF08B5F1), Color(0xFF027AD5)])
          .createShader(const Rect.fromLTWH(0, 0, 22, 25));
    canvas.drawPath(
        Path()
          ..moveTo(12, 23)
          ..quadraticBezierTo(-1, 21, 2, 4)
          ..quadraticBezierTo(15, 9, 12, 23)
          ..close(),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(13, 24)
          ..quadraticBezierTo(11, 12, 22, 12)
          ..quadraticBezierTo(22, 23, 13, 24)
          ..close(),
        paint);
    canvas.drawLine(
        const Offset(5, 9),
        const Offset(13, 24),
        Paint()
          ..color = const Color(0xFF007BCA)
          ..strokeWidth = .7);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BlueSprig oldDelegate) => false;
}
