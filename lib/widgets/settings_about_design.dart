import 'package:flutter/material.dart';
import '../services/app_build_info.dart';
import 'button_sound.dart';
import 'home_progress_banner.dart';

const _aboutInk = Color(0xFF123B9A);
const _aboutBody = Color(0xFF36568C);

/// Essential app information, with no decorative leaves or extra settings.
class SettingsAboutDialog extends StatelessWidget {
  const SettingsAboutDialog(
      {super.key,
      required this.info,
      required this.character,
      required this.onLicenses});
  final Future<AppBuildInfo> info;
  final String character;
  final VoidCallback onLicenses;

  @override
  Widget build(BuildContext context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      constraints: const BoxConstraints(maxWidth: 540),
      backgroundColor: Colors.transparent,
      child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFF39B7F5), width: 3),
              gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF76C9FF),
                    Color(0xFFF1FCFF),
                    Color(0xFFEDFAFF)
                  ],
                  stops: [
                    0,
                    .38,
                    1
                  ]),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x55153673),
                    blurRadius: 10,
                    offset: Offset(0, 5))
              ]),
          clipBehavior: Clip.antiAlias,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _AboutHeader(onClose: () => Navigator.pop(context)),
            Flexible(
                child: SingleChildScrollView(
                    key: const ValueKey('settings-about-content'),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AboutSurface(
                              child: Row(children: [
                            const _AboutIcon(icon: Icons.settings_rounded),
                            const SizedBox(width: 10),
                            Expanded(
                                child: FutureBuilder<AppBuildInfo>(
                                    future: info,
                                    builder: (_, snapshot) => Text(
                                        snapshot.data?.label ??
                                            'Loading app version…',
                                        key: const ValueKey(
                                            'settings-app-version'),
                                        style: const TextStyle(
                                            fontFamily: 'Nunito',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: _aboutInk)))),
                          ])),
                          _AboutSection(
                              title: 'Your saved learning',
                              text:
                                  'Your profile, progress, rewards, and settings are saved on this device. Clearing app data or uninstalling may remove them.',
                              illustration: _AboutIcon(
                                  child: Image.asset(
                                      HomeBannerArt.portrait(character),
                                      fit: BoxFit.contain,
                                      cacheWidth: 180,
                                      excludeFromSemantics: true))),
                          const _AboutSection(
                              title: 'Speech activities',
                              text:
                                  'Speech activities use your device’s microphone and speech recognition. An internet connection may be needed.',
                              illustration:
                                  _AboutIcon(icon: Icons.mic_rounded)),
                          _AboutSurface(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                const _AboutCopy(
                                    title: 'Credits',
                                    text:
                                        'KidsPhonics artwork, recordings, and learning materials. Nunito and Fredoka: SIL Open Font License.'),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                    key: const ValueKey(
                                        'settings-about-licenses'),
                                    onPressed: withButtonSound(onLicenses),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: _aboutInk,
                                        backgroundColor:
                                            const Color(0xFFDBF1FF),
                                        side: const BorderSide(
                                            color: Color(0xFFA8DFFF),
                                            width: 1.5),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15))),
                                    icon: const Icon(Icons.description_rounded,
                                        color: Color(0xFF168BF1)),
                                    label: const Text('Open-source licenses',
                                        style: TextStyle(
                                            fontFamily: 'Nunito',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900))),
                              ])),
                        ]))),
            CustomPaint(
                painter: const _AboutClouds(),
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                    child: Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFF66D5FF),
                                          Color(0xFF138DFF),
                                          Color(0xFF1159ED)
                                        ]),
                                    border: Border.all(color: const Color(0xFF81DFFF), width: 3),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Color(0x554A81D0),
                                          blurRadius: 4,
                                          offset: Offset(0, 3))
                                    ]),
                                child: TextButton(
                                    onPressed: withButtonSound(
                                        () => Navigator.pop(context)),
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(48, 48),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                    child: const Text('Close', style: TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w900)))))))),
          ])));
}

class _AboutHeader extends StatelessWidget {
  const _AboutHeader({required this.onClose});
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: const _AboutClouds(),
      child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const ExcludeSemantics(
                  child: Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Icon(Icons.star_rounded,
                          color: Color(0xFFFFD441), size: 28))),
              const Expanded(
                  child:
                      FittedBox(fit: BoxFit.scaleDown, child: _AboutTitle())),
              IconButton(
                  tooltip: 'Close About',
                  onPressed: withButtonSound(onClose),
                  style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF138CFF),
                      side:
                          const BorderSide(color: Color(0xFF9BE5FF), width: 2)),
                  icon: const Icon(Icons.close_rounded)),
            ]),
            const SizedBox(height: 5),
            const Text('Play, listen, and learn one little step at a time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: _aboutInk)),
          ])));
}

class _AboutTitle extends StatelessWidget {
  const _AboutTitle();
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
        fontFamily: 'Nunito',
        fontSize: 30,
        height: 1.05,
        fontWeight: FontWeight.w900);
    return Stack(children: [
      ExcludeSemantics(
          child: Text('About\nKidsPhonics',
              textAlign: TextAlign.center,
              style: style.copyWith(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 5
                    ..color = Colors.white))),
      const Text('About\nKidsPhonics',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 30,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: _aboutInk)),
    ]);
  }
}

class _AboutSurface extends StatelessWidget {
  const _AboutSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC6EBFF), width: 1.5),
          gradient: const LinearGradient(
              colors: [Color(0xFFF7FCFF), Color(0xFFEAF8FF)])),
      child: child);
}

class _AboutIcon extends StatelessWidget {
  const _AboutIcon({this.icon, this.child});
  final IconData? icon;
  final Widget? child;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: Container(
          width: 48,
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                  colors: [Color(0xFFB2E7FF), Color(0xFFEBFAFF)])),
          child: child ??
              Icon(icon,
                  size: 35,
                  color: const Color(0xFF168BF1),
                  shadows: const [
                    Shadow(
                        color: Colors.white,
                        blurRadius: 2,
                        offset: Offset(0, -1))
                  ])));
}

class _AboutSection extends StatelessWidget {
  const _AboutSection(
      {required this.title, required this.text, required this.illustration});
  final String title, text;
  final Widget illustration;
  @override
  Widget build(BuildContext context) =>
      _AboutSurface(child: LayoutBuilder(builder: (context, box) {
        final copy = _AboutCopy(title: title, text: text);
        if (box.maxWidth < 260 ||
            MediaQuery.textScalerOf(context).scale(14) > 22) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [illustration, const SizedBox(height: 6), copy]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          illustration,
          const SizedBox(width: 10),
          Expanded(child: copy)
        ]);
      }));
}

class _AboutCopy extends StatelessWidget {
  const _AboutCopy({required this.title, required this.text});
  final String title, text;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                height: 1.15,
                fontWeight: FontWeight.w900,
                color: _aboutInk)),
        const SizedBox(height: 5),
        Text(text,
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: _aboutBody)),
      ]);
}

class _AboutClouds extends CustomPainter {
  const _AboutClouds();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x99FFFFFF);
    canvas.drawCircle(Offset(0, size.height), size.height * .48, paint);
    canvas.drawCircle(
        Offset(size.width * .13, size.height), size.height * .3, paint);
    canvas.drawCircle(Offset(size.width, size.height), size.height * .5, paint);
    canvas.drawCircle(
        Offset(size.width * .84, size.height), size.height * .26, paint);
  }

  @override
  bool shouldRepaint(covariant _AboutClouds oldDelegate) => false;
}
