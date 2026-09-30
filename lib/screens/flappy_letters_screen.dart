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
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  void _flap() {
    if (!_provider.gameAccess || _provider.timeLimitReached) return;
    setState(_game.flap);
    _focus.requestFocus();
  }

  void _restart() {
    unawaited(_provider.phonicsAudio.stop());
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GameTutorialHost(
      tutorial: GameTutorial.flappyLetters,
      onOpen: _pause,
      builder: (context, onHelp) => _page(context, onHelp));

  Widget _page(BuildContext context, VoidCallback onHelp) => Scaffold(
        body: Focus(
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
                              'assets/images/app_mascot.png',
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
                child: Column(children: [
              LearnerHeader(
                  title: 'Flappy Letters',
                  onHelp: onHelp,
                  trailing: IconButton(
                      tooltip: 'Pause',
                      color: const Color(0xFF2F245D),
                      onPressed:
                          _game.state == FlightState.flying ? _pause : null,
                      icon: const Icon(Icons.pause_rounded))),
              IgnorePointer(
                  child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(16)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                      '${widget.difficulty.label}  •  ${_game.passed} / 26 letters'
                      '${_letter == null ? '' : '  •  Great! $_letter'}',
                      style: const TextStyle(
                          color: Color(0xFF2F245D),
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                  GameLives(lives: _game.lives),
                ]),
              )),
            ])),
          ]),
        ),
      );
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
              onPressed: () {
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
              },
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
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: game.state == FlightState.lost
                ? const [Color(0xFFF6B5B5), Color(0xFFFFF0EC)]
                : game.state == FlightState.won || successGlow
                    ? const [Color(0xFF92DEB7), Color(0xFFEFFFF1)]
                    : const [Color(0xFF9DDEFA), Color(0xFFF0FBFF)],
          ).createShader(Offset.zero & size));
    final cloud = Paint()..color = Colors.white.withValues(alpha: .75);
    for (final origin in [
      const Offset(65, 95),
      const Offset(290, 190),
      const Offset(190, 480)
    ]) {
      canvas.drawOval(
          Rect.fromCenter(center: origin, width: 110, height: 35), cloud);
      canvas.drawCircle(origin - const Offset(10, 14), 25, cloud);
    }
    for (var i = 0; i < 26; i++) {
      final x = game.pipeX(i);
      if (x > size.width || x + FlappyLettersGame.pipeWidth < 0) continue;
      final top = game.gapCenter(i) - FlappyLettersGame.gap / 2;
      final bottom = game.gapCenter(i) + FlappyLettersGame.gap / 2;
      final paint = Paint()..color = const Color(0xFF239B78);
      canvas.drawRect(Rect.fromLTWH(x + 5, 0, 56, top), paint);
      canvas.drawRect(
          Rect.fromLTWH(x + 5, bottom, 56, size.height - bottom), paint);
      paint.color = const Color(0xFF116951);
      for (final y in [top - 22, bottom]) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x, y, 66, 22), const Radius.circular(5)),
            paint);
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
