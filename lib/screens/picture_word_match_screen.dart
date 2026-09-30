import '../data/game_session_order.dart';
import '../widgets/game_word_picture.dart';
// lib/screens/picture_word_match_screen.dart
//
// Picture-to-Word Match — 4 pictures shown, tap the one that matches the word.
// Tests word recognition by connecting written text to images.
//
// Easy   : 3 choices, simple 3-letter words
// Medium : 4 choices
// Hard   : 5 choices + longer words

import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:provider/provider.dart';

import '../data/phonics_activity_data.dart';
import '../providers/app_provider.dart';
import '../models/difficulty.dart';

import '../widgets/learner_widgets.dart';
import '../theme/kids_ui.dart';

class PictureWordMatchScreen extends StatefulWidget {
  final Difficulty difficulty;
  const PictureWordMatchScreen({super.key, this.difficulty = Difficulty.easy});

  @override
  State<PictureWordMatchScreen> createState() => _PictureWordMatchScreenState();
}

class _PictureWordMatchScreenState extends State<PictureWordMatchScreen>
    with SingleTickerProviderStateMixin, GameSessionUi<PictureWordMatchScreen> {
  int _index = 0;
  String? _picked;
  bool _answered = false;
  bool _landed = false, _flying = false;
  final _targetKey = GlobalKey();
  final Map<int, GlobalKey> _pictureKeys = {};
  late final AnimationController _flight;
  OverlayEntry? _flightEntry;

  @override
  void dispose() {
    _flightEntry?.remove();
    _flight.dispose();
    super.dispose();
  }

  Future<void> _flyToFrame(int option) async {
    final source = _pictureKeys[option]?.currentContext?.findRenderObject();
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final start = source is RenderBox
        ? source.localToGlobal(Offset.zero, ancestor: overlayBox) & source.size
        : null;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    setState(() => _flying = true);
    await Scrollable.ensureVisible(_targetKey.currentContext!, alignment: .15);
    if (!mounted) return;
    final target = _targetKey.currentContext!.findRenderObject() as RenderBox;
    final end =
        target.localToGlobal(Offset.zero, ancestor: overlayBox) & target.size;
    if (!reducedMotion && start != null) {
      _flightEntry = OverlayEntry(
          builder: (_) => AnimatedBuilder(
                animation: _flight,
                builder: (_, __) {
                  final t = Curves.easeInOutCubic.transform(_flight.value);
                  final rect = Rect.lerp(start, end, t)!.shift(Offset(
                      28 * math.sin(t * math.pi), -36 * math.sin(t * math.pi)));
                  return Positioned.fromRect(
                      rect: rect,
                      child: IgnorePointer(
                          child: ExcludeSemantics(
                              child: Material(
                        color: Colors.transparent,
                        child: GameWordPicture(
                            key: const ValueKey('flying-match-picture'),
                            word: _round.labels[option],
                            size: rect.width),
                      ))));
                },
              ));
      overlay.insert(_flightEntry!);
      try {
        await _flight.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
      _flightEntry?.remove();
      _flightEntry = null;
    }
    if (mounted) {
      setState(() {
        _landed = true;
        _flying = false;
      });
    }
  }

  late List<int> _shuffledIdx;

  late List<PictureWordRound> _rounds = _newSession();
  List<PictureWordRound> _newSession() => GameSessionOrder.next(
      'picture_word_match-${widget.difficulty.name}',
      pictureRoundsFor(widget.difficulty),
      (item) => item.word,
      count: GameSessionOrder.roundLength(widget.difficulty));
  PictureWordRound get _round => _rounds[_index];

  @override
  void initState() {
    super.initState();
    _flight = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _shuffleIdx();
  }

  void _shuffleIdx() {
    _shuffledIdx = List.generate(_round.options.length, (i) => i)..shuffle();
  }

  void _pick(String emoji) async {
    if (_answered || _picked != null || resultOpen) return;
    final isCorrect = emoji == _round.correctEmoji;
    setState(() => _picked = emoji);

    final provider = context.read<AppProvider>();
    recordGameAnswer(correct: isCorrect);
    if (isCorrect) {
      setState(() {
        _answered = true;
      });
      provider.audio.playCorrect();
      awardGameXp((8 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      await _flyToFrame(_round.options.indexOf(emoji));
      // No competing voice — correct.mp3 plays cleanly
    } else {
      // Wrong — play wrong.mp3 tone, show red flash, then clear so child can retry
      provider.audio.playWrong();
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _picked = null);
    }
  }

  void _next() {
    if (!_answered || _flying || resultOpen) return;
    if (_index < _rounds.length - 1) {
      setState(() {
        _index++;
        _picked = null;
        _answered = false;
        _landed = false;
        _shuffleIdx();
      });
    } else {
      _showResults();
    }
  }

  void _restart() => setState(() {
        _index = 0;
        _rounds = _newSession();
        _picked = null;
        _answered = false;
        _landed = false;

        _shuffleIdx();
      });

  void _showResults() {
    if (resultOpen) return;
    resultOpen = true;
    final provider = context.read<AppProvider>();
    provider.recordActivityCompleted();
    awardGameXp((15 * widget.difficulty.xpMultiplier).round());
    provider.audio.playWin();

    showGameResult(_restart, backLabel: 'Back to Games');
  }

  @override
  int get totalGameItems => _rounds.length;

  @override
  Widget build(BuildContext context) => GameScaffold(
        answerResult: _picked == null ? null : _picked == _round.correctEmoji,
        title: 'Picture Match',
        fitViewport: true,
        instructions: 'Read or hear the word. Tap its picture.',
        difficulty: widget.difficulty,
        hasProgress: scoredAttempts > 0 && !resultOpen,
        current: _index + 1,
        total: _rounds.length,
        child: LayoutBuilder(
            builder: (_, box) => Center(
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                        width: box.maxWidth,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                  child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _landed
                                      ? const Color(0xFFE4F8ED)
                                      : const Color(0xFFF2ECFC),
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                      color: _landed
                                          ? KidsUi.correct
                                          : const Color(0xFFCDBCEB),
                                      width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Color(0x227052CA),
                                        blurRadius: 16,
                                        offset: Offset(0, 6))
                                  ],
                                ),
                                child: Column(children: [
                                  SizedBox(
                                      key: _targetKey,
                                      width: (box.maxHeight * .32)
                                          .clamp(130.0, 200.0),
                                      height: (box.maxHeight * .32)
                                          .clamp(130.0, 200.0),
                                      child: _landed
                                          ? GameWordPicture(
                                              key: const ValueKey(
                                                  'matched-picture'),
                                              word: _round.word)
                                          : const Icon(
                                              Icons
                                                  .add_photo_alternate_outlined,
                                              size: 64,
                                              color: Color(0xFF8A72B6))),
                                  const SizedBox(height: 8),
                                  Text(
                                      _landed
                                          ? 'Correct match!'
                                          : 'Your picture goes here',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: _landed
                                              ? KidsUi.correct
                                              : KidsUi.muted)),
                                ]),
                              )),
                              const SizedBox(height: 6),
                              Text(_round.word,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              AudioButton(
                                  phrase: _round.word[0] +
                                      _round.word.substring(1).toLowerCase()),
                              const SizedBox(height: 6),
                              GameChoiceGrid(
                                  compact: true,
                                  children: _shuffledIdx
                                      .map((option) => GameAnswerButton(
                                          label: 'Picture ${option + 1}',
                                          visual: SizedBox(
                                              key: _pictureKeys.putIfAbsent(
                                                  option, () => GlobalKey()),
                                              child: Opacity(
                                                  opacity:
                                                      _answered && _picked == _round.options[option]
                                                          ? 0
                                                          : 1,
                                                  child: GameWordPicture(
                                                      word: _round
                                                          .labels[option]))),
                                          selected:
                                              _picked == _round.options[option],
                                          result:
                                              _picked == _round.options[option]
                                                  ? _round.options[option] ==
                                                      _round.correctEmoji
                                                  : null,
                                          onPressed: _answered ||
                                                  _picked != null ||
                                                  resultOpen
                                              ? null
                                              : () =>
                                                  _pick(_round.options[option])))
                                      .toList()),
                              if (_picked != null)
                                GameFeedback(
                                    correct: _picked == _round.correctEmoji),
                              if (_answered)
                                ElevatedButton(
                                    onPressed:
                                        resultOpen || _flying ? null : _next,
                                    child: const Text('Next')),
                            ]))))),
      );
}
