import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/kids_ui.dart';
import 'game_design.dart';
import 'game_leave_dialog.dart';
import 'game_theme_background.dart';
import 'mascot_guide.dart';
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
                body: GameThemeBackground(
                    child: SafeArea(
                        child: LayoutBuilder(
              builder: (context, box) => Center(
                  child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: LayoutBuilder(
                    builder: (context, inner) => SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                          child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(minHeight: box.maxHeight - 26),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(children: [
                                      ForestIconButton(
                                          tooltip: 'Back',
                                          onPressed: _leave,
                                          icon: Icons.arrow_back_rounded),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                          child: QuickWoodSign(
                                              label: 'Quick Check',
                                              compact: true)),
                                      const SizedBox(width: 12),
                                    ]),
                                    const SizedBox(height: 12),
                                    widget.builder(
                                        context,
                                        Size(inner.maxWidth - 28,
                                            box.maxHeight)),
                                  ])),
                        )),
              )),
            ))))),
      );
}

final quickPrimaryStyle = quickColorButtonStyle(index: 3);

class QuickWoodSign extends StatelessWidget {
  const QuickWoodSign({super.key, required this.label, this.compact = false});
  final String label;
  final bool compact;
  @override
  Widget build(BuildContext context) => CustomPaint(
      foregroundPainter: const ForestLeaves(allCorners: true),
      child: Container(
          padding:
              EdgeInsets.symmetric(horizontal: 22, vertical: compact ? 8 : 11),
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
                  ]))));
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
          child: Row(children: [
        ClipOval(
            child: MascotPortrait(
                mascot: LearningMascot.wigloo, size: intro ? 76 : 52)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 16, height: 1.25, fontWeight: FontWeight.w800))),
        if (replay != null) replay!,
      ]));
}

class QuickProgress extends StatelessWidget {
  const QuickProgress(
      {super.key, required this.current, required this.completed});
  final int current, completed;
  @override
  Widget build(BuildContext context) => QuickGlassPanel(
      key: const ValueKey('quick-check-progress'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('$current / 5 challenge',
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Semantics(
            label: '$completed of 5 challenges answered',
            child: LinearProgressIndicator(
                value: completed / 5,
                minHeight: 9,
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
