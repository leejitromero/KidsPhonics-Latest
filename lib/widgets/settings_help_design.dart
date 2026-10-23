import 'package:flutter/material.dart';
import 'button_sound.dart';

const _helpInk = Color(0xFF0738A4);
const _helpBody = Color(0xFF455E99);

class SettingsHelpDialog extends StatelessWidget {
  const SettingsHelpDialog(
      {super.key,
      required this.onLessons,
      required this.onGames,
      required this.onDeviceSettings});
  final VoidCallback onLessons, onGames, onDeviceSettings;

  @override
  Widget build(BuildContext context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      constraints: const BoxConstraints(maxWidth: 540),
      backgroundColor: Colors.transparent,
      child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFB4EDFF), width: 2),
              gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF42C5FA),
                    Color(0xFFCAF1FF),
                    Color(0xFFF3FCFF)
                  ]),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x4D143D78),
                    blurRadius: 12,
                    offset: Offset(0, 6))
              ]),
          clipBehavior: Clip.antiAlias,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 14),
                child: Row(children: [
                  const ExcludeSemantics(
                      child: Icon(Icons.star_rounded,
                          color: Color(0xFFFFD543), size: 23)),
                  const SizedBox(width: 5),
                  const Expanded(
                      child: FittedBox(
                          fit: BoxFit.scaleDown, child: _HelpHeading())),
                  IconButton(
                      tooltip: 'Close help',
                      onPressed: withButtonSound(() => Navigator.pop(context)),
                      style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF388BFF),
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                              color: Color(0xFFBCEBFF), width: 2)),
                      icon: const Icon(Icons.close_rounded)),
                ])),
            Flexible(
                child: SingleChildScrollView(
                    key: const ValueKey('settings-help-content'),
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFFDF1),
                            borderRadius: BorderRadius.circular(30)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _HelpSection(
                                  icon: Icons.menu_book_rounded,
                                  title: 'Lessons',
                                  text:
                                      'Choose a lesson and listen to the recordings. Follow the instructions and revisit letters that need practice.'),
                              const SizedBox(height: 12),
                              SettingsGuideButton(
                                  key: const ValueKey('settings-lessons-guide'),
                                  label: 'Meet the Lessons guide',
                                  icon: Icons.menu_book_rounded,
                                  onPressed: onLessons),
                              const SizedBox(height: 20),
                              const _HelpSection(
                                  icon: Icons.sports_esports_rounded,
                                  title: 'Games',
                                  text:
                                      'Choose a game and difficulty. Use the help button inside a game to see its instructions again.'),
                              const SizedBox(height: 12),
                              SettingsGuideButton(
                                  key: const ValueKey('settings-games-guide'),
                                  label: 'Meet the Games guide',
                                  icon: Icons.sports_esports_rounded,
                                  indigo: true,
                                  onPressed: onGames),
                              const SizedBox(height: 20),
                              const _HelpSection(
                                  icon: Icons.edit_rounded,
                                  title: 'Practice Letter',
                                  text:
                                      'Home recommends a letter that still needs practice. It advances when you meet the activity’s mastery criteria.'),
                              const SizedBox(height: 20),
                              const _HelpSection(
                                  icon: Icons.mic_rounded,
                                  title: 'Microphone',
                                  text:
                                      'Speech activities ask for microphone access when you start listening. Speak clearly in a quiet place. If access was denied, ask a grown-up to allow it in device settings. Recognition availability depends on your device and may require a connection.'),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                  key: const ValueKey(
                                      'settings-microphone-help'),
                                  onPressed: withButtonSound(onDeviceSettings),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: _helpInk,
                                      side: const BorderSide(
                                          color: Color(0xFF70CFFF), width: 2),
                                      backgroundColor: const Color(0xFFE7F6FF)),
                                  icon: const Icon(Icons.mic_rounded),
                                  label: const Text('Open device settings',
                                      style: TextStyle(fontFamily: 'Nunito'))),
                            ])))),
            CustomPaint(
                painter: const _HelpClouds(),
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 12, 12),
                    child: Row(children: [
                      const ExcludeSemantics(
                          child: Icon(Icons.star_rounded,
                              color: Color(0xFFFFD543), size: 25)),
                      const Spacer(),
                      OutlinedButton(
                          onPressed:
                              withButtonSound(() => Navigator.pop(context)),
                          style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFF1FBFF),
                              foregroundColor: _helpInk,
                              minimumSize: const Size(100, 46),
                              side: const BorderSide(
                                  color: Color(0xFF239CF2), width: 2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18))),
                          child: const Text('Close',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19))),
                    ]))),
          ])));
}

class _HelpHeading extends StatelessWidget {
  const _HelpHeading();
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
        fontFamily: 'Nunito', fontSize: 30, fontWeight: FontWeight.w900);
    return Stack(children: [
      ExcludeSemantics(
          child: Text('Help & Tutorials',
              style: style.copyWith(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 6
                    ..color = Colors.white))),
      const Text('Help & Tutorials',
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: _helpInk)),
    ]);
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection(
      {required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title, text;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final compact = box.maxWidth < 260 ||
            MediaQuery.textScalerOf(context).scale(15) > 24;
        final illustration = ExcludeSemantics(
            child: Container(
                width: compact ? 44 : 55,
                height: compact ? 44 : 55,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Color(0xFFDDF5FF), Color(0xFFF7FCFF)])),
                child: Icon(icon,
                    color: icon == Icons.edit_rounded
                        ? const Color(0xFFF8BB28)
                        : const Color(0xFF2867F0),
                    size: compact ? 32 : 41,
                    shadows: const [
                      Shadow(
                          color: Color(0x555B38A2),
                          offset: Offset(0, 2),
                          blurRadius: 1)
                    ])));
        final copy =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFFDCF1FF),
                  borderRadius: BorderRadius.circular(18)),
              child: Text(title,
                  style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 19,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      color: _helpInk))),
          const SizedBox(height: 5),
          Text(text,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: _helpBody)),
        ]);
        if (compact) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [illustration, const SizedBox(height: 6), copy]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          illustration,
          const SizedBox(width: 10),
          Expanded(child: copy)
        ]);
      });
}

class SettingsGuideButton extends StatelessWidget {
  const SettingsGuideButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon,
      this.indigo = false,
      this.purple = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool indigo, purple;
  @override
  Widget build(BuildContext context) => Opacity(
      opacity: onPressed == null ? .55 : 1,
      child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: purple
                      ? const Color(0xFFD5A6FF)
                      : const Color(0xFFA1E3FF),
                  width: 3),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: purple
                      ? const [
                          Color(0xFFC16BFF),
                          Color(0xFF8D2AFF),
                          Color(0xFF7A20E1)
                        ]
                      : indigo
                          ? const [
                              Color(0xFF8495FF),
                              Color(0xFF354EFF),
                              Color(0xFF1936D3)
                            ]
                          : const [
                              Color(0xFF6FD8FF),
                              Color(0xFF008EFF),
                              Color(0xFF0066E8)
                            ]),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x33496EAE),
                    blurRadius: 4,
                    offset: Offset(0, 3))
              ]),
          child: ElevatedButton(
              onPressed: withButtonSound(onPressed),
              style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  minimumSize: const Size(0, 54),
                  shape: const StadiumBorder()),
              child: Row(children: [
                if (icon != null) ...[
                  Icon(icon, color: const Color(0xFFFFDE5A), size: 26),
                  const SizedBox(width: 8)
                ],
                Expanded(
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            height: 1.1))),
                const SizedBox(width: 5),
                const Icon(Icons.chevron_right_rounded, size: 28),
              ]))));
}

class SettingsGuideFrame extends StatelessWidget {
  const SettingsGuideFrame(
      {super.key,
      required this.games,
      required this.speaker,
      required this.nextLabel,
      required this.onNext,
      required this.onReplay});
  final bool games;
  final Widget speaker;
  final String nextLabel;
  final VoidCallback? onNext, onReplay;
  @override
  Widget build(BuildContext context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      constraints: const BoxConstraints(maxWidth: 400),
      backgroundColor: const Color(0xFFFFF8DF),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(color: Color(0xFFEEB650), width: 3)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                speaker,
                const SizedBox(height: 8),
                SettingsGuideButton(
                    key: const ValueKey('settings-guide-next'),
                    label: nextLabel,
                    purple: !games,
                    onPressed: onNext),
                const SizedBox(height: 8),
                Row(children: [
                  IconButton(
                      tooltip: 'Replay guideline',
                      onPressed: onReplay,
                      color: games
                          ? const Color(0xFF057BE1)
                          : const Color(0xFF8D2AFF),
                      icon: const Icon(Icons.volume_up_rounded)),
                  Expanded(
                      child: OutlinedButton(
                          key: const ValueKey('settings-guide-skip'),
                          onPressed:
                              withButtonSound(() => Navigator.pop(context)),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: games
                                  ? const Color(0xFF713814)
                                  : const Color(0xFF8D2AFF),
                              side: BorderSide(
                                  color: games
                                      ? const Color(0xFFE8BB70)
                                      : const Color(0xFFBA6CFF),
                                  width: 2),
                              shape: const StadiumBorder()),
                          child: const Text('Skip',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)))),
                  const SizedBox(width: 48),
                ]),
              ])));
}

class _HelpClouds extends CustomPainter {
  const _HelpClouds();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFCEF0FF);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * .6, size.width, size.height * .4),
        paint);
    for (var i = 0; i < 7; i++) {
      canvas.drawCircle(Offset(size.width * i / 6, size.height * .75),
          size.height * (i.isEven ? .55 : .35), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HelpClouds oldDelegate) => false;
}
