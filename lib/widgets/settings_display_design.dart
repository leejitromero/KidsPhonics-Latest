import 'package:flutter/material.dart';
import 'button_sound.dart';
import 'settings_sound_design.dart';

class SettingsDisplayPanel extends StatelessWidget {
  const SettingsDisplayPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SettingsSoundPanel(child: child);
}

class SettingsTextSizeOptions extends StatelessWidget {
  const SettingsTextSizeOptions(
      {super.key, required this.value, required this.onSelected});
  final double value;
  final ValueChanged<double>? onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final stacked = MediaQuery.textScalerOf(context).scale(13) > 19;
        final width = stacked ? box.maxWidth : (box.maxWidth - 12) / 3;
        return Wrap(spacing: 6, runSpacing: 6, children: [
          for (final (size, label) in [
            (1.0, 'Standard'),
            (1.15, 'Large'),
            (1.3, 'Extra large')
          ])
            SizedBox(
                width: width,
                child: ChoiceChip(
                    key: ValueKey('settings-text-size-$size'),
                    label: Text(label, textAlign: TextAlign.center),
                    labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: (value - size).abs() < .001
                            ? Colors.white
                            : settingsSoundMuted),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    backgroundColor: const Color(0xFFF5FAFF),
                    selectedColor: const Color(0xFF3698FF),
                    checkmarkColor: Colors.white,
                    side:
                        const BorderSide(color: Color(0xFFB9D9FF), width: 1.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: (value - size).abs() < .001 ? 2 : 0,
                    shadowColor: const Color(0x553C8DE8),
                    selected: (value - size).abs() < .001,
                    onSelected: withSelectionSound((selected) {
                      if (selected) onSelected?.call(size);
                    }))),
        ]);
      });
}

class SettingsDisplayPreview extends StatelessWidget {
  const SettingsDisplayPreview({super.key});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBCE9FF)),
          gradient: const LinearGradient(
              colors: [Color(0xFFE1F4FF), Color(0xFFECF6FF)])),
      child: LayoutBuilder(builder: (context, box) {
        const copy =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Aa Bb Cc · Let’s learn!',
              key: ValueKey('settings-text-preview'),
              style: TextStyle(
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  color: settingsSoundInk)),
          SizedBox(height: 5),
          Text('Your device’s accessibility settings are respected too.',
              style: TextStyle(
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: settingsSoundMuted)),
        ]);
        if (MediaQuery.textScalerOf(context).scale(14) > 21 ||
            box.maxWidth < 260) {
          return const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                copy,
                Align(
                    alignment: Alignment.centerRight,
                    child: _AlphabetDecoration())
              ]);
        }
        return const Row(children: [
          Expanded(child: copy),
          SizedBox(width: 6),
          _AlphabetDecoration()
        ]);
      }));
}

class SettingsAnimationNote extends StatelessWidget {
  const SettingsAnimationNote({super.key});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: const Color(0xFFE1F3FF),
          border: Border.all(color: const Color(0xFFC3E7FC)),
          borderRadius: BorderRadius.circular(14)),
      child: const Row(children: [
        ExcludeSemantics(
            child: Icon(Icons.lightbulb_rounded,
                color: Color(0xFFFFBD1B), size: 25)),
        SizedBox(width: 8),
        Expanded(
            child: Text(
                'Turn this on if you prefer a simpler and more comfortable experience.',
                style: TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: settingsSoundMuted))),
        SizedBox(width: 6),
        ExcludeSemantics(
            child: Icon(Icons.eco_rounded, color: Color(0xFF73B735), size: 23)),
      ]));
}

class _AlphabetDecoration extends StatelessWidget {
  const _AlphabetDecoration();
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: SizedBox(
          width: 80,
          height: 65,
          child: Stack(children: [
            const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Icon(Icons.cloud_rounded,
                    color: Colors.white,
                    size: 76,
                    shadows: [
                      Shadow(
                          color: Color(0xFFBADDF6),
                          blurRadius: 3,
                          offset: Offset(0, 2))
                    ])),
            for (final (letter, x, y, color) in [
              ('A', 10.0, 1.0, const Color(0xFFF9415D)),
              ('B', 30.0, 12.0, const Color(0xFF0B9BF2)),
              ('C', 51.0, 8.0, const Color(0xFF48BF41)),
            ])
              Positioned(
                  left: x,
                  top: y,
                  child: Text(letter,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 35,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: color,
                          shadows: const [
                            Shadow(
                                color: Color(0x55859DC5),
                                offset: Offset(0, 2),
                                blurRadius: 2)
                          ]))),
            const Positioned(
                left: 0,
                top: 2,
                child: Icon(Icons.star_rounded,
                    color: Color(0xFFFFCF37), size: 17)),
            const Positioned(
                right: 0,
                top: 0,
                child: Icon(Icons.star_rounded,
                    color: Color(0xFFFFCF37), size: 12)),
          ])));
}
