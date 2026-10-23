import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../data/updated_scene.dart';
import '../theme/kids_ui.dart';
import 'game_design.dart';
import 'game_leave_dialog.dart';
import 'animated_screen_art.dart';
import 'quick_choice_art.dart';

const quickInk = Color(0xFF29165D);
const quickPurple = Color(0xFF8534E8);

/// A compact, live assessment page. The reference's large decorative banner
/// is replaced by a small title so the actual task has room on phones.
class QuickCheckPage extends StatefulWidget {
  const QuickCheckPage(
      {super.key,
      required this.hasProgress,
      required this.onLeave,
      required this.builder});
  final bool hasProgress;
  final VoidCallback onLeave;
  final Widget Function(BuildContext, Size) builder;
  @override
  State<QuickCheckPage> createState() => _QuickCheckPageState();
}

class _QuickCheckPageState extends State<QuickCheckPage> {
  bool _leaving = false, _allowPop = false;
  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    final leave = !widget.hasProgress ||
        await showDialog<bool>(
                context: context,
                builder: (_) => Theme(
                    data: KidsUi.theme, child: const GameLeaveDialog())) ==
            true;
    if (!mounted) return;
    if (!leave) {
      _leaving = false;
      return;
    }
    widget.onLeave();
    await context.read<AppProvider>().phonicsAudio.stop();
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: KidsUi.theme.copyWith(
            filledButtonTheme: FilledButtonThemeData(style: quickPrimaryStyle),
            outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                    foregroundColor: quickInk,
                    backgroundColor: const Color(0xFFF5EEFF),
                    side: const BorderSide(color: Color(0xFFB780F8), width: 2),
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20))))),
        child: PopScope(
            canPop: _allowPop,
            onPopInvokedWithResult: (popped, _) {
              if (!popped) _leave();
            },
            child: Scaffold(
                body: _QuickCheckBackground(
                    child: SafeArea(
              child: Center(
                  child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          ForestIconButton(
                              tooltip: 'Back',
                              onPressed: _leave,
                              icon: Icons.arrow_back_rounded),
                          const SizedBox(width: 8),
                          const Expanded(
                              child: QuickWoodSign(
                                  label: 'Quick Check', compact: true)),
                          const SizedBox(width: 8),
                          const _QuickCheckProfile(),
                        ]),
                        const SizedBox(height: 8),
                        Expanded(
                            child: LayoutBuilder(
                                builder: (context, body) =>
                                    widget.builder(context, body.biggest))),
                      ]),
                ),
              )),
            )))),
      );
}

class _QuickCheckProfile extends StatelessWidget {
  const _QuickCheckProfile();

  @override
  Widget build(BuildContext context) {
    final character = context
        .select<AppProvider, String>((provider) => provider.studentCharacter);
    return Container(
        key: const ValueKey('quick-check-profile'),
        width: 52,
        height: 52,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF3D9),
            border: Border.all(color: const Color(0xFFB780F8), width: 2),
            borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.asset('$sceneAssets/${character}_1.png',
                key: ValueKey('quick-check-profile-$character'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                cacheWidth: 160,
                semanticLabel: 'Selected $character character')));
  }
}

/// Quick Check's supplied artwork uses its own full-screen background.
class _QuickCheckBackground extends StatelessWidget {
  const _QuickCheckBackground({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const AnimatedScreenArt(
            frames: [
              'assets/images/quick_check_background/quickcheck_newbg_1.png',
              'assets/images/quick_check_background/quickcheck_newbg_2.png',
              'assets/images/quick_check_background/quickcheck_newbg_3.png',
            ],
            fit: BoxFit.cover,
            alignment: Alignment.center,
            blend: true,
            frameDuration: Duration(seconds: 5)),
        child,
      ]);
}

final quickPrimaryStyle = quickColorButtonStyle(index: 3);

class QuickWoodSign extends StatelessWidget {
  const QuickWoodSign({super.key, required this.label, this.compact = false});
  final String label;
  final bool compact;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (_, box) => CustomPaint(
          foregroundPainter: const ForestLeaves(allCorners: true),
          child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: box.hasBoundedHeight && box.maxHeight <= 40
                      ? 3
                      : compact
                          ? 8
                          : 11),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFFCE79), width: 3),
                  gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFE5A15A),
                        Color(0xFFC27532),
                        Color(0xFF995026)
                      ]),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x44392966),
                        blurRadius: 5,
                        offset: Offset(0, 4))
                  ]),
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: compact ? 18 : 23,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.15,
                          shadows: const [
                            Shadow(
                                color: Color(0xFF682D15),
                                offset: Offset(0, 2),
                                blurRadius: 2)
                          ]))))));
}

class QuickGlassPanel extends StatelessWidget {
  const QuickGlassPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(12)});
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
      padding: padding,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFBB8AF4), width: 2.5),
          gradient: const LinearGradient(
              colors: [Color(0xFFFDFBFF), Color(0xFFEEE6FF)]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x444F2B9B), offset: Offset(0, 4), blurRadius: 5)
          ]),
      child: DefaultTextStyle.merge(
          style: const TextStyle(color: quickInk), child: child));
}

class QuickInstruction extends StatelessWidget {
  const QuickInstruction(
      {super.key, required this.text, this.intro = false, this.replay});
  final String text;
  final bool intro;
  final Widget? replay;
  @override
  Widget build(BuildContext context) => QuickGlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(children: [
        Expanded(
            child: LayoutBuilder(
                builder: (_, box) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                        width: box.maxWidth,
                        child: Text(text,
                            style: const TextStyle(
                                fontSize: 16,
                                height: 1.25,
                                fontWeight: FontWeight.w800)))))),
        if (replay != null) ...[const SizedBox(width: 8), replay!],
      ]));
}

class QuickProgress extends StatelessWidget {
  const QuickProgress(
      {super.key,
      required this.current,
      required this.completed,
      this.trailing,
      this.compact = false});
  final int current, completed;
  final Widget? trailing;
  final bool compact;
  @override
  Widget build(BuildContext context) => QuickGlassPanel(
      key: const ValueKey('quick-check-progress'),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 4 : 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: SizedBox(
                  height: compact ? 18 : 22,
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('$current / 5 challenge',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w900))))),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ]),
        SizedBox(height: compact ? 3 : 5),
        Semantics(
            label: '$completed of 5 challenges answered',
            child: LinearProgressIndicator(
                value: completed / 5,
                minHeight: compact ? 7 : 9,
                borderRadius: BorderRadius.circular(10),
                color: quickPurple,
                backgroundColor: const Color(0xFFD8C8F5))),
      ]));
}

class QuickLetter extends StatelessWidget {
  const QuickLetter({super.key, required this.letter, this.size = 82});
  final String letter;
  final double size;
  @override
  Widget build(BuildContext context) => Text(letter,
      textAlign: TextAlign.center,
      style: TextStyle(
          fontSize: size,
          height: 1.05,
          fontWeight: FontWeight.w900,
          color: quickPurple,
          shadows: const [
            Shadow(color: Colors.white, offset: Offset(-2, -2)),
            Shadow(color: Colors.white, offset: Offset(2, -2)),
            Shadow(color: Colors.white, offset: Offset(-2, 2)),
            Shadow(color: Colors.white, offset: Offset(2, 2)),
            Shadow(
                color: Color(0xFF63318D), offset: Offset(0, 4), blurRadius: 2),
          ]));
}
