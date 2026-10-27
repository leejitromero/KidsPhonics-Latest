import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_narration_controller.dart';
import '../providers/app_provider.dart';
import '../theme/kids_ui.dart';

class GameMascotCoach extends StatefulWidget {
  const GameMascotCoach(
      {super.key,
      required this.title,
      required this.instructions,
      required this.controller,
      this.child,
      this.enabled = true});
  static const mascotAsset = 'assets/images/new_ui/game_mascot.webp';
  final String title, instructions;
  final GameNarrationController controller;
  final bool enabled;
  final Widget? child;
  @override
  State<GameMascotCoach> createState() => _GameMascotCoachState();
}

class _GameMascotCoachState extends State<GameMascotCoach>
    with WidgetsBindingObserver {
  bool _foreground = true;
  int _syncRequest = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  void _sync() {
    final request = ++_syncRequest;
    final provider = context.read<AppProvider>();
    final voice = provider.voiceEnabled;
    final active = _foreground &&
        widget.enabled &&
        TickerMode.valuesOf(context).enabled &&
        provider.gameAccess &&
        !provider.timeLimitReached &&
        (ModalRoute.isCurrentOf(context) ?? true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || request != _syncRequest) return;
      widget.controller.updateEnvironment(enabled: voice, active: active);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.watch<AppProvider>();
    _sync();
  }

  @override
  void didUpdateWidget(GameMascotCoach oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.title != widget.title ||
        oldWidget.controller != widget.controller) {
      _sync();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      // Backgrounding can suspend frames, so silence speech immediately.
      _syncRequest++;
      widget.controller.updateEnvironment(
          enabled: context.read<AppProvider>().voiceEnabled, active: false);
      return;
    }
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.child ??
      AnimatedBuilder(
        animation: widget.controller,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0xE6EFFBFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white)),
          child: Row(children: [
            AnimatedScale(
                scale: widget.controller.speaking &&
                        !MediaQuery.disableAnimationsOf(context)
                    ? 1.08
                    : 1,
                duration: const Duration(milliseconds: 180),
                child: Image.asset(GameMascotCoach.mascotAsset,
                    key: const ValueKey('game-mascot'),
                    width: 42,
                    height: 42,
                    fit: BoxFit.contain,
                    cacheWidth: 192,
                    excludeFromSemantics: true)),
            const SizedBox(width: 6),
            Expanded(
                child: Semantics(
                    liveRegion: widget.controller.feedback != null,
                    child: DefaultTextStyle.merge(
                        style: const TextStyle(
                            fontSize: 14,
                            color: KidsUi.ink,
                            fontWeight: FontWeight.w800),
                        child:
                            Stack(alignment: Alignment.centerLeft, children: [
                          // Letter sound labels keep the guide's controls in place.
                          Visibility(
                              visible: widget.controller.feedback == null,
                              maintainSize: true,
                              maintainAnimation: true,
                              maintainState: true,
                              child: Text(widget.instructions)),
                          if (widget.controller.feedback != null)
                            Text(widget.controller.feedback!),
                        ])))),
          ]),
        ),
      );
}
