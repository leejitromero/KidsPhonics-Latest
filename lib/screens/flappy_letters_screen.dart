import '../widgets/game_theme_background.dart';
import '../widgets/button_sound.dart';
import '../widgets/game_design.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/difficulty.dart';
import '../models/flappy_letters_game.dart';
import '../providers/app_provider.dart';
import '../widgets/game_tutorial.dart';
import '../widgets/learner_widgets.dart';

class FlappyLettersScreen extends StatefulWidget {
  const FlappyLettersScreen({super.key, this.difficulty = Difficulty.easy});
  final Difficulty difficulty;
  @override
  State<FlappyLettersScreen> createState() => _FlappyLettersScreenState();
}

class _FlappyLettersScreenState extends State<FlappyLettersScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late FlappyLettersGame _game;
  late Ticker _ticker;
  late AppProvider _provider;
  final _focus = FocusNode();
  Duration? _last;
  String? _letter;
  double _successGlow = 0;

  @override
  void initState() {
    super.initState();
    _game = FlappyLettersGame(widget.difficulty);
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<AppProvider>();
  }

  void _tick(Duration elapsed) {
    final dt = _last == null ? 0.0 : (elapsed - _last!).inMicroseconds / 1e6;
    _last = elapsed;
    if (_game.state != FlightState.flying) return;
    if (ModalRoute.of(context)?.isCurrent != true ||
        !_provider.gameAccess ||
        _provider.timeLimitReached) {
      _pause();
      return;
    }
    final previousLives = _game.lives;
    setState(() {
      _successGlow = (_successGlow - dt).clamp(0, .7);
      for (final letter in _game.advance(dt)) {
        _successGlow = .7;
        _letter = letter;
        if (_provider.voiceEnabled) {
          unawaited(_provider.phonicsAudio.tryPlay('lesson-letter-$letter'));
        }
      }
    });
    if (_game.lives < previousLives) {
      unawaited(_provider.phonicsAudio.stop());
      unawaited(_provider.audio.playWrong());
    }
    if (_game.state == FlightState.won) {
      // Flying is motor practice, not a scored letter-mastery assessment.
      _provider.recordActivityCompleted();
    }
  }

  void _pause() {
    if (!mounted) return;
    setState(_game.pause);
    unawaited(_provider.phonicsAudio.stop());
    unawaited(_provider.audio.stop());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  void _flap() {
    if (!_provider.gameAccess || _provider.timeLimitReached) return;
    if (_game.state != FlightState.ready && _game.state != FlightState.flying) {
      return;
    }
    setState(_game.flap);
    unawaited(_provider.audio.playFlap());
    _focus.requestFocus();
  }

  void _restart() {
    unawaited(_provider.phonicsAudio.stop());
    unawaited(_provider.audio.stop());
    setState(() {
      _game = FlappyLettersGame(widget.difficulty);
      _letter = null;
      _successGlow = 0;
    });
    _focus.requestFocus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _focus.dispose();
    unawaited(_provider.phonicsAudio.stop());
    unawaited(_provider.audio.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GameTutorialHost(
      tutorial: GameTutorial.flappyLetters,
      onOpen: _pause,
      builder: (context, onHelp) => _page(context, onHelp));

  Widget _page(BuildContext context, VoidCallback onHelp) => Scaffold(
          body: GameThemeBackground(
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: (_, event) {
            if (event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (event is KeyDownEvent) _flap();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Stack(fit: StackFit.expand, children: [
            Semantics(
              button: true,
              label: 'Flap. Tap to fly through the letter pipes.',
              child: GestureDetector(
                key: const ValueKey('flight-play-area'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _flap(),
                child: LayoutBuilder(
                    builder: (_, box) => Stack(children: [
                          Positioned.fill(
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: SizedBox(
                                width: FlappyLettersGame.width,
                                height: FlappyLettersGame.height,
                                child: CustomPaint(
                                    painter: _CoursePainter(
                                        _game, _successGlow > 0)),
                              ),
                            ),
                          ),
                          Positioned(
                            left: (FlappyLettersGame.birdX - 28) *
                                box.maxWidth /
                                FlappyLettersGame.width,
                            top: _game.y *
                                    box.maxHeight /
                                    FlappyLettersGame.height -
                                28 * box.maxWidth / FlappyLettersGame.width,
                            child: IgnorePointer(
                                child: Image.asset(
                              'assets/images/new_ui/flappy_bird.png',
                              width:
                                  56 * box.maxWidth / FlappyLettersGame.width,
                              height:
                                  56 * box.maxWidth / FlappyLettersGame.width,
                            )),
                          ),
                        ])),
              ),
            ),
            if (_game.state != FlightState.flying) SafeArea(child: _overlay()),
            SafeArea(
                child: Align(
                    alignment: Alignment.topCenter,
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ForestIconButton(
                              tooltip: 'Back',
                              onPressed: () => Navigator.maybePop(context),
                              icon: Icons.arrow_back_rounded),
                          const SizedBox(width: 6),
                          Expanded(
                              child: IgnorePointer(
                                  child: ForestPanel(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                      '${widget.difficulty.label}  •  ${_game.passed} / 26 letters'
                                      '${_letter == null ? '' : '  •  Great! $_letter'}',
                                      style: const TextStyle(
                                          color: Color(0xFF2F245D),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800)),
                                  GameLives(lives: _game.lives),
                                ]),
                          ))),
                          const SizedBox(width: 6),
                          ForestIconButton(
                              tooltip: 'How to Play',
                              onPressed: onHelp,
                              purple: true,
                              icon: Icons.help_outline_rounded),
                          const SizedBox(width: 4),
                          ForestIconButton(
                              tooltip: 'Pause',
                              onPressed: _game.state == FlightState.flying
                                  ? _pause
                                  : null,
                              icon: Icons.pause_rounded),
                        ]))),
          ]),
        ),
      ));
  Widget _overlay() {
    final state = _game.state;
    final title = switch (state) {
      FlightState.ready => 'Ready to fly?',
      FlightState.paused => 'Taking a little break',
      FlightState.won => 'A to Z! You did it!',
      FlightState.hit => 'Oops! Keep going!',
      _ => 'Nice flying! Try again!',
    };
    return ColoredBox(
      color: const Color(0x442F245D),
      child: Center(
          child: Card(
        margin: const EdgeInsets.all(28),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
                state == FlightState.won
                    ? Icons.emoji_events_rounded
                    : Icons.flight_rounded,
                size: 48,
                color: const Color(0xFF7052CA)),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
                state == FlightState.ready
                    ? 'Tap to fly. Space / ↑ on a keyboard.\nYou have 3 lives. Pass 26 pipes!'
                    : '${_game.passed} of 26 letters cleared',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: withButtonSound(() {
                if (state == FlightState.ready) {
                  _flap();
                } else if (state == FlightState.hit) {
                  setState(() {
                    _game.continueFlight();
                    _letter = null;
                    _successGlow = 0;
                  });
                  _flap();
                } else if (state == FlightState.paused) {
                  setState(_game.resume);
                  _focus.requestFocus();
                } else {
                  _restart();
                }
              }),
              child: Text(state == FlightState.ready
                  ? 'Start flying'
                  : state == FlightState.paused
                      ? 'Resume'
                      : state == FlightState.hit
                          ? 'Continue'
                          : 'Play again'),
            ),
          ]),
        ),
      )),
    );
  }
}

class _CoursePainter extends CustomPainter {
  _CoursePainter(this.game, this.successGlow);
  final bool successGlow;
  final FlappyLettersGame game;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = game.state == FlightState.lost
              ? const Color(0x55F6B5B5)
              : game.state == FlightState.won || successGlow
                  ? const Color(0x5592DEB7)
                  : const Color(0x22FFFFFF));
    for (var i = 0; i < 26; i++) {
      final x = game.pipeX(i);
      if (x > size.width || x + FlappyLettersGame.pipeWidth < 0) continue;
      final top = game.gapCenter(i) - FlappyLettersGame.gap / 2;
      final bottom = game.gapCenter(i) + FlappyLettersGame.gap / 2;
      final pipeRect = Rect.fromLTWH(x + 5, 0, 56, size.height);
      final paint = Paint()
        ..shader = const LinearGradient(colors: [
          Color(0xFF337C19),
          Color(0xFFB6E93D),
          Color(0xFF68BC25),
          Color(0xFF1A721D),
        ], stops: [
          0,
          .2,
          .5,
          1
        ]).createShader(pipeRect);
      final outline = Paint()
        ..color = const Color(0xFF22652A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (final rect in [
        Rect.fromLTWH(x + 5, 0, 56, top),
        Rect.fromLTWH(x + 5, bottom, 56, size.height - bottom)
      ]) {
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, outline);
        canvas.drawLine(
            Offset(rect.left + 9, rect.top),
            Offset(rect.left + 9, rect.bottom),
            Paint()
              ..color = const Color(0x88E7FFB3)
              ..strokeWidth = 3);
      }
      for (final y in [top - 22, bottom]) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x, y, 66, 22), const Radius.circular(5)),
            paint);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x, y, 66, 22), const Radius.circular(5)),
            outline);
        canvas.drawLine(
            Offset(x + 5, y + 3),
            Offset(x + 61, y + 3),
            Paint()
              ..color = const Color(0xFFE8FFB4)
              ..strokeWidth = 2);
        canvas.save();
        canvas.translate(x + 38, y - 26);
        const ForestLeaves().paint(canvas, const Size(30, 36));
        canvas.restore();
      }
      final text = TextPainter(
        text: TextSpan(
            text: String.fromCharCode(65 + i),
            style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(x + (66 - text.width) / 2, top - 72));
      text.paint(canvas, Offset(x + (66 - text.width) / 2, bottom + 27));
    }
  }

  @override
  bool shouldRepaint(covariant _CoursePainter oldDelegate) => true;
}
