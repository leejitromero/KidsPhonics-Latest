import 'package:flutter/material.dart';

const settingsSoundInk = Color(0xFF123E91);
const settingsSoundMuted = Color(0xFF526DA8);
const settingsSoundBlue = Color(0xFF3577FF);

/// Local audio-section styling; native switches and slider retain their behavior.
class SettingsSoundPanel extends StatelessWidget {
  const SettingsSoundPanel({super.key, required this.child});
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
              colors: [Color(0xFF65CEFF), Color(0xFFE0FAFF), Color(0xFF75C6FF)]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x444D78AB), blurRadius: 8, offset: Offset(0, 4))
          ]),
      child: Material(
          color: const Color(0xFFFCFEFF),
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Theme(
              data: Theme.of(context).copyWith(
                  listTileTheme: const ListTileThemeData(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      horizontalTitleGap: 10,
                      minLeadingWidth: 46,
                      titleTextStyle:
                          TextStyle(fontFamily: 'Nunito', fontSize: 16, height: 1.15, fontWeight: FontWeight.w900, color: settingsSoundInk),
                      subtitleTextStyle: TextStyle(fontFamily: 'Nunito', fontSize: 14, height: 1.2, fontWeight: FontWeight.w600, color: settingsSoundMuted)),
                  expansionTileTheme: const ExpansionTileThemeData(tilePadding: EdgeInsets.symmetric(horizontal: 10, vertical: 3), childrenPadding: EdgeInsets.fromLTRB(8, 0, 8, 8), collapsedTextColor: settingsSoundInk, textColor: settingsSoundInk, iconColor: Color(0xFF6353FF), collapsedIconColor: Color(0xFF6353FF), shape: Border(), collapsedShape: Border()),
                  switchTheme: SwitchThemeData(trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent), trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? settingsSoundBlue : const Color(0xFFD3DEF1)), thumbColor: const WidgetStatePropertyAll(Colors.white), overlayColor: const WidgetStatePropertyAll(Color(0x223577FF))),
                  sliderTheme: SliderTheme.of(context).copyWith(activeTrackColor: settingsSoundBlue, inactiveTrackColor: const Color(0xFFC7DCF9), disabledActiveTrackColor: const Color(0xFFB4C7E4), disabledInactiveTrackColor: const Color(0xFFD9E6F6), disabledThumbColor: const Color(0xFF9DB9E2), thumbColor: settingsSoundBlue, overlayColor: const Color(0x253577FF), activeTickMarkColor: const Color(0xFF73BCFF), inactiveTickMarkColor: const Color(0xFF9EBEEA), trackHeight: 9, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10), overlayShape: const RoundSliderOverlayShape(overlayRadius: 18))),
              child: Ink(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE3F3FF), Colors.white, Color(0xFFF2F9FF)], stops: [0, .2, 1])), child: child))));
}

class SettingsSoundIcon extends StatelessWidget {
  const SettingsSoundIcon(this.icon, {super.key});
  final IconData icon;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: SizedBox.square(
          dimension: 48,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFBEEBFF), Color(0xFFF5FDFF)])))),
            Center(
                child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: icon == Icons.library_music_rounded
                                ? const [Color(0xFFAF7DFF), Color(0xFF5733EC)]
                                : const [
                                    Color(0xFF48CFFF),
                                    Color(0xFF0871E9),
                                    Color(0xFF234CBD)
                                  ])
                        .createShader(bounds),
                    child: Icon(icon,
                        size: 36,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                              color: Color(0x55456CAC),
                              offset: Offset(0, 2),
                              blurRadius: 1)
                        ]))),
            const Positioned(
                left: 1,
                bottom: 1,
                child: Icon(Icons.eco_rounded,
                    size: 14, color: Color(0xFF69BB32))),
            Positioned(
                right: -1,
                top: 1,
                child: Icon(
                    icon == Icons.face_rounded
                        ? Icons.volume_up_rounded
                        : Icons.auto_awesome_rounded,
                    size: 15,
                    color: icon == Icons.face_rounded
                        ? settingsSoundBlue
                        : const Color(0xFFFFBD2E))),
          ])));
}

class SettingsSoundDivider extends StatelessWidget {
  const SettingsSoundDivider({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.only(left: 66, right: 8),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFEDF2FA)));
}

class SettingsVolumePanel extends StatelessWidget {
  const SettingsVolumePanel(
      {super.key, required this.label, required this.slider});
  final String label;
  final Widget slider;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
              colors: [Color(0xFFDDF2FF), Color(0xFFE4F1FF)])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: settingsSoundInk)),
        Row(children: [
          const ExcludeSemantics(
              child: Icon(Icons.volume_down_rounded,
                  color: Color(0xFF6260FF), size: 23)),
          Expanded(child: slider),
          const ExcludeSemantics(
              child: Icon(Icons.volume_up_rounded,
                  color: Color(0xFF6260FF), size: 23)),
        ]),
      ]));
}

class SettingsMusicNote extends StatelessWidget {
  const SettingsMusicNote({super.key});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFE1F3FF),
          borderRadius: BorderRadius.circular(15)),
      child: const Row(children: [
        ExcludeSemantics(
            child: Icon(Icons.lightbulb_rounded,
                color: Color(0xFFFFBD1B), size: 23)),
        SizedBox(width: 7),
        Expanded(
            child: Text('Music stays soft so letter sounds are clear.',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: settingsSoundMuted))),
        SizedBox(width: 5),
        ExcludeSemantics(
            child: Icon(Icons.eco_rounded, color: Color(0xFF73B735), size: 20)),
      ]));
}
