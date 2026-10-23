// lib/screens/alphabet_order_screen.dart
//
// Alphabet Order game: letters are shown shuffled — the child taps them
// in the correct A→Z order. Wrong tap shows a shake + red flash.
// Difficulty controls how many letters are in play:
//   Easy   → A–F  (6 letters)
//   Medium → A–M  (13 letters)
//   Hard   → A–Z  (26 letters)

import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

import '../models/difficulty.dart';
import '../widgets/learner_widgets.dart';
import '../widgets/floating_choice.dart';
import '../widgets/game_instruction_guide.dart';
import '../widgets/game_mascot_coach.dart';
import '../widgets/game_design.dart';
import '../widgets/activity_round_header.dart';
import '../widgets/alphabet_order_design.dart';

class AlphabetOrderScreen extends StatefulWidget {
  final Difficulty difficulty;
  const AlphabetOrderScreen({super.key, this.difficulty = Difficulty.easy});

  @override
  State<AlphabetOrderScreen> createState() => _AlphabetOrderScreenState();
}

class _AlphabetOrderScreenState extends State<AlphabetOrderScreen>
    with SingleTickerProviderStateMixin, GameSessionUi<AlphabetOrderScreen> {
  late List<String> _letters; // all letters for this difficulty
  late List<String> _shuffled; // displayed in this order
  bool _busy = false;
  int _nextExpected = 0; // index into _letters (sorted)
  Set<String> _correct = {}; // tapped correctly
  String? _wrongLetter; // flashes red briefly
  final Map<String, GlobalKey> _slots = {}, _choices = {};
  late final AnimationController _flight;
  OverlayEntry? _flightEntry;
  String? _flyingLetter;

  @override
  void dispose() {
    _flightEntry?.remove();
    _flight.dispose();
    super.dispose();
  }

  Future<void> _flyLetter(String letter) async {
    if (MediaQuery.disableAnimationsOf(context)) return;
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final source =
        _choices[letter]!.currentContext!.findRenderObject() as RenderBox;
    final target =
        _slots[letter]!.currentContext!.findRenderObject() as RenderBox;
    final start =
        source.localToGlobal(Offset.zero, ancestor: overlayBox) & source.size;
    final end =
        target.localToGlobal(Offset.zero, ancestor: overlayBox) & target.size;
    setState(() => _flyingLetter = letter);
    _flightEntry = OverlayEntry(
        builder: (_) => AnimatedBuilder(
              animation: _flight,
              builder: (_, __) {
                final t = Curves.easeInOutCubic.transform(_flight.value);
                final rect = Rect.lerp(start, end, t)!;
                return Positioned.fromRect(
                    rect: rect,
                    child: IgnorePointer(
                        child: ExcludeSemantics(
                            child: Material(
                      key: const ValueKey('flying-alphabet-letter'),
                      color: Color.lerp(choiceBlue, const Color(0xFF167769), t),
                      borderRadius: BorderRadius.circular(10),
                      elevation: 6,
                      child: Center(
                          child: Text(letter,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800))),
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
    if (mounted) setState(() => _flyingLetter = null);
  }

  @override
  void initState() {
    super.initState();
    _flight = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _setupRound();
  }

// ── helpers ──────────────────────────────────────────────────────────────

  List<String> _lettersForDifficulty() {
    const all = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    switch (widget.difficulty) {
      case Difficulty.easy:
        return all.substring(0, 6).split('');
      case Difficulty.medium:
        return all.substring(0, 13).split('');
      case Difficulty.hard:
        return all.split('');
    }
  }

  void _setupRound() {
    _letters = _lettersForDifficulty();
    _shuffled = List<String>.from(_letters)..shuffle();
    _nextExpected = 0;
    _correct = {};
    _wrongLetter = null;
    _busy = false;
  }

  void _restart() => setState(_setupRound);

  int get _totalLetters => _letters.length;
  bool get _finished => _correct.length == _totalLetters;

  // ── tap handler ───────────────────────────────────────────────────────────

  void _tap(String letter) async {
    if (resultOpen || _finished || _busy || _correct.contains(letter)) return;
    setState(() => _busy = true);
    final provider = context.read<AppProvider>();

    recordGameAnswer(correct: letter == _letters[_nextExpected]);
    if (letter == _letters[_nextExpected]) {
      playGameCorrect();
      awardGameXp((3 * widget.difficulty.xpMultiplier).round());
      awardGameStar();
      await _flyLetter(letter);
      if (!mounted) return;
      setState(() {
        _correct.add(letter);
        _nextExpected++;
        _wrongLetter = null;
      });
      if (_finished) provider.recordActivityCompleted();
      if (!mounted) return;
      if (_finished) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          provider.audio.playWin();
          awardGameXp((15 * widget.difficulty.xpMultiplier).round());
          _showWinDialog();
        }
      }
    } else {
      // Play the existing local feedback effect.
      playGameWrong();
      setState(() => _wrongLetter = letter);
      await Future.delayed(const Duration(milliseconds: 700));
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _wrongLetter = null);
    }
    if (mounted) setState(() => _busy = false);
  }

  // ── win dialog ────────────────────────────────────────────────────────────

  void _showWinDialog() {
    if (resultOpen) return;
    resultOpen = true;
    showGameResult(_restart);
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  int get totalGameItems => _totalLetters;

  @override
  Widget build(BuildContext context) => GameScaffold(
      narration: gameNarration,
      answerResult: _busy ? _wrongLetter == null : null,
      title: 'Alphabet Order',
      roundHeader: ActivityRoundHeader(
          difficulty: widget.difficulty,
          current: _correct.length,
          total: _totalLetters,
          label: 'Letters placed',
          fitLabels: true,
          leaves: false),
      instructions: 'Tap letters in order. Start with A.',
      instructionPanel: GameMascotCoach(
          title: 'Alphabet Order',
          instructions: 'Tap letters in order. Start with A.',
          controller: gameNarration,
          child: const GameInstructionGuide(gameTitle: 'Alphabet Order')),
      difficulty: widget.difficulty,
      current: _correct.length,
      total: _totalLetters,
      progressLabel: 'Letters placed',
      hasProgress: scoredAttempts > 0 && !resultOpen,
      fitViewport: true,
      child: LayoutBuilder(builder: (_, box) {
        final columns = switch (widget.difficulty) {
          Difficulty.easy => 3,
          Difficulty.medium => 5,
          Difficulty.hard => 7,
        };
        final rows = (_totalLetters / columns).ceil();
        final gap = widget.difficulty == Difficulty.easy ? 8.0 : 5.0;
        final side = math
            .min(
                112.0,
                math.min(
                  (box.maxWidth - gap * (columns - 1)) / columns,
                  (box.maxHeight - 70 - gap * (rows - 1) * 2) / (rows * 2),
                ))
            .clamp(1.0, 112.0);
        Widget grid(bool slots) => SizedBox(
              width: side * columns + gap * (columns - 1) + .01,
              child: Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  alignment: WrapAlignment.center,
                  children: (slots ? _letters : _shuffled).map((letter) {
                    final placed = _correct.contains(letter);
                    return SizedBox(
                        width: side,
                        height: side,
                        child: slots
                            ? Container(
                                key: _slots.putIfAbsent(
                                    letter, () => GlobalKey()),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: placed
                                        ? const Color(0xFF167769)
                                        : const Color(0xFFFFFCF3),
                                    borderRadius:
                                        BorderRadius.circular(side * .16)),
                                child: AlphabetSlotFrame(
                                    placed: placed,
                                    child: placed
                                        ? Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(letter,
                                                    style: TextStyle(
                                                        fontSize: side * .5,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color:
                                                            GameDesign.ink))))
                                        : Icon(Icons.star_rounded,
                                            size: side * .48,
                                            color: const Color(0xFFC9A9EF))),
                              )
                            : SizedBox(
                                key: _choices.putIfAbsent(
                                    letter, () => GlobalKey()),
                                child: Opacity(
                                  opacity:
                                      placed || _flyingLetter == letter ? 0 : 1,
                                  child: ExcludeSemantics(
                                    excluding:
                                        placed || _flyingLetter == letter,
                                    child: GameAnswerButton(
                                      buttonKey:
                                          ValueKey('alphabet-choice-$letter'),
                                      compact: true,
                                      floating: false,
                                      leaves: false,
                                      labelStyle: TextStyle(
                                          fontSize: side * .5,
                                          fontWeight: FontWeight.w900,
                                          color: GameDesign.ink),
                                      accent: _wrongLetter == letter
                                          ? const Color(0xFF8D2037)
                                          : choiceBlue,
                                      label: letter,
                                      onPressed: _busy || placed || resultOpen
                                          ? null
                                          : () => _tap(letter),
                                    ),
                                  ),
                                ),
                              ));
                  }).toList()),
            );
        return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              grid(true),
              SizedBox(
                  height: 46,
                  width: math.min(220, box.maxWidth * .55),
                  child: ForestPanel(
                      leaves: false,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                              _finished
                                  ? 'Alphabet complete!'
                                  : _wrongLetter != null
                                      ? 'Try again! Find ${_letters[_nextExpected]}'
                                      : 'Find ${_letters[_nextExpected]}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: GameDesign.ink))))),
              grid(false),
            ]);
      }));
}
