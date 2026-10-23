import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/updated_scene.dart';
import '../services/audio_service.dart';

/// Compact glossy cards reuse the existing game and selected-character artwork.
class GameZoneCard extends StatefulWidget {
  const GameZoneCard(
      {super.key,
      required this.title,
      required this.description,
      required this.imageAsset,
      required this.accent,
      required this.character,
      required this.onPressed,
      this.completed = false});
  final String title, description, imageAsset, character;
  final Color accent;
  final VoidCallback? onPressed;
  final bool completed;
  @override
  State<GameZoneCard> createState() => _GameZoneCardState();
}

class _GameZoneCardState extends State<GameZoneCard> {
  bool _pressed = false, _pending = false;
  Future<void> _activate() async {
    if (_pending || widget.onPressed == null) return;
    _pending = true;
    unawaited(AudioService().playTap());
    final reduced = MediaQuery.disableAnimationsOf(context);
    try {
      if (!reduced) {
        setState(() => _pressed = true);
        await Future<void>.delayed(const Duration(milliseconds: 90));
        if (!mounted) return;
        setState(() => _pressed = false);
        await Future<void>.delayed(const Duration(milliseconds: 90));
      }
      if (mounted) widget.onPressed?.call();
    } finally {
      if (mounted) {
        setState(() {
          _pending = false;
          _pressed = false;
        });
      }
    }
  }

  Widget _surface() => Container(
      key: ValueKey('game-frame-${widget.title}'),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(widget.accent, Colors.white, .38)!,
                widget.accent,
                Color.lerp(widget.accent, Colors.black, .16)!
              ]),
          boxShadow: [
            BoxShadow(
                color: widget.accent.withValues(alpha: .23),
                blurRadius: 4,
                offset: const Offset(0, 3))
          ]),
      child: DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xE6FFFFFF), width: 1.5),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(widget.accent, Colors.white, .94)!,
                    Color.lerp(widget.accent, Colors.white, .72)!,
                    Color.lerp(widget.accent, Colors.white, .84)!
                  ]))));

  @override
  Widget build(BuildContext context) => Semantics(
      label: widget.title,
      hint:
          '${widget.description}${widget.completed ? ' Completed.' : ''} Play game.',
      button: true,
      enabled: widget.onPressed != null,
      excludeSemantics: true,
      onTap: widget.onPressed == null || _pending
          ? null
          : () => unawaited(_activate()),
      child: AnimatedScale(
          key: ValueKey('game-scale-${widget.title}'),
          scale: _pressed ? .97 : 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  key: ValueKey('game-open-${widget.title}'),
                  borderRadius: BorderRadius.circular(24),
                  excludeFromSemantics: true,
                  onTap: widget.onPressed == null || _pending
                      ? null
                      : () => unawaited(_activate()),
                  child: LayoutBuilder(builder: (context, box) {
                    final inset = box.maxWidth < 160 ? 8.0 : 10.0;
                    final safe = Rect.fromLTWH(inset, inset,
                        box.maxWidth - inset * 2, box.maxHeight - inset * 2);
                    return Stack(
                        key: ValueKey('game-card-${widget.title}'),
                        fit: StackFit.expand,
                        children: [
                          IgnorePointer(child: _surface()),
                          Positioned.fromRect(
                              rect: safe,
                              child: SizedBox(
                                  key: ValueKey('game-safe-${widget.title}'),
                                  child: _content(safe))),
                          IgnorePointer(
                              child: AnimatedOpacity(
                                  key: ValueKey(
                                      'game-frame-light-${widget.title}'),
                                  opacity: _pressed ? .22 : 0,
                                  duration: const Duration(milliseconds: 90),
                                  child: DecoratedBox(
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(24))))),
                        ]);
                  })))));

  Widget _content(Rect safe) {
    final completedHeight = widget.completed ? 13.0 : 0.0;
    final budget = safe.height - 6 - completedHeight;
    final titleHeight = (budget * .24).clamp(26.0, 34.0);
    final descriptionHeight = (budget * .12).clamp(13.0, 18.0);
    final playHeight = (budget * .24).clamp(26.0, 36.0);
    final artHeight =
        math.max(0.0, budget - titleHeight - descriptionHeight - playHeight);
    return Column(children: [
      SizedBox(
          height: artHeight,
          child: Stack(children: [
            Positioned.fill(
                left: safe.width * .30,
                child: Image.asset(widget.imageAsset,
                    key: ValueKey('game-art-${widget.title}'),
                    fit: BoxFit.contain,
                    cacheWidth: 500,
                    gaplessPlayback: true,
                    excludeFromSemantics: true)),
            Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: safe.width * .45,
                child: Image.asset('$sceneAssets/${widget.character}_1.png',
                    key: ValueKey(
                        'game-character-${widget.title}-${widget.character}'),
                    fit: BoxFit.contain,
                    cacheWidth: 240,
                    gaplessPlayback: true,
                    excludeFromSemantics: true)),
          ])),
      const SizedBox(height: 2),
      _caption(
          widget.title,
          'title',
          titleHeight,
          safe.width,
          (safe.width * .115).clamp(14.0, 18.0),
          FontWeight.w900,
          const Color(0xFF2C0D6A)),
      _caption(
          widget.description,
          'description',
          descriptionHeight,
          safe.width,
          (safe.width * .085).clamp(11.0, 14.0),
          FontWeight.w700,
          const Color(0xFF4D3477)),
      const SizedBox(height: 4),
      if (widget.completed)
        SizedBox(
            height: completedHeight,
            child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF087F46), size: 11),
                  SizedBox(width: 3),
                  Text('Completed',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF087F46))),
                ]))),
      Center(
          child: Container(
              key: ValueKey('game-play-${widget.title}'),
              height: playHeight,
              width: safe.width * .88,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 1.5),
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(widget.accent, Colors.white, .45)!,
                        widget.accent,
                        Color.lerp(widget.accent, Colors.black, .16)!
                      ],
                      stops: const [
                        0,
                        .45,
                        1
                      ]),
                  boxShadow: [
                    BoxShadow(
                        color: widget.accent.withValues(alpha: .35),
                        blurRadius: 3,
                        offset: const Offset(0, 2))
                  ]),
              child: const Stack(alignment: Alignment.center, children: [
                Positioned(
                    left: 10,
                    top: 3,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: Color(0x99FFFFFF),
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        child: SizedBox(width: 16, height: 3))),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 22),
                          SizedBox(width: 4),
                          Text('Play',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                        color: Color(0x55502772),
                                        offset: Offset(0, 1),
                                        blurRadius: 1)
                                  ])),
                        ]))),
              ]))),
    ]);
  }

  Widget _caption(String text, String part, double height, double width,
          double fontSize, FontWeight weight, Color color) =>
      SizedBox(
          key: ValueKey('game-$part-${widget.title}'),
          height: height,
          child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                  width: width,
                  child: Text(text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: fontSize,
                          height: 1.1,
                          fontWeight: weight,
                          color: color)))));
}
