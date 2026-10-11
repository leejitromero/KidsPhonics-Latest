import 'package:flutter/material.dart';
import 'mascot_guide.dart';

const parentInk = Color(0xFF073D2E);
const parentMuted = Color(0xFF486B63);
const parentGold = Color(0xFFFFC900);

ThemeData get parentPanelTheme => ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(
              seedColor: parentInk, brightness: Brightness.light)
          .copyWith(
              primary: parentInk,
              secondary: parentGold,
              surface: const Color(0xFFFFFEF5)),
      textTheme: const TextTheme(
          bodyMedium: TextStyle(color: parentMuted, fontSize: 14),
          bodyLarge: TextStyle(color: parentInk, fontSize: 15)),
      switchTheme: SwitchThemeData(
          thumbColor: const WidgetStatePropertyAll(Colors.white),
          trackColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? parentGold
                  : const Color(0xFF91958F)),
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
          thumbIcon: const WidgetStatePropertyAll(
              Icon(Icons.circle, color: Colors.white))),
      sliderTheme: const SliderThemeData(
          activeTrackColor: parentGold,
          thumbColor: parentGold,
          inactiveTrackColor: Color(0xFFE4EADA),
          overlayColor: Color(0x33FFCA00),
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 11),
          trackHeight: 6),
      dividerTheme: const DividerThemeData(color: Color(0xFFDCEADB)),
    );

class ParentPanelHeader extends StatelessWidget {
  const ParentPanelHeader({super.key, required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => SafeArea(
      bottom: false,
      child: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
                  child: LayoutBuilder(builder: (context, box) {
                    final largeText =
                        MediaQuery.textScalerOf(context).scale(16) > 23;
                    return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton.filled(
                              tooltip: 'Back',
                              onPressed: onBack,
                              style: IconButton.styleFrom(
                                  backgroundColor:
                                      parentInk.withValues(alpha: .9),
                                  foregroundColor: Colors.white,
                                  fixedSize: const Size(48, 48)),
                              icon: const Icon(Icons.arrow_back_rounded)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Parent Panel',
                                    style: TextStyle(
                                        fontSize: box.maxWidth < 350 ? 22 : 24,
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w900,
                                        color: parentInk,
                                        height: 1.1)),
                                const SizedBox(height: 3),
                                const Text(
                                    'Support your child’s learning journey.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: parentMuted,
                                        height: 1.3)),
                              ])),
                          if (!largeText) ...[
                            const SizedBox(width: 4),
                            MascotPortrait(
                                mascot: LearningMascot.jitjit,
                                size: box.maxWidth < 350 ? 50 : 58),
                          ],
                        ]);
                  })))));
}

class ParentTabButton extends StatelessWidget {
  const ParentTabButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.selected,
      required this.onPressed});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
      selected: selected,
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: selected
                      ? [const Color(0xFFEFFFAB), const Color(0xFFF9FFE9)]
                      : [const Color(0xFF32664A), const Color(0xFF194534)]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: selected ? Colors.white : const Color(0xFF98BA83),
                  width: selected ? 2 : 1),
              boxShadow: [
                BoxShadow(
                    color: selected
                        ? const Color(0x668FC34B)
                        : const Color(0x332D5A28),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ]),
          child: TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                  foregroundColor: selected ? parentInk : Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18))),
              child: Column(children: [
                Icon(icon, size: 20),
                const SizedBox(height: 2),
                FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label,
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w900)))
              ]))));
}

/// Light garden surfaces keep settings readable over the illustrated forest.
class ParentSectionCard extends StatelessWidget {
  const ParentSectionCard(
      {super.key,
      required this.title,
      required this.description,
      required this.icon,
      required this.child,
      this.accent = const Color(0xFFC8EE9E)});
  final String title, description;
  final IconData icon;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFEF5), Color(0xFFF7F9EA)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7F5BA), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x303D681E), blurRadius: 12, offset: Offset(0, 5))
          ]),
      child: Stack(children: [
        const Positioned(left: 0, top: 24, child: _Leaves()),
        const Positioned(right: 0, top: 45, child: _Leaves()),
        const Positioned(
            left: 0,
            bottom: 0,
            child: RotatedBox(quarterTurns: 2, child: _Leaves())),
        Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    ParentIconBadge(icon: icon, color: accent, size: 38),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              style: const TextStyle(
                                  color: parentInk,
                                  fontSize: 18,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w900,
                                  height: 1.15)),
                          const SizedBox(height: 3),
                          Text(description,
                              style: const TextStyle(
                                  color: parentMuted,
                                  fontSize: 12,
                                  height: 1.25)),
                        ])),
                  ]),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 7),
                      child: Divider(height: 1, color: Color(0xFFDCEADB))),
                  DefaultTextStyle.merge(
                      style: const TextStyle(
                          color: parentMuted,
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          height: 1.25),
                      child: child),
                ])),
      ]));
}

class ParentIconBadge extends StatelessWidget {
  const ParentIconBadge(
      {super.key,
      required this.icon,
      this.size = 34,
      this.color = const Color(0xFFCDF3AD),
      this.ink = parentInk});
  final IconData icon;
  final double size;
  final Color color, ink;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(Colors.white, color, .55)!, color]),
              border: Border.all(
                  color: Colors.white.withValues(alpha: .8), width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: .35), spreadRadius: 2)
              ]),
          child: Icon(icon, color: ink, size: size * .52)));
}

class ParentSettingToggle extends StatelessWidget {
  const ParentSettingToggle(
      {super.key,
      required this.title,
      required this.icon,
      required this.value,
      required this.onChanged,
      this.subtitle,
      this.color = const Color(0xFFCDF3AD),
      this.ink = parentInk});
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color, ink;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
          color: const Color(0xCCFFFFFF),
          borderRadius: BorderRadius.circular(20),
          child: SwitchListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFF0F4E7))),
              tileColor: const Color(0xCCFFFFFF),
              secondary: ParentIconBadge(icon: icon, color: color, ink: ink),
              title: Text(title,
                  style: const TextStyle(
                      color: parentInk,
                      fontSize: 15,
                      fontWeight: FontWeight.w900)),
              subtitle: subtitle == null
                  ? null
                  : Text(subtitle!,
                      style: const TextStyle(color: parentMuted, fontSize: 12)),
              value: value,
              onChanged: onChanged)));
}

class ParentActionRow extends StatelessWidget {
  const ParentActionRow(
      {super.key,
      required this.title,
      required this.icon,
      required this.onTap,
      this.highlight = false});
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool highlight;
  @override
  Widget build(BuildContext context) => Material(
      color: highlight ? const Color(0xFFEEF8DA) : const Color(0xFFFFFEF5),
      borderRadius: BorderRadius.circular(20),
      child: ListTile(
          dense: true,
          minTileHeight: 48,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          leading: ParentIconBadge(icon: icon),
          title: Text(title,
              style: const TextStyle(
                  color: parentInk, fontSize: 16, fontWeight: FontWeight.w900)),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: parentMuted, size: 24),
          onTap: onTap));
}

class _Leaves extends StatelessWidget {
  const _Leaves();
  @override
  Widget build(BuildContext context) => const IgnorePointer(
      child: ExcludeSemantics(
          child: CustomPaint(size: Size(38, 45), painter: _LeafPainter())));
}

class _LeafPainter extends CustomPainter {
  const _LeafPainter();
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final tip = Offset(7 + i * 12, i == 1 ? 0 : 14);
      final base = Offset(size.width, size.height);
      final path = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(tip.dx - 8, tip.dy + 8, tip.dx, tip.dy)
        ..quadraticBezierTo(tip.dx + 18, tip.dy, base.dx, base.dy);
      canvas.drawPath(
          path,
          Paint()
            ..shader = const LinearGradient(
                    colors: [Color(0xFF9CCC4B), Color(0xFF398C59)])
                .createShader(Offset.zero & size));
      canvas.drawLine(
          tip + const Offset(2, 7),
          base,
          Paint()
            ..color = const Color(0x6641682A)
            ..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(_LeafPainter oldDelegate) => false;
}
