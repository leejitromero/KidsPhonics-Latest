import '../widgets/game_theme_background.dart';
import '../widgets/game_design.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/difficulty.dart';
import '../models/flappy_letters_game.dart';
import '../widgets/flappy_bird_sprite.dart';
import '../widgets/flappy_letters_design.dart';
import '../widgets/game_instruction_guide.dart';
import '../widgets/completion_celebration.dart';
import '../widgets/game_round_result_dialog.dart';
import '../controllers/game_narration_controller.dart';
import '../providers/app_provider.dart';
import '../services/phonics_audio_service.dart';
import '../widgets/game_tutorial.dart';

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
  int _narrationSync = 0;
  int _feedbackGeneration = 0;
  late final _narration = GameNarrationController(
      play: (phrase) async {
        if (!_provider.voiceEnabled) return false;
        return _provider.phonicsAudio
            .playInstruction(phrase, playbackRate: _feedbackRate);
      },
      stop: () => _provider.phonicsAudio.stop());
  final _focus = FocusNode();
  Duration? _last;
  String? _letter;
  double _successGlow = 0;
  bool _flightStarsPosted = false;
  int _flightEarnedStars = 0;
  static const _birdSize = 72.0;
  static const _flapFrames = [1, 2, 3, 2, 0];
  static const _frameSeconds = .065;
  double _flapElapsed = _frameSeconds * _flapFrames.length;

  // The longest name/sound pair is 2.48 s. Leave decoder headroom within
  // the 3.29 / 2.43 / 1.93 s between pipes, without changing the flight speed.
  double get _feedbackRate => switch (widget.difficulty) {
        Difficulty.easy => 1.0,
        Difficulty.medium => 1.2,
        Difficulty.hard => 1.5,
      };

  void _prepareLetterFeedback(int index) {
    if (index >= 26) return;
    final letter = String.fromCharCode(65 + index);
    unawaited(PhonicsAudioService.prepareInstruction('lesson-letter-$letter'));
    unawaited(PhonicsAudioService.prepareInstruction('lesson-sound-$letter'));
  }

  int get _birdFrame => _game.state == FlightState.flying
      ? _flapFrames[(_flapElapsed / _frameSeconds)
          .floor()
          .clamp(0, _flapFrames.length - 1)]
      : 0;

  bool get _feedbackActive =>
      mounted &&
      (ModalRoute.isCurrentOf(context) ?? true) &&
      TickerMode.valuesOf(context).enabled &&
      _provider.gameAccess &&
      !_provider.timeLimitReached &&
      (_game.state == FlightState.flying || _game.state == FlightState.won) &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);

  void _cancelLetterFeedback() {
    _feedbackGeneration++;
    _narration.cancel();
  }

  Future<void> _playLetterFeedback(String letter) async {
    // A slow decoder must never leave an earlier letter queued behind the
    // visible one. Cancel that pair before starting the newly cleared letter.
    _cancelLetterFeedback();
    final run = _feedbackGeneration;
    try {
      bool current() =>
          mounted &&
          run == _feedbackGeneration &&
          _provider.voiceEnabled &&
          _feedbackActive;
      if (!current()) return;
      _narration.updateEnvironment(enabled: true, active: true);
      final name = _narration.letterName(letter);
      final generation = _narration.generation;
      await name;
      if (!current() ||
          generation != _narration.generation ||
          _narration.audioUnavailable) {
        return;
      }
      await _narration.letterSound(letter);
    } catch (_) {
      // An unavailable recording must not interrupt the flight controls.
    }
  }

  @override
  void initState() {
    super.initState();
    _game = FlappyLettersGame(widget.difficulty);
    _prepareLetterFeedback(0);
    _prepareLetterFeedback(1);
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.watch<AppProvider>();
    final request = ++_narrationSync;
    final active = _feedbackActive;
    if (!active || !_provider.voiceEnabled) _feedbackGeneration++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || request != _narrationSync) return;
      _narration.updateEnvironment(
          enabled: _provider.voiceEnabled, active: active);
    });
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
      _flapElapsed =
          (_flapElapsed + dt).clamp(0, _frameSeconds * _flapFrames.length);
      _successGlow = (_successGlow - dt).clamp(0, .7);
      for (final letter in _game.advance(dt)) {
        _successGlow = .7;
        _letter = letter;
        if (_provider.voiceEnabled) {
          unawaited(_playLetterFeedback(letter));
        }
        _prepareLetterFeedback(_game.passed);
      }
    });
    if (_game.lives < previousLives) {
      _cancelLetterFeedback();
      unawaited(_provider.phonicsAudio.stop());
      unawaited(_provider.audio.playWrong());
    }
    if (_game.state == FlightState.won) {
      // Flying is motor practice, not a scored letter-mastery assessment.
      _provider.recordActivityCompleted();
    }
    if ((_game.state == FlightState.won || _game.state == FlightState.lost) &&
        !_flightStarsPosted) {
      _flightStarsPosted = true;
      _flightEarnedStars = _game.state == FlightState.won
          ? (_game.lives == 3 ? 3 : 2)
          : (_game.passed * 100 >= 26 * 60 ? 2 : 1);
      unawaited(_saveFlightStars(_flightEarnedStars));
    }
  }

  Future<void> _saveFlightStars(int count) async {
    for (var i = 0; i < count; i++) {
      await _provider.addStar();
    }
  }

  void _pause() {
    if (!mounted) return;
    setState(_game.pause);
    _cancelLetterFeedback();
    _narration.updateEnvironment(
        enabled: _provider.voiceEnabled, active: false);
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
    setState(() {
      _game.flap();
      _flapElapsed = 0;
    });
    _narration.updateEnvironment(enabled: _provider.voiceEnabled, active: true);
    unawaited(_provider.audio.playFlap());
    _focus.requestFocus();
  }

  void _restart() {
    _flightStarsPosted = false;
    _flightEarnedStars = 0;
    _cancelLetterFeedback();
    unawaited(_provider.phonicsAudio.stop());
    unawaited(_provider.audio.stop());
    setState(() {
      _game = FlappyLettersGame(widget.difficulty);
      _letter = null;
      _successGlow = 0;
      _flapElapsed = _frameSeconds * _flapFrames.length;
    });
    _narration.resetRound();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _focus.dispose();
    _cancelLetterFeedback();
    _narration.dispose();
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
          child: CompletionCelebration(
              enabled: _game.state == FlightState.won,
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
                                left:
                                    (FlappyLettersGame.birdX - _birdSize / 2) *
                                        box.maxWidth /
                                        FlappyLettersGame.width,
                                top: _game.y *
                                        box.maxHeight /
                                        FlappyLettersGame.height -
                                    _birdSize /
                                        2 *
                                        box.maxWidth /
                                        FlappyLettersGame.width,
                                child: Opacity(
                                    opacity: _game.state == FlightState.flying
                                        ? 1
                                        : 0,
                                    child: IgnorePointer(
                                        child: FlappyBirdSprite(
                                      frame: _birdFrame,
                                      tilt: _game.state == FlightState.flying
                                          ? (_game.velocity / 900)
                                              .clamp(-.28, .45)
                                          : 0,
                                      size: _birdSize *
                                          box.maxWidth /
                                          FlappyLettersGame.width,
                                    ))),
                              ),
                            ])),
                  ),
                ),
                SafeArea(
                  child: Column(children: [
                    FlappyStatusBar(
                        difficulty: widget.difficulty,
                        passed: _game.passed,
                        lives: _game.lives,
                        letter: _letter,
                        onBack: () => Navigator.pop(context),
                        onHelp: onHelp,
                        onPause:
                            _game.state == FlightState.flying ? _pause : null),
                    if (_game.state == FlightState.ready)
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: GameInstructionGuide(
                              gameTitle: 'Flappy Letters')),
                    if (_game.state != FlightState.flying)
                      Expanded(child: _overlay()),
                  ]),
                ),
              ])),
        ),
      ));
  Widget _overlay() {
    final state = _game.state;
    if (state == FlightState.won || state == FlightState.lost) {
      return GameResultDialog(
          title: 'Flappy Letters',
          savePending: _provider.hasUnsavedChanges,
          onRetrySaving: () => unawaited(_provider.retrySaving()),
          correct: _game.passed,
          attempts: 26,
          totalItems: 26,
          earnedXp: 0,
          earnedStars: _flightEarnedStars,
          difficulty: widget.difficulty,
          ratingStars: _flightEarnedStars,
          ratingLabel: 'course progress',
          scoreUnit: 'Letters cleared; flight practice, not letter mastery.',
          accuracyNote:
              'Three stars: clear A to Z without losing a life. Two stars: finish with a lost life, or clear 60% of the course.',
          onAgain: _restart,
          onBack: () => Navigator.pop(context),
          onDifficultySelected: (difficulty) => Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                  builder: (_) =>
                      FlappyLettersScreen(difficulty: difficulty))));
    }
    final title = switch (state) {
      FlightState.ready => 'Ready to fly?',
      FlightState.paused => 'Taking a little break',
      FlightState.won => 'A to Z! You did it!',
      FlightState.hit => 'Oops! Keep going!',
      _ => 'Nice flying! Try again!',
    };
    return ColoredBox(
      color: state == FlightState.ready
          ? Colors.transparent
          : const Color(0x222F245D),
      child: FlappyFlightPanel(
        title: title,
        detail: state == FlightState.ready
            ? 'Tap to fly. Space / Up on a keyboard.\nYou have 3 lives. Pass 26 pipes!'
            : '${_game.passed} of 26 letters cleared',
        buttonLabel: switch (state) {
          FlightState.ready => 'Start flying',
          FlightState.paused => 'Resume',
          FlightState.hit => 'Continue',
          _ => 'Play again',
        },
        celebrate: state == FlightState.won,
        onPressed: _overlayAction,
      ),
    );
  }

  void _overlayAction() {
    final state = _game.state;
    if (state == FlightState.flying) return;
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
      _narration.updateEnvironment(
          enabled: _provider.voiceEnabled, active: true);
      _focus.requestFocus();
    } else {
      _restart();
    }
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
